import '../../shared/journal/journal_failure.dart';
import '../../shared/journal/journal_runtime.dart';
import '../../shared/journal/journal_text.dart';
import '../../shared/journal/practice_date.dart';
import '../../shared/journal/practice_review_service.dart';

bool validPracticeRating(int? value) =>
    value == null ||
    (value >= PracticeRules.minimumRating &&
        value <= PracticeRules.maximumRating);

/// Shared by Review Save and saved-session Edit before their transactions write.
Map<String, Object?> validatedReviewFields(
  PracticeReviewValues values,
  JournalClock clock,
) {
  if (values.date.isAfter(PracticeDate.fromLocal(clock.localNow())) ||
      values.durationSeconds < PracticeRules.minimumDurationSeconds ||
      values.durationSeconds > PracticeRules.maximumDuration.inSeconds ||
      !validPracticeRating(values.mood) ||
      !validPracticeRating(values.focus) ||
      (values.bpm != null &&
          (values.bpm! < PracticeRules.minimumBpm ||
              values.bpm! > PracticeRules.maximumBpm))) {
    throw const JournalFailure(JournalFailureCode.invalidInput);
  }
  final title = JournalText.sessionTitle(values.title);
  final practiced = JournalText.note(values.practiced);
  final difficulty = JournalText.note(values.difficulty);
  final next = JournalText.note(values.next);
  return {
    'title': title,
    'practice_date': values.date.value,
    'duration_seconds': values.durationSeconds,
    'practiced': practiced,
    'difficulty': difficulty,
    'next_note': next,
    'mood': values.mood,
    'focus': values.focus,
    'bpm': values.bpm,
    'title_search': JournalText.searchKey(title),
    'practiced_search': JournalText.searchKey(practiced),
    'difficulty_search': JournalText.searchKey(difficulty),
    'next_search': JournalText.searchKey(next),
  };
}
