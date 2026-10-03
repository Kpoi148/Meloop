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
  PitchSnapshot? _prepared;
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
  Future<void> start() async =>
      present(_prepared?.phase ?? startPhase, reading: _prepared?.reading);

  /// Select a review scenario for the next explicit Start, clearing old data.
  void prepare(PitchPhase phase, {PitchReading? reading}) {
    _prepared = PitchSnapshot(
      configuration: _snapshot.configuration,
      phase: phase,
      sample: reading,
    );
    present(PitchPhase.idle);
  }

  @override
  Future<void> stop() async => present(PitchPhase.idle);

  @override
  Future<bool> openAppSettings() async => settingsAvailable;

  Future<void> close() async {
    _closed = true;
    await _changes.close();
  }
}
