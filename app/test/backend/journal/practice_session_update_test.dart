import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/backend/database/journal_database.dart';
import 'package:meloop/backend/database/journal_database_owner.dart';
import 'package:meloop/backend/journal/sqlite_journal_readers.dart';
import 'package:meloop/backend/journal/sqlite_practice_session_update_service.dart';
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
        sessionId;
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
    String title = 'Đã sửa',
    int seconds = 30,
    String date = '2026-09-29',
    String practiced = 'Âm dài\nchậm',
    String difficulty = '   ',
    int? mood,
    int? focus,
  }) => PracticeReviewValues(
    title: title,
    date: PracticeDate.parse(date),
    durationSeconds: seconds,
    practiced: practiced,
    difficulty: difficulty,
    next: '',
    mood: mood,
    focus: focus,
  );
  Future<void> update(
    PracticeReviewValues value, {
    String profile = profileId,
    String id = sessionId,
  }) async {
    await service.update(profileId: profile, sessionId: id, values: value);
  }

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('meloop-edit-');
    reopen();
    await owner.read((db) async {
      final database = db as Database;
      await addProfile(database);
      await addProfile(database, id: otherProfileId, name: 'Flute');
      await database.insert('practice_sessions', sessionRow(state: 'review'));
      await addRecording(database);
      await database.update(
        'session_drafts',
        {'accumulated_ms': 60000},
        where: 'session_id = ?',
        whereArgs: [sessionId],
      );
      await database.update(
        'practice_sessions',
        {
          'state': 'saved',
          'duration_seconds': 60,
          'measured_duration_seconds': 60,
          'mood': 4,
          'focus': 5,
        },
        where: 'id = ?',
        whereArgs: [sessionId],
      );
    });
  });
  tearDown(() async {
    await owner.close();
    await temp.delete(recursive: true);
  });

  test('Edit persists one row and clears optional fields; ownership, measurement and audio survive reopen', () async {
    final before = (await owner.read((db) => db.query('practice_sessions')))
        .single;
    final recordings = await owner.read((db) => db.query('recordings'));
    await Future.wait([update(values()), update(values())]);
    final rows = await owner.read((db) => db.query('practice_sessions'));
    expect(rows, hasLength(1));
    final edited = rows.single;
    expect(edited['title'], 'Đã sửa');
    expect(edited['practice_date'], '2026-09-29');
    expect(edited['duration_seconds'], 30);
    expect(edited['practiced'], 'Âm dài\nchậm');
    expect(edited['difficulty'], '');
    expect(edited['next_note'], '');
    expect(edited['mood'], isNull);
    expect(edited['focus'], isNull);
    for (final key in [
      'id',
      'profile_id',
      'measured_duration_seconds',
      'start_offset_minutes',
      'created_at',
    ]) {
      expect(edited[key], before[key], reason: key);
    }
    expect(await owner.read((db) => db.query('recordings')), recordings);
    expect(await owner.read((db) => db.query('session_drafts')), isEmpty);
    await owner.close();
    reopen();
    final saved = await SqliteJournalSessionReader(owner)
        .saved(profileId: profileId);
    expect(saved, hasLength(1));
    expect(saved.single.title, 'Đã sửa');
    expect(saved.single.durationSeconds, 30);
    expect(saved.single.mood, isNull);
    expect(
      await SqliteJournalSessionReader(owner)
          .saved(profileId: profileId, query: 'AM DAI'),
      hasLength(1),
    );
  });

  test(
    'transaction failure retains committed row and audio, then allows retry',
    () async {
      final before = await owner.read((db) => db.query('practice_sessions'));
      final audio = await owner.read((db) => db.query('recordings'));
      await owner.read(
        (db) => db.execute(
          "CREATE TRIGGER injected_edit BEFORE UPDATE ON practice_sessions BEGIN SELECT RAISE(ABORT,'injected'); END",
        ),
      );
      await expectLater(update(values()), throwsA(isA<JournalFailure>()));
      expect(await owner.read((db) => db.query('practice_sessions')), before);
      expect(await owner.read((db) => db.query('recordings')), audio);
      await owner.read((db) => db.execute('DROP TRIGGER injected_edit'));
      await update(values());
      expect(
        (await SqliteJournalSessionReader(owner).saved(profileId: profileId))
            .single
            .title,
        'Đã sửa',
      );
    },
  );

  test('domain rejects future dates, invalid bounds, ratings, controls and overlength Unicode without writing', () async {
    final before = await owner.read((db) => db.query('practice_sessions'));
    for (final value in [
      values(date: '2026-10-01'),
      values(seconds: 0),
      values(seconds: 86401),
      values(title: ''),
      values(title: 'Bad\nTitle'),
      values(title: List.filled(101, '😀').join()),
      values(practiced: List.filled(2001, '😀').join()),
      values(practiced: 'bad\u0000'),
      values(mood: 0),
      values(focus: 6),
    ]) {
      await expectLater(update(value), throwsA(isA<JournalFailure>()));
      expect(await owner.read((db) => db.query('practice_sessions')), before);
    }
    await update(
      values(
        title: List.filled(100, '😀').join(),
        practiced: List.filled(2000, '😀').join(),
        seconds: 86400,
      ),
    );
    expect(
      (await SqliteJournalSessionReader(owner).saved(profileId: profileId))
          .single
          .durationSeconds,
      86400,
    );
  });

  test(
    'wrong owner, unfinished and deleted sessions cannot be edited',
    () async {
      await expectLater(
        update(values(), profile: otherProfileId),
        throwsA(isA<JournalFailure>()),
      );
      const draftId = '00000000-0000-4000-8000-000000000013';
      await owner.read(
        (db) => db.insert(
          'practice_sessions',
          sessionRow(id: draftId, state: 'paused'),
        ),
      );
      await expectLater(
        update(values(), id: draftId),
        throwsA(isA<JournalFailure>()),
      );
      await owner.read(
        (db) => db.update(
          'practice_sessions',
          {'deleted_at': 1790726400000},
          where: 'id = ?',
          whereArgs: [sessionId],
        ),
      );
      await expectLater(update(values()), throwsA(isA<JournalFailure>()));
      expect(await owner.read((db) => db.query('recordings')), hasLength(1));
    },
  );
}
