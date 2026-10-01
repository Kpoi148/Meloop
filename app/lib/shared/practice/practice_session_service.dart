import 'session_form_values.dart';

/// The backend owns the clock, transitions, persistence and save idempotency.
/// Every command returns only after its state has been committed.
abstract interface class PracticeSessionService {
  PracticeSessionState get current;
  Stream<PracticeSessionState> get changes;

  Future<PracticeSessionDraft> start({
    required String profileId,
    required String title,
  });
  Future<void> pause();
  Future<void> resume();
  Future<PracticeSessionDraft> finish();
  Future<void> leaveReview();
  Future<void> rename(String title);
  Future<void> discard();

  /// Use the draft ID as the stable save identity, including after a retry.
  Future<SavedPracticeSession> save(String draftId, SessionFormValues values);
}

enum PracticeSessionPhase { running, paused, review }

class PracticeSessionDraft {
  const PracticeSessionDraft({
    required this.id,
    required this.profileId,
    required this.title,
    required this.startedAt,
    this.elapsed = Duration.zero,
    this.phase = PracticeSessionPhase.paused,
    this.wasRecovered = false,
  });

  final String id, profileId, title;
  final DateTime startedAt;
  final Duration elapsed;
  final PracticeSessionPhase phase;
  final bool wasRecovered;

  bool get isRunning => phase == PracticeSessionPhase.running;

  PracticeSessionDraft copyWith({
    String? title,
    Duration? elapsed,
    PracticeSessionPhase? phase,
    bool? wasRecovered,
  }) => PracticeSessionDraft(
    id: id,
    profileId: profileId,
    title: title ?? this.title,
    startedAt: startedAt,
    elapsed: elapsed ?? this.elapsed,
    phase: phase ?? this.phase,
    wasRecovered: wasRecovered ?? this.wasRecovered,
  );
}

class SavedPracticeSession {
  const SavedPracticeSession({
    required this.id,
    required this.profileId,
    required this.values,
  });

  final String id, profileId;
  final SessionFormValues values;
}

class PracticeSessionState {
  const PracticeSessionState({this.draft, this.sessions = const []});

  final PracticeSessionDraft? draft;
  final List<SavedPracticeSession> sessions;
}
