import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/backend/database/journal_database_owner.dart';
import 'package:meloop/backend/journal/sqlite_practice_statistics_reader.dart';
import 'package:meloop/backend/journal/sqlite_practice_review_service.dart';
import 'package:meloop/backend/journal/sqlite_practice_session_update_service.dart';
import 'package:meloop/backend/journal/sqlite_practice_session_delete_service.dart';
import 'package:meloop/shared/journal/journal_failure.dart';
import 'package:meloop/shared/journal/journal_runtime.dart';
import 'package:meloop/shared/journal/practice_date.dart';
import 'package:meloop/shared/journal/practice_review_service.dart';

class StatisticsLocalClock implements JournalClock {
  @override
  DateTime localNow() => DateTime(2026, 10, 1, 0, 30);
  @override
  DateTime utcNow() => DateTime.utc(2026, 9, 30, 17, 30);
}

/// Real mutations verify recomputation and no writes by the statistics reader.
Future<void> runPracticeStatisticsJourney(JournalDatabaseOwner owner) async {
  const profile = '00000000-0000-4000-8000-000000000001';
  const other = '00000000-0000-4000-8000-000000000002';
  const saved = '00000000-0000-4000-8000-000000000011';
  const review = '00000000-0000-4000-8000-000000000012';
  const otherSession = '00000000-0000-4000-8000-000000000013';
  final clock = StatisticsLocalClock();
  final reader = SqlitePracticeStatisticsReader(owner: owner, clock: clock);
  PracticeReviewValues values(int seconds) => PracticeReviewValues(
    title: 'Statistics QA',
    date: PracticeDate.parse('2026-10-01'),
    durationSeconds: seconds,
    practiced: '',
    difficulty: '',
    next: '',
  );
  await owner.read((db) async {
    final timestamp = clock.utcNow().millisecondsSinceEpoch;
    for (final (id, name) in [(profile, 'Guitar QA'), (other, 'Flute QA')]) {
      await db.insert('instrument_profiles', {
        'id': id,
        'name': name,
        'name_key': name.toLowerCase(),
        'instrument_type': 'guitar',
        'created_at': timestamp,
        'updated_at': timestamp,
      });
    }
    for (final (id, ownerId, state) in [
      (saved, profile, 'saved'),
      (review, profile, 'review'),
      (otherSession, other, 'saved'),
    ]) {
      await db.insert('practice_sessions', {
        'id': id,
        'profile_id': ownerId,
        'state': state,
        'title': 'Statistics QA',
        'practice_date': '2026-10-01',
        'start_offset_minutes': clock.localNow().timeZoneOffset.inMinutes,
        'created_at': timestamp,
        'updated_at': timestamp,
        if (state == 'saved') ...{
          'duration_seconds': ownerId == profile ? 60 : 600,
          'measured_duration_seconds': 60,
        },
      });
    }
  });
  Future<Map<String, Object?>> snapshot() => owner.read(
    (db) async => {
      for (final table in [
        'practice_sessions',
        'session_drafts',
        'weekly_goals',
      ])
        table: await db.query(table, orderBy: 'rowid'),
    },
  );
  final before = await snapshot();
  final initial = await reader.read(profile);
  expect(initial.totalSeconds, 60);
  expect(initial.sessionCount, 1);
  expect(initial.consecutiveDays, 1);
  expect(initial.qualifyingDaysThisWeek, 1);
  expect(await snapshot(), before);
  await SqlitePracticeSessionUpdateService(
    owner: owner,
    clock: clock,
  ).update(profileId: profile, sessionId: saved, values: values(30));
  final edited = await reader.read(profile);
  expect(edited.totalSeconds, 30);
  expect(edited.consecutiveDays, 0);
  expect(edited.qualifyingDaysThisWeek, 0);
  await SqlitePracticeReviewService(
    owner: owner,
    clock: clock,
  ).save(review, values(30));
  final combined = await reader.read(profile);
  expect(combined.totalSeconds, 60);
  expect(combined.minutes, 1);
  expect(combined.sessionCount, 2);
  expect(combined.qualifyingDaysThisWeek, 0);
  await SqlitePracticeSessionDeleteService(
    owner: owner,
    clock: clock,
  ).delete(profileId: profile, sessionId: saved);
  expect((await reader.read(profile)).totalSeconds, 30);
  await SqlitePracticeSessionDeleteService(
    owner: owner,
    clock: clock,
  ).delete(profileId: profile, sessionId: review);
  final empty = await reader.read(profile);
  expect(empty.sessionCount, 0);
  expect(empty.totalSeconds, 0);
  expect((await reader.read(other)).totalSeconds, 600);
  await owner.close();
  await expectLater(
    reader.read(profile),
    throwsA(
      isA<JournalFailure>().having(
        (error) => error.code,
        'code',
        JournalFailureCode.closed,
      ),
    ),
  );
}
