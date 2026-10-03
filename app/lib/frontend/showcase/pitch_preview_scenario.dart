import '../../shared/pitch/pitch_service.dart';

/// Synthetic single-note samples for manual FE acceptance only.
enum PitchPreviewScenario {
  listening(PitchPhase.listening),
  inTune(
    PitchPhase.detected,
    PitchReading(
      note: 'A4',
      frequencyHz: 440,
      cents: 0,
      direction: PitchDirection.inTune,
    ),
  ),
  low(
    PitchPhase.detected,
    PitchReading(
      note: 'A4',
      frequencyHz: 435.9,
      cents: -16.2,
      direction: PitchDirection.low,
    ),
  ),
  high(
    PitchPhase.detected,
    PitchReading(
      note: 'A4',
      frequencyHz: 445.1,
      cents: 19.95,
      direction: PitchDirection.high,
    ),
  ),
  weakSignal(PitchPhase.weakSignal),
  permissionDenied(PitchPhase.permissionDenied),
  permissionBlocked(PitchPhase.permissionBlocked);

  const PitchPreviewScenario(this.phase, [this.reading]);
  final PitchPhase phase;
  final PitchReading? reading;
}
