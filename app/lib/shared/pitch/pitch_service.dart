enum PitchPhase {
  idle,
  requestingPermission,
  listening,
  weakSignal,
  detected,
  permissionDenied,
  permissionBlocked,
  unavailable,
  audioBusy,
  failed,
  stopFailed,
}

enum PitchDirection { low, inTune, high }

/// Detection range and reference come from the audio service, not the widget.
class PitchConfiguration {
  const PitchConfiguration({
    required this.lowestNote,
    required this.highestNote,
    required this.referenceNote,
    required this.referenceHz,
  });

  static const standard = PitchConfiguration(
    lowestNote: 'C2',
    highestNote: 'C6',
    referenceNote: 'A4',
    referenceHz: 440,
  );

  final String lowestNote, highestNote, referenceNote;
  final double referenceHz;
}

/// The service decides low/in-tune/high; the frontend does not classify audio.
class PitchReading {
  const PitchReading({
    required this.note,
    required this.frequencyHz,
    required this.cents,
    required this.direction,
  });

  final String note;
  final double frequencyHz, cents;
  final PitchDirection direction;

  bool get isValid =>
      note.trim().isNotEmpty &&
      frequencyHz.isFinite &&
      frequencyHz > 0 &&
      cents.isFinite;
}

class PitchSnapshot {
  const PitchSnapshot({
    this.configuration = PitchConfiguration.standard,
    this.phase = PitchPhase.idle,
    this.sample,
  });

  final PitchConfiguration configuration;
  final PitchPhase phase;
  final PitchReading? sample;

  /// Never expose an old or invalid measurement as a current result.
  PitchReading? get reading =>
      phase == PitchPhase.detected && sample?.isValid == true ? sample : null;

  bool get listening => switch (phase) {
    PitchPhase.requestingPermission ||
    PitchPhase.listening ||
    PitchPhase.weakSignal ||
    PitchPhase.detected => true,
    _ => false,
  };

  PitchSnapshot withPhase(PitchPhase next) =>
      PitchSnapshot(configuration: configuration, phase: next);
}

/// UC-09 integration port. No journal or recording storage is involved.
abstract interface class PitchService {
  PitchSnapshot get snapshot;
  Stream<PitchSnapshot> get changes;

  /// Requests access only after the user starts listening. Reports denial,
  /// permanently blocked access, weak signal and audio conflicts via snapshots.
  Future<void> start();

  /// Idempotent. Releases the microphone and cancels pending permission/start
  /// work. Must complete only when audio capture has stopped.
  Future<void> stop();

  /// Opens this app's Android settings; false means manual guidance is needed.
  Future<bool> openAppSettings();
}
