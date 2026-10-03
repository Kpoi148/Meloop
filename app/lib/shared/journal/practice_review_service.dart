import 'journal_models.dart';
import 'practice_date.dart';

class PracticeReviewValues {
  const PracticeReviewValues({
    required this.title,
    required this.date,
    required this.durationSeconds,
    required this.practiced,
    required this.difficulty,
    required this.next,
    this.mood,
    this.focus,
    this.bpm,
  });
  final String title, practiced, difficulty, next;
  final PracticeDate date;
  final int durationSeconds;
  final int? mood, focus, bpm;
}

abstract interface class PracticeReviewService {
  Future<String> rename(String sessionId, String title);
  Future<PracticeDraft> read(String sessionId);
  Future<void> persistInput(String sessionId, ReviewInput input);

  /// Updates the existing Review row atomically; repeated IDs return that Save.
  Future<PracticeSession> save(String sessionId, PracticeReviewValues values);
}
