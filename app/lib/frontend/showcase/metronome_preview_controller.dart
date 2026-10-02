import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../metronome/metronome_ui_state.dart';

/// UI integration seam for the audio tool's availability. No device audio here.
final metronomeAudioBusyProvider = Provider<bool>((ref) => false);

final metronomePreviewControllerProvider =
    NotifierProvider<MetronomePreviewController, MetronomeUiState>(
      MetronomePreviewController.new,
    );

/// In-memory presentation driver for reviewing UC-08 before audio is connected.
/// The widget reads one snapshot for the value, button and beat indicator.
class MetronomePreviewController extends Notifier<MetronomeUiState> {
  Timer? _pulse;

  @override
  MetronomeUiState build() {
    ref.onDispose(() => _pulse?.cancel());
    ref.listen(metronomeAudioBusyProvider, (_, busy) {
      if (busy && state.playing) {
        stop();
        state = state.copyWith(error: MetronomeUiError.audioBusy);
      }
    });
    return const MetronomeUiState();
  }

  void setBpm(int value) {
    if (value < MetronomeUiLimits.minimumBpm ||
        value > MetronomeUiLimits.maximumBpm) {
      state = state.copyWith(
        activeBeat: state.activeBeat,
        error: MetronomeUiError.bpmRange,
      );
      return;
    }
    state = state.copyWith(bpm: value, activeBeat: state.activeBeat);
    if (state.playing) _startPulse();
  }

  void setBeats(int value) {
    if (value < MetronomeUiLimits.minimumBeats ||
        value > MetronomeUiLimits.maximumBeats) {
      state = state.copyWith(
        activeBeat: state.activeBeat,
        error: MetronomeUiError.beatsRange,
      );
      return;
    }
    state = state.copyWith(
      beatsPerBar: value,
      activeBeat: state.playing ? 0 : null,
    );
    if (state.playing) _startPulse();
  }

  void toggle() {
    if (state.playing) {
      stop();
      return;
    }
    if (ref.read(metronomeAudioBusyProvider)) {
      state = state.copyWith(error: MetronomeUiError.audioBusy);
      return;
    }
    state = state.copyWith(playing: true, activeBeat: 0);
    _startPulse();
  }

  void _startPulse() {
    _pulse?.cancel();
    final interval = Duration(
      microseconds: (MetronomeUiLimits.microsecondsPerMinute / state.bpm)
          .round(),
    );
    _pulse = Timer.periodic(interval, (_) {
      state = state.copyWith(
        activeBeat: ((state.activeBeat ?? 0) + 1) % state.beatsPerBar,
        error: state.error,
      );
    });
  }

  void stop() {
    _pulse?.cancel();
    _pulse = null;
    if (!ref.mounted) return;
    state = state.copyWith(playing: false);
  }

  void closePreview() {
    _pulse?.cancel();
    _pulse = null;
    // Route disposal runs while Flutter is finalizing its widget tree.
    scheduleMicrotask(() {
      if (ref.mounted) stop();
    });
  }
}
