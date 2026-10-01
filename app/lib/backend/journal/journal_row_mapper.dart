import 'dart:convert';

import '../../shared/journal/journal_models.dart';
import '../../shared/journal/journal_runtime.dart';
import '../../shared/journal/practice_date.dart';

String storedId(Object? value) {
  if (value is! String || !JournalId.isValid(value)) {
    throw const FormatException('Invalid stored identity');
  }
  return value;
}

DateTime storedUtc(Object? value) {
  if (value is! int || value < 0) {
    throw const FormatException('Invalid stored timestamp');
  }
  return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
}

JournalProfile profileFromRow(Map<String, Object?> row) => JournalProfile(
  id: storedId(row['id']),
  name: row['name'] as String,
  instrument: JournalInstrument.values.byName(row['instrument_type'] as String),
  customType: row['custom_type'] as String,
  createdAt: storedUtc(row['created_at']),
  updatedAt: storedUtc(row['updated_at']),
);

PracticeSession sessionFromRow(Map<String, Object?> row) => PracticeSession(
  id: storedId(row['id']),
  profileId: storedId(row['profile_id']),
  state: PracticeState.values.byName(row['state'] as String),
  title: row['title'] as String,
  practiceDate: PracticeDate.parse(row['practice_date'] as String),
  startOffsetMinutes: row['start_offset_minutes'] as int,
  createdAt: storedUtc(row['created_at']),
  updatedAt: storedUtc(row['updated_at']),
  durationSeconds: row['duration_seconds'] as int?,
  measuredDurationSeconds: row['measured_duration_seconds'] as int?,
  practiced: row['practiced'] as String,
  difficulty: row['difficulty'] as String,
  next: row['next_note'] as String,
  mood: row['mood'] as int?,
  focus: row['focus'] as int?,
);

ReviewInput? reviewFromJson(Object? value) {
  if (value == null) return null;
  final decoded = jsonDecode(value as String);
  const textKeys = {
    'title',
    'practiceDate',
    'durationHoursInput',
    'durationMinutesInput',
    'durationSecondsInput',
    'practiced',
    'difficulty',
    'next',
  };
  if (decoded is! Map<String, dynamic> ||
      decoded.length != textKeys.length + 2 ||
      !textKeys.every((key) => decoded[key] is String) ||
      !decoded.containsKey('mood') ||
      !decoded.containsKey('focus')) {
    throw const FormatException('Invalid stored review structure');
  }
  int? rating(String key) {
    final rating = decoded[key];
    if (rating == null || (rating is int && rating >= 1 && rating <= 5)) {
      return rating as int?;
    }
    throw const FormatException('Invalid stored rating');
  }

  return ReviewInput(
    title: decoded['title'] as String,
    practiceDate: decoded['practiceDate'] as String,
    durationHoursInput: decoded['durationHoursInput'] as String,
    durationMinutesInput: decoded['durationMinutesInput'] as String,
    durationSecondsInput: decoded['durationSecondsInput'] as String,
    practiced: decoded['practiced'] as String,
    difficulty: decoded['difficulty'] as String,
    next: decoded['next'] as String,
    mood: rating('mood'),
    focus: rating('focus'),
  );
}
