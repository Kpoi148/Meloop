import 'dart:async';

import '../../shared/pitch/pitch_service.dart';

/// Explicit visual-review adapter; never installed in the journal app.
/// It has no microphone, pitch detection, files or persistent data.
class PitchPreviewService implements PitchService {
  PitchPreviewService({
    PitchConfiguration configuration = PitchConfiguration.standard,
    this.startPhase = PitchPhase.listening,
    this.settingsAvailable = false,
  }) : _snapshot = PitchSnapshot(configuration: configuration);

  final PitchPhase startPhase;
  final bool settingsAvailable;
  final _changes = StreamController<PitchSnapshot>.broadcast(sync: true);
  PitchSnapshot _snapshot;
  bool _closed = false;

  @override
  PitchSnapshot get snapshot => _snapshot;
  @override
  Stream<PitchSnapshot> get changes => _changes.stream;

  void present(PitchPhase phase, {PitchReading? reading}) {
    if (_closed) return;
    _snapshot = PitchSnapshot(
      configuration: _snapshot.configuration,
      phase: phase,
      sample: reading,
    );
    _changes.add(_snapshot);
  }

  @override
  Future<void> start() async => present(startPhase);

  @override
  Future<void> stop() async => present(PitchPhase.idle);

  @override
  Future<bool> openAppSettings() async => settingsAvailable;

  Future<void> close() async {
    _closed = true;
    await _changes.close();
  }
}
