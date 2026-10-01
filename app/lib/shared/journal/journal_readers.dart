import 'journal_models.dart';
import 'practice_date.dart';

/// Empty means a successful query with no records; storage errors must throw.
abstract interface class JournalProfileReader {
  Future<List<JournalProfile>> list();
  Future<JournalProfile?> find(String profileId);
}

abstract interface class JournalSessionReader {
  /// Global unfinished session; reading does not transition its state.
  Future<PracticeDraft?> unfinished();
  Future<PracticeSession?> findSaved({
    required String profileId,
    required String sessionId,
  });
  Future<List<PracticeSession>> saved({
    required String profileId,
    PracticeDate? from,
    PracticeDate? through,
    String query = '',
  });
}

abstract interface class JournalPreferencesReader {
  /// No row is distinct from persisted settings and requires bootstrap defaults.
  Future<JournalPreferences?> read();
}
