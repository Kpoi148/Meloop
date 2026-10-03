import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/backend/database/journal_database.dart';
import 'package:meloop/backend/database/journal_database_owner.dart';
import 'package:meloop/backend/journal/sqlite_practice_session_update_service.dart';
import 'package:meloop/backend/journal/sqlite_journal_readers.dart';
import 'package:meloop/backend/journal/sqlite_practice_review_service.dart';
import 'package:meloop/shared/journal/journal_failure.dart';
import 'package:meloop/shared/journal/practice_date.dart';
import 'package:meloop/shared/journal/practice_review_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../database/journal_database_test.dart'
    show
        addProfile,
        addRecording,
        sessionRow,
        profileId,
        otherProfileId,
        sessionId,
        otherSessionId;
import 'journal_foundation_test.dart' show TestClock;

void main() {
  sqfliteFfiInit();
  late Directory temp;
  late JournalDatabaseOwner owner;
  late SqlitePracticeSessionUpdateService service;
  void reopen() {
    owner = JournalDatabaseOwner(
      open: () => JournalDatabase.open(
        factory: databaseFactoryFfi,
        path: '${temp.path}/journal.db',
      ),
    );
    service = SqlitePracticeSessionUpdateService(
      owner: owner,
      clock: TestClock(),
    );
  }

  PracticeReviewValues values({
    String title = '  Luyện mới  ',
    String date = '2026-09-30',
    int duration = 95,
    String practiced = 'Âm dài',
    int? mood = 5,
    int? bpm = 100,
  }) => PracticeReviewValues(
    title: title,
    date: PracticeDate.parse(date),
    durationSeconds: duration,
    practiced: practiced,
    difficulty: '',
    next: 'Lần sau',
    mood: mood,
    focus: null,
    bpm: bpm,
  );
  final invalid = throwsA(
    isA<JournalFailure>().having(
      (e) => e.code,
      'code',
      JournalFailureCode.invalidInput,
    ),
  );
  Future<Map<String, Object?>> row() => owner.read(
    (db) async => (await db.query(
      'practice_sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
    )).single,
  );
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('meloop-update-');
    reopen();
    await owner.read((executor) async {
      final db = executor as Database;
      await addProfile(db);
      await addProfile(db, id: otherProfileId, name: 'Flute');
      await db.insert('practice_sessions', sessionRow(state: 'review'));
      await addRecording(db);
      await db.update('session_drafts', {'accumulated_ms': 60000});
      await db.update(
        'practice_sessions',
        {
          'state': 'saved',
          'duration_seconds': 60,
          'measured_duration_seconds': 60,
        },
        where: 'id = ?',
        whereArgs: [sessionId],
      );
      await db.insert(
        'practice_sessions',
        sessionRow(
          id: otherSessionId,
          profile: otherProfileId,
          state: 'paused',
        ),
      );
    });
  });
  tearDown(() async {
    await owner.close();
    await temp.delete(recursive: true);
  });
  test('edit/retry/reopen retains identity measurement recordings and another profile draft; search keys refresh', () async {
    final before = await row();
    final clips = await owner.read((db) => db.query('recordings'));
    final drafts = await owner.read((db) => db.query('session_drafts'));
    await service.update(
      profileId: profileId,
      sessionId: sessionId,
      values: values(),
    );
    await service.update(
      profileId: profileId,
      sessionId: sessionId,
      values: values(),
    );
    final after = await row();
    for (final key in [
      'id',
      'profile_id',
      'state',
      'created_at',
      'start_offset_minutes',
      'measured_duration_seconds',
    ]) {
      expect(after[key], before[key]);
    }
    expect(after['duration_seconds'], 95);
    expect(after['title'], 'Luyện mới');
    expect(after['focus'], isNull);
    expect(await owner.read((db) => db.query('recordings')), clips);
    expect(await owner.read((db) => db.query('session_drafts')), drafts);
    expect(
      await SqliteJournalSessionReader(owner)
          .saved(profileId: profileId, query: 'am dai'),
      hasLength(1),
    );
    await owner.close();
    reopen();
    expect((await row())['title'], 'Luyện mới');
  });
  test('wrong owner, draft, missing/deleted identity and invalid fields cannot edit committed data', () async {
    final before = await row();
    await expectLater(
      service.update(
        profileId: otherProfileId,
        sessionId: sessionId,
        values: values(),
      ),
      invalid,
    );
    await expectLater(
      service.update(
        profileId: otherProfileId,
        sessionId: otherSessionId,
        values: values(),
      ),
      invalid,
    );
    await expectLater(
      service.update(profileId: profileId, sessionId: 'bad', values: values()),
      invalid,
    );
    for (final v in [
      values(title: ''),
      values(date: '2026-10-01'),
      values(duration: 0),
      values(duration: 86401),
      values(practiced: List.filled(2001, 'a').join()),
      values(mood: 0),
      values(bpm: 401),
    ]) {
      await expectLater(
        service.update(profileId: profileId, sessionId: sessionId, values: v),
        invalid,
      );
    }
    expect(await row(), before);
    await owner.read(
      (db) => db.update(
        'practice_sessions',
        {'deleted_at': before['updated_at']},
        where: 'id = ?',
        whereArgs: [sessionId],
      ),
    );
    await expectLater(
      service.update(
        profileId: profileId,
        sessionId: sessionId,
        values: values(),
      ),
      invalid,
    );
  });
  test('SQL failure retains previous record; retry succeeds', () async {
    final before = await row();
    await owner.read(
      (db) => db.execute(
        "CREATE TRIGGER fail_update BEFORE UPDATE ON practice_sessions BEGIN SELECT RAISE(ABORT, 'injected'); END",
      ),
    );
    await expectLater(
      service.update(
        profileId: profileId,
        sessionId: sessionId,
        values: values(),
      ),
      throwsA(
        isA<JournalFailure>().having(
          (e) => e.code,
          'code',
          JournalFailureCode.storage,
        ),
      ),
    );
    expect(await row(), before);
    await owner.read((db) => db.execute('DROP TRIGGER fail_update'));
    await service.update(
      profileId: profileId,
      sessionId: sessionId,
      values: values(),
    );
    expect((await row())['title'], 'Luyện mới');
  });
  test('new Save uses the same future-date validation and retains Review on failure', () async {
    await owner.read(
      (db) => db.update(
        'practice_sessions',
        {'state': 'review'},
        where: 'id = ?',
        whereArgs: [otherSessionId],
      ),
    );
    final review = SqlitePracticeReviewService(
      owner: owner,
      clock: TestClock(),
    );
    await expectLater(
      review.save(otherSessionId, values(date: '2026-10-01')),
      invalid,
    );
    expect(
      (await SqliteJournalSessionReader(owner)
              .unfinished(profileId: otherProfileId))!
          .session
          .state
          .name,
      'review',
    );
  });
}
