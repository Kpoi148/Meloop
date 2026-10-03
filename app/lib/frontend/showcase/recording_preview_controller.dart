import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/journal/journal_models.dart';
import '../application/practice_timer_service.dart';
import '../application/startup_controller.dart';
import '../recording/recording_ui_state.dart';
import 'recordings_preview_library.dart';

/// Temporary inputs for UC-10 visual review. No microphone, files or SQLite.
class RecordingPreviewInputs {
  const RecordingPreviewInputs({
    this.quota = freeQuota,
    this.microphone = RecordingMicrophone.permissionRequired,
    this.storageAvailable = true,
    this.audioBusy = false,
    this.startAvailable = true,
    this.saveAvailable = true,
  });

  static const freeQuota = RecordingQuota(
    maximumDuration: Duration(minutes: 5),
    maximumFiles: 10,
    savedFiles: 0,
    isPro: false,
  );
  static const pulseInterval = Duration(milliseconds: 250);
  final RecordingQuota quota;
  final RecordingMicrophone microphone;
  final bool storageAvailable, audioBusy, startAvailable, saveAvailable;
}

final recordingPreviewInputsProvider = Provider<RecordingPreviewInputs>(
  (ref) => RecordingPreviewInputs(
    quota: RecordingPreviewInputs.freeQuota.withSavedFiles(
      (RecordingsPreviewLibrary.initialFileCount *
                  ref.watch(meloopShellControllerProvider).profiles.length -
              ref.watch(recordingsPreviewRemovedProvider).length)
          .clamp(
            0,
            RecordingsPreviewLibrary.initialFileCount *
                ref.watch(meloopShellControllerProvider).profiles.length,
          ),
    ),
  ),
);
final recordingPreviewClockProvider = Provider<Duration Function()>((ref) {
  final clock = Stopwatch()..start();
  ref.onDispose(clock.stop);
  return () => clock.elapsed;
});
final recordingPreviewControllerProvider =
    NotifierProvider<RecordingPreviewController, Map<String, RecordingUiState>>(
      RecordingPreviewController.new,
    );

