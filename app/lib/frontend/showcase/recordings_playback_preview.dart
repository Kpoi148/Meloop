import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../practice_sessions/practice_session.dart';
import '../recording/recording_ui_state.dart';
import 'metronome_preview_controller.dart';
import 'recording_preview_controller.dart';

class RecordingsPlaybackState {
  const RecordingsPlaybackState({
    this.recordingId,
    this.duration = Duration.zero,
    this.position = Duration.zero,
    this.playing = false,
    this.muted = false,
  });

  final String? recordingId;
  final Duration duration, position;
  final bool playing, muted;
}

final recordingsPlaybackPreviewProvider =
    NotifierProvider<RecordingsPlaybackPreview, RecordingsPlaybackState>(
      RecordingsPlaybackPreview.new,
    );

/// Presentation clock only. Device playback is outside this UI task.
class RecordingsPlaybackPreview extends Notifier<RecordingsPlaybackState> {
  Timer? _pulse;
  Duration _startedAt = Duration.zero;
  Duration _offset = Duration.zero;

  @override
  RecordingsPlaybackState build() {
    ref.onDispose(() => _pulse?.cancel());
    ref.listen(metronomePreviewControllerProvider, (_, next) {
      if (next.playing) pause();
    });
    ref.listen(recordingPreviewControllerProvider, (_, next) {
      if (next.values.any(
        (item) => item.playing || item.phase == RecordingPhase.recording,
      )) {
        pause();
      }
    });
    return const RecordingsPlaybackState();
  }

  Duration get _now => ref.read(recordingPreviewClockProvider)();

  void toggle(PracticeSessionRecording recording) {
    if (!recording.fileAvailable ||
        !recording.canPlay ||
        recording.duration <= Duration.zero) {
      return;
    }
    if (state.recordingId == recording.id && state.playing) {
      pause();
      return;
    }
    ref.read(metronomePreviewControllerProvider.notifier).stop();
    final recorder = ref.read(recordingPreviewControllerProvider.notifier);
    for (final entry in ref.read(recordingPreviewControllerProvider).entries) {
      if (entry.value.playing ||
          entry.value.phase == RecordingPhase.recording) {
        recorder.stop(entry.key);
      }
    }
    _pulse?.cancel();
    _offset =
        state.recordingId == recording.id && state.position < recording.duration
        ? state.position
        : Duration.zero;
    _startedAt = _now;
    state = RecordingsPlaybackState(
      recordingId: recording.id,
      duration: recording.duration,
      position: _offset,
      playing: true,
      muted: state.muted,
    );
    _pulse = Timer.periodic(
      RecordingPreviewInputs.pulseInterval,
      (_) => refresh(),
    );
  }

  void refresh() {
    if (!state.playing) return;
    final position = _offset + _now - _startedAt;
    final complete = position >= state.duration;
    state = RecordingsPlaybackState(
      recordingId: state.recordingId,
      duration: state.duration,
      position: complete ? state.duration : position,
      playing: !complete,
      muted: state.muted,
    );
    if (complete) _pulse?.cancel();
  }

  void pause() {
    refresh();
    _pulse?.cancel();
    if (!state.playing) return;
    state = RecordingsPlaybackState(
      recordingId: state.recordingId,
      duration: state.duration,
      position: state.position,
      muted: state.muted,
    );
  }

  void seek(PracticeSessionRecording recording, Duration position) {
    if (!recording.fileAvailable || !recording.canPlay) return;
    final wasPlaying = state.recordingId == recording.id && state.playing;
    _pulse?.cancel();
    _offset = Duration(
      milliseconds: position.inMilliseconds.clamp(
        0,
        recording.duration.inMilliseconds,
      ),
    );
    _startedAt = _now;
    state = RecordingsPlaybackState(
      recordingId: recording.id,
      duration: recording.duration,
      position: _offset,
      playing: wasPlaying && _offset < recording.duration,
      muted: state.muted,
    );
    if (state.playing) {
      _pulse = Timer.periodic(
        RecordingPreviewInputs.pulseInterval,
        (_) => refresh(),
      );
    }
  }

  void toggleMute() => state = RecordingsPlaybackState(
    recordingId: state.recordingId,
    duration: state.duration,
    position: state.position,
    playing: state.playing,
    muted: !state.muted,
  );

  void remove(String id) {
    if (state.recordingId != id) return;
    _pulse?.cancel();
    state = const RecordingsPlaybackState();
  }

  void closePreview() {
    _pulse?.cancel();
    scheduleMicrotask(() {
      if (ref.mounted) pause();
    });
  }
}
