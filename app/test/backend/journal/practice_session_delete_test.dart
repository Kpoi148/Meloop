import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/backend/database/journal_database.dart';
import 'package:meloop/backend/database/journal_database_owner.dart';
import 'package:meloop/backend/journal/sqlite_instrument_profile_service.dart';
import 'package:meloop/backend/journal/sqlite_journal_readers.dart';
import 'package:meloop/backend/journal/sqlite_practice_review_service.dart';
import 'package:meloop/backend/journal/sqlite_practice_session_delete_service.dart';
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
        otherSessionId,
        timestamp;
import 'journal_foundation_test.dart' show TestClock;

void main() {
  sqfliteFfiInit();
  late Directory temp;
  late JournalDatabaseOwner owner;
  late SqlitePracticeSessionDeleteService service;
  final invalid = throwsA(
    isA<JournalFailure>().having(
      (error) => error.code,
      'code',
      JournalFailureCode.invalidInput,
    ),
  );
  void reopen() {
    owner = JournalDatabaseOwner(
      open: () => JournalDatabase.open(
        factory: databaseFactoryFfi,
        path: '${temp.path}/journal.db',
      ),
    );
    service = SqlitePracticeSessionDeleteService(
      owner: owner,
      clock: TestClock(),
    );
  }

  Future<void> seed({bool recording = false}) async {
    await owner.read((db) async {
      // Helpers use Database for test fixtures; the owner still owns lifetime.
      final database = db as Database;
      await addProfile(database);
      await addProfile(database, id: otherProfileId, name: 'Flute');
      if (recording) {
        await database.insert('practice_sessions', sessionRow(state: 'review'));
        await addRecording(database);
        await database.update('session_drafts', {'accumulated_ms': 60000});
        await database.update(
          'practice_sessions',
          {
            'state': 'saved',
            'duration_seconds': 60,
            'measured_duration_seconds': 60,
          },
          where: 'id = ?',
          whereArgs: [sessionId],
        );
      } else {
        await database.insert('practice_sessions', sessionRow(state: 'saved'));
      }
      await database.insert(
        'practice_sessions',
        sessionRow(id: otherSessionId, profile: otherProfileId, state: 'saved'),
      );
      await database.insert(
        'practice_sessions',
        sessionRow(
          id: '00000000-0000-4000-8000-000000000013',
          profile: otherProfileId,
          state: 'paused',
        ),
      );
    });
  }

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('meloop-delete-');
    reopen();
  });
  tearDown(() async {
    await owner.close();
    await temp.delete(recursive: true);
  });

  test('confirmed delete removes only its saved row; concurrent retry and reopen are idempotent', () async {
    await seed();
    final before = await owner.read((db) => db.query('session_drafts'));
    await Future.wait(
      List.generate(
        2,
        (_) => service.delete(profileId: profileId, sessionId: sessionId),
      ),
    );
    expect(
      await owner.read(
        (db) => db.query(
          'practice_sessions',
          where: 'id = ?',
          whereArgs: [sessionId],
        ),
      ),
      isEmpty,
    );
    expect(
      await SqliteJournalSessionReader(owner).saved(profileId: otherProfileId),
      hasLength(1),
    );
    expect(await owner.read((db) => db.query('session_drafts')), before);
    await owner.close();
    reopen();
    await service.delete(profileId: profileId, sessionId: sessionId);
    expect(
      await SqliteJournalSessionReader(owner).saved(profileId: profileId),
      isEmpty,
    );
    expect(
      await SqliteJournalSessionReader(owner)
          .findSaved(profileId: profileId, sessionId: sessionId),
      isNull,
    );
  });

  test('delete retains recording metadata and file ownership, but excludes journal detail and profile totals', () async {
    await seed(recording: true);
    final recordings = await owner.read((db) => db.query('recordings'));
    await service.delete(profileId: profileId, sessionId: sessionId);
    await service.delete(profileId: profileId, sessionId: sessionId);
    expect(await owner.read((db) => db.query('recordings')), recordings);
    expect(await owner.read((db) => db.query('file_cleanup_queue')), isEmpty);
    expect(
      await owner.read((db) => db.rawQuery('PRAGMA foreign_key_check')),
      isEmpty,
    );
    final row = (await owner.read(
      (db) => db.query(
        'practice_sessions',
        where: 'id = ?',
        whereArgs: [sessionId],
      ),
    )).single;
    expect(row['deleted_at'], timestamp);
    expect(row['state'], 'saved');
    final directory = await SqliteInstrumentProfileService(
      owner: owner,
      initialLanguage: 'vi',
    ).load();
    expect(directory.byId(profileId)!.savedSessionCount, 0);
    expect(directory.byId(profileId)!.recordingCount, 1);
    expect(directory.byId(otherProfileId)!.savedSessionCount, 1);
    await expectLater(
      SqlitePracticeReviewService(owner: owner).save(
        sessionId,
        PracticeReviewValues(
          title: 'Retry',
          date: PracticeDate.parse('2026-09-30'),
          durationSeconds: 60,
          practiced: '',
          difficulty: '',
          next: '',
          mood: null,
          focus: null,
          bpm: null,
        ),
      ),
      invalid,
    );
    await owner.close();
    reopen();
    expect(
      await SqliteJournalSessionReader(owner).saved(profileId: profileId),
      isEmpty,
    );
    expect(
      await SqliteJournalSessionReader(owner)
          .findSaved(profileId: profileId, sessionId: sessionId),
      isNull,
    );
    expect(await owner.read((db) => db.query('recordings')), recordings);
    await expectLater(
      owner.read(
        (db) => db.update(
          'practice_sessions',
          {'deleted_at': null},
          where: 'id = ?',
          whereArgs: [sessionId],
        ),
      ),
      throwsA(isA<DatabaseException>()),
    );
  });

  test(
    'invalid IDs, wrong ownership and unfinished sessions cannot be deleted',
    () async {
      await seed();
      final before = await owner.read(
        (db) => db.query('practice_sessions', orderBy: 'id'),
      );
      for (final (profile, session) in [
        (profileId, 'invalid'),
        ('invalid', sessionId),
        (otherProfileId, sessionId),
        (otherProfileId, '00000000-0000-4000-8000-000000000013'),
      ]) {
        await expectLater(
          service.delete(profileId: profile, sessionId: session),
          invalid,
        );
      }
      expect(
        await owner.read((db) => db.query('practice_sessions', orderBy: 'id')),
        before,
      );
    },
  );

  for (final recording in [false, true]) {
    test(
      'storage failure rolls back everything and allows retry (recording: $recording)',
      () async {
        await seed(recording: recording);
        final sessions = await owner.read(
          (db) => db.query('practice_sessions', orderBy: 'id'),
        );
        final recordings = await owner.read((db) => db.query('recordings'));
        await owner.read(
          (db) => db.execute(
            'CREATE TRIGGER injected_delete BEFORE ${recording ? 'UPDATE OF deleted_at' : 'DELETE'} ON practice_sessions BEGIN SELECT RAISE(ABORT, \'injected\'); END',
          ),
        );
        await expectLater(
          service.delete(profileId: profileId, sessionId: sessionId),
          throwsA(
            isA<JournalFailure>().having(
              (e) => e.code,
              'code',
              JournalFailureCode.storage,
            ),
          ),
        );
        expect(
          await owner.read(
            (db) => db.query('practice_sessions', orderBy: 'id'),
          ),
          sessions,
        );
        expect(await owner.read((db) => db.query('recordings')), recordings);
        expect(
          await SqliteJournalSessionReader(owner).saved(profileId: profileId),
          hasLength(1),
        );
        await owner.read((db) => db.execute('DROP TRIGGER injected_delete'));
        await service.delete(profileId: profileId, sessionId: sessionId);
        expect(
          await SqliteJournalSessionReader(owner).saved(profileId: profileId),
          isEmpty,
        );
      },
    );
  }
}
