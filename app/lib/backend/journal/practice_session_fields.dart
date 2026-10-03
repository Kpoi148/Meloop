import '../../shared/journal/journal_failure.dart';
import '../../shared/journal/journal_text.dart';
import '../../shared/journal/practice_date.dart';
import '../../shared/journal/practice_review_service.dart';

/// Whitelist of editable fields; never includes identity or measured duration.
Map<String, Object?> practiceSessionFields(
  PracticeReviewValues values, {
  required DateTime localToday,
}) {
  final title = JournalText.sessionTitle(values.title);
  bool validRating(int? value) =>
      value == null ||
      (value >= PracticeRules.minimumRating &&
          value <= PracticeRules.maximumRating);
  if (values.date.isAfter(PracticeDate.fromLocal(localToday)) ||
      values.durationSeconds < 1 ||
      values.durationSeconds > PracticeRules.maximumDuration.inSeconds ||
      !validRating(values.mood) ||
      !validRating(values.focus) ||
      (values.bpm != null &&
          (values.bpm! < PracticeRules.minimumBpm ||
              values.bpm! > PracticeRules.maximumBpm)) ||
      [values.practiced, values.difficulty, values.next].any(
        (text) =>
            text.runes.length > PracticeRules.noteMaxCodePoints ||
            text.contains('\u0000'),
      )) {
    throw const JournalFailure(JournalFailureCode.invalidInput);
  }
  return {
    'title': title,
    'practice_date': values.date.value,
    'duration_seconds': values.durationSeconds,
    'practiced': values.practiced,
    'difficulty': values.difficulty,
    'next_note': values.next,
    'mood': values.mood,
    'focus': values.focus,
    'bpm': values.bpm,
    'title_search': JournalText.searchKey(title),
    'practiced_search': JournalText.searchKey(values.practiced),
    'difficulty_search': JournalText.searchKey(values.difficulty),
    'next_search': JournalText.searchKey(values.next),
  };
}
