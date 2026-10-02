/// UC-08 presentation limits and initial values from Tempo and the SRS.
abstract final class MetronomeUiLimits {
  static const minimumBpm = 40;
  static const maximumBpm = 240;
  static const initialBpm = 80;
  static const minimumBeats = 1;
  static const maximumBeats = 12;
  static const initialBeats = 4;
  static const microsecondsPerMinute =
      Duration.microsecondsPerSecond * Duration.secondsPerMinute;
}

enum MetronomeUiError { bpmRange, beatsRange, audioBusy }

class MetronomeUiState {
  const MetronomeUiState({
    this.bpm = MetronomeUiLimits.initialBpm,
    this.beatsPerBar = MetronomeUiLimits.initialBeats,
    this.playing = false,
    this.activeBeat,
    this.error,
  });

  final int bpm, beatsPerBar;
  final bool playing;
  final int? activeBeat;
  final MetronomeUiError? error;

  MetronomeUiState copyWith({
    int? bpm,
    int? beatsPerBar,
    bool? playing,
    int? activeBeat,
    MetronomeUiError? error,
  }) => MetronomeUiState(
    bpm: bpm ?? this.bpm,
    beatsPerBar: beatsPerBar ?? this.beatsPerBar,
    playing: playing ?? this.playing,
    activeBeat: activeBeat,
    error: error,
  );
}
