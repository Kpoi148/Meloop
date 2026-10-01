import 'journal_models.dart';

abstract interface class MonotonicClock {
  int get elapsedMilliseconds;
}

abstract interface class PracticeScreenAwake {
  Future<void> setEnabled(bool enabled);
}

abstract interface class PracticeTimerStore {
  Future<PracticeDraft> checkpoint({
    required String sessionId,
    required String profileId,
    required int accumulatedMilliseconds,
    required PracticeState state,
  });
}

class PracticeTimerSnapshot {
  const PracticeTimerSnapshot({
    required this.sessionId,
    required this.profileId,
    required this.state,
    required this.elapsedMilliseconds,
    required this.persistedMilliseconds,
    this.busy = false,
    this.failed = false,
  });
  final String sessionId, profileId;
  final PracticeState state;
  final int elapsedMilliseconds, persistedMilliseconds;
  final bool busy, failed;
}

abstract interface class PracticeTimerService {
  PracticeTimerSnapshot? get snapshot;
  Stream<PracticeTimerSnapshot> get changes;

  /// Cold recovery pauses without adding wall-clock time; Review is preserved.
  Future<void> open(PracticeDraft draft, {bool newlyStarted = false});
  Future<void> pause();
  Future<void> resume();
  Future<void> retry();
  void setForeground(bool foreground);
  Future<void> close();
}
