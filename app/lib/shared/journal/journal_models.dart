import 'practice_date.dart';

/// Database protocol values; no labels or widget dependencies.
enum JournalInstrument { guitar, piano, ukulele, violin, flute, drums, other }

enum PracticeState { running, paused, review, saved }

class JournalProfile {
  const JournalProfile({
    required this.id,
    required this.name,
    required this.instrument,
    required this.customType,
    required this.createdAt,
    required this.updatedAt,
  });
  final String id;
  final String name;
  final JournalInstrument instrument;
  final String customType;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class PracticeSession {
  const PracticeSession({
    required this.id,
    required this.profileId,
    required this.state,
    required this.title,
    required this.practiceDate,
    required this.startOffsetMinutes,
    required this.createdAt,
    required this.updatedAt,
    this.durationSeconds,
    this.measuredDurationSeconds,
    this.practiced = '',
    this.difficulty = '',
    this.next = '',
    this.mood,
    this.focus,
    this.bpm,
  });
  final String id;
  final String profileId;
  final PracticeState state;
  final String title;
  final PracticeDate practiceDate;
  final int startOffsetMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? durationSeconds;
  final int? measuredDurationSeconds;
  final String practiced;
  final String difficulty;
  final String next;
  final int? mood;
  final int? focus;
  final int? bpm;
}

/// Review strings deliberately retain invalid/unfinished form input.
class ReviewInput {
  const ReviewInput({
    required this.title,
    required this.practiceDate,
    required this.durationHoursInput,
    required this.durationMinutesInput,
    required this.durationSecondsInput,
    required this.practiced,
    required this.difficulty,
    required this.next,
    required this.mood,
    required this.focus,
  });
  final String title;
  final String practiceDate;
  final String durationHoursInput;
  final String durationMinutesInput;
  final String durationSecondsInput;
  final String practiced;
  final String difficulty;
  final String next;
  final int? mood;
  final int? focus;
}

class PracticeDraft {
  const PracticeDraft({
    required this.session,
    required this.accumulatedMilliseconds,
    required this.checkpointAt,
    required this.updatedAt,
    this.reviewInput,
  });
  final PracticeSession session;
  final int accumulatedMilliseconds;
  final DateTime checkpointAt;
  final DateTime updatedAt;
  final ReviewInput? reviewInput;
}

enum JournalLanguage { vi, en }

class JournalPreferences {
  const JournalPreferences({
    required this.language,
    required this.selectedProfileId,
    required this.updatedAt,
  });
  final JournalLanguage language;
  final String? selectedProfileId;
  final DateTime updatedAt;
}