/// Session-scoped, in-memory interaction states; never writes journal metadata.
class RecordingPreviewController
    extends Notifier<Map<String, RecordingUiState>> {
  Timer? _pulse;
  String? _activeSession;
  Duration _startedAt = Duration.zero;
  Duration _playbackStartedAt = Duration.zero;
  Duration _playbackOffset = Duration.zero;

  @override
  Map<String, RecordingUiState> build() {
    ref.onDispose(() => _pulse?.cancel());
    ref.listen(practiceTimerSnapshotProvider, (_, next) {
      if (ref.read(practiceTimerServiceProvider) == null) return;
      final id = _activeSession;
      if (id == null) return;
      final snapshot = next.value;
      if (snapshot == null ||
          snapshot.sessionId != id ||
          snapshot.state != PracticeState.running ||
          snapshot.failed) {
        stop(id);
      }
    });
    ref.listen(recordingPreviewInputsProvider, (_, input) {
      final id = _activeSession;
      if (id == null || forSession(id).phase != RecordingPhase.recording) {
        return;
      }
      final issue = switch (input.microphone) {
        RecordingMicrophone.denied => RecordingIssue.microphoneDenied,
        RecordingMicrophone.unavailable => RecordingIssue.microphoneUnavailable,
        _ =>
          !input.storageAvailable
              ? RecordingIssue.storageFull
              : input.audioBusy
              ? RecordingIssue.audioBusy
              : null,
      };
      if (issue != null) stop(id, issue: issue);
    });
    return const {};
  }

  Duration get _now => ref.read(recordingPreviewClockProvider)();

  RecordingUiState forSession(String id) {
    final input = ref.read(recordingPreviewInputsProvider);
    final kept = state.values.fold<int>(0, (sum, item) => sum + item.keptTakes);
    final quota = input.quota.withSavedFiles(input.quota.savedFiles + kept);
    return (state[id] ??
            RecordingUiState(quota: quota, microphone: input.microphone))
        .copyWith(quota: quota, issue: state[id]?.issue);
  }

  void _set(String id, RecordingUiState value) => state = {...state, id: value};

  void start(String id, {required bool sessionRunning}) {
    final current = forSession(id);
    if (!sessionRunning || current.phase != RecordingPhase.ready) return;
    final input = ref.read(recordingPreviewInputsProvider);
    final issue = switch (input.microphone) {
      RecordingMicrophone.denied => RecordingIssue.microphoneDenied,
      RecordingMicrophone.unavailable => RecordingIssue.microphoneUnavailable,
      _ =>
        current.quota.full
            ? RecordingIssue.fileLimit
            : !input.storageAvailable
            ? RecordingIssue.storageFull
            : input.audioBusy
            ? RecordingIssue.audioBusy
            : !input.startAvailable
            ? RecordingIssue.startFailed
            : null,
    };
    if (issue != null) {
      _set(id, current.copyWith(microphone: input.microphone, issue: issue));
      return;
    }
    if (_activeSession case final previous? when previous != id) stop(previous);
    _activeSession = id;
    _startedAt = _now;
    _set(
      id,
      current.copyWith(
        phase: RecordingPhase.recording,
        microphone: RecordingMicrophone.ready,
        elapsed: Duration.zero,
        playbackPosition: Duration.zero,
        playing: false,
      ),
    );
    _startPulse();
  }

  void _startPulse() {
    _pulse?.cancel();
    _pulse = Timer.periodic(
      RecordingPreviewInputs.pulseInterval,
      (_) => refresh(),
    );
  }

  void refresh() {
    final id = _activeSession;
    if (id == null) return;
    final current = forSession(id);
    if (current.phase == RecordingPhase.recording) {
      final elapsed = _now - _startedAt;
      if (elapsed >= current.quota.maximumDuration) {
        _set(id, current.copyWith(elapsed: current.quota.maximumDuration));
        stop(id, issue: RecordingIssue.durationLimit, refreshElapsed: false);
      } else {
        _set(id, current.copyWith(elapsed: elapsed));
      }
    } else if (current.playing) {
      final position = _playbackOffset + _now - _playbackStartedAt;
      final ended = position >= current.elapsed;
      _set(
        id,
        current.copyWith(
          playbackPosition: ended ? current.elapsed : position,
          playing: !ended,
          issue: current.issue,
        ),
      );
      if (ended) _cancelPulse();
    }
  }

  void _cancelPulse() {
    _pulse?.cancel();
    _pulse = null;
    _activeSession = null;
  }

  void stop(String id, {RecordingIssue? issue, bool refreshElapsed = true}) {
    final current = forSession(id);
    if (current.phase == RecordingPhase.recording) {
      final elapsed = refreshElapsed ? _now - _startedAt : current.elapsed;
      _set(
        id,
        current.copyWith(
          phase: RecordingPhase.review,
          elapsed: elapsed > current.quota.maximumDuration
              ? current.quota.maximumDuration
              : elapsed,
          playing: false,
          issue: issue,
        ),
      );
    } else if (current.playing) {
      _set(id, current.copyWith(playing: false, issue: current.issue));
    }
    if (_activeSession == id) _cancelPulse();
  }

  void togglePlayback(String id) {
    final current = forSession(id);
    if (current.phase != RecordingPhase.review ||
        current.elapsed == Duration.zero) {
      return;
    }
    if (current.playing) {
      refresh();
      stop(id);
      return;
    }
    if (_activeSession case final previous? when previous != id) stop(previous);
    _activeSession = id;
    _playbackStartedAt = _now;
    _playbackOffset = current.playbackPosition >= current.elapsed
        ? Duration.zero
        : current.playbackPosition;
    _set(
      id,
      current.copyWith(
        playing: true,
        playbackPosition: _playbackOffset,
        issue: current.issue,
      ),
    );
    _startPulse();
  }

  void seek(String id, Duration position) {
    final current = forSession(id);
    if (current.phase != RecordingPhase.review) return;
    _playbackOffset = position;
    _playbackStartedAt = _now;
    _set(
      id,
      current.copyWith(playbackPosition: position, issue: current.issue),
    );
  }

  bool keep(String id) {
    final current = forSession(id);
    if (current.phase != RecordingPhase.review) return false;
    final input = ref.read(recordingPreviewInputsProvider);
    if (!input.saveAvailable || !input.storageAvailable || current.quota.full) {
      stop(id);
      _set(
        id,
        current.copyWith(
          playing: false,
          issue: current.quota.full
              ? RecordingIssue.fileLimit
              : RecordingIssue.saveFailed,
        ),
      );
      return false;
    }
    stop(id);
    _set(
      id,
      RecordingUiState(
        quota: current.quota,
        microphone: current.microphone,
        keptTakes: current.keptTakes + 1,
      ),
    );
    return true;
  }

  void discard(String id) {
    final current = forSession(id);
    stop(id);
    _set(
      id,
      RecordingUiState(
        quota: current.quota,
        microphone: current.microphone,
        keptTakes: current.keptTakes,
      ),
    );
  }

  void closePreview(String id) {
    if (_activeSession == id) {
      _pulse?.cancel();
      _pulse = null;
    }
    scheduleMicrotask(() {
      if (ref.mounted) stop(id);
    });
  }
}
