import '../frontend/application/session_form_values.dart';
import '../frontend/practice_sessions/practice_session.dart' as ui;
import '../shared/journal/journal_models.dart' as journal;
import '../shared/journal/practice_date.dart';
import '../shared/journal/practice_review_service.dart';

ui.PracticeSession presentPracticeSession(
  journal.PracticeSession session, {
  ui.PracticeSession? original,
}) => ui.PracticeSession(
  id: session.id,
  profileId: session.profileId,
  date: DateTime.parse(session.practiceDate.value),
  title: session.title,
  duration: Duration(seconds: session.durationSeconds!),
  practiced: session.practiced,
  difficulty: session.difficulty,
  nextPractice: session.next,
  mood: session.mood,
  focus: session.focus,
  bpm: session.bpm,
  recordingCount: original?.recordingCount ?? 0,
  recordings: original?.recordings ?? const [],
);

PracticeReviewValues journalReviewValues(SessionFormValues values) =>
    PracticeReviewValues(
      title: values.title,
      date: PracticeDate.fromLocal(values.date),
      durationSeconds: values.durationSeconds,
      practiced: values.practiced,
      difficulty: values.difficulty,
      next: values.next,
      mood: values.mood,
      focus: values.focus,
      bpm: values.bpm,
    );
