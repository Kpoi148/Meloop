import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/backend/database/journal_database.dart';
import 'package:meloop/backend/database/journal_database_owner.dart';
import 'package:meloop/backend/journal/sqlite_practice_start_service.dart';
import 'package:meloop/backend/journal/sqlite_journal_readers.dart';
import 'package:meloop/shared/journal/journal_failure.dart';
import 'package:meloop/shared/journal/journal_models.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'journal_foundation_test.dart'
    show insertProfile, insertSession, TestClock;
import 'profile_create_test.dart' show id;

void main() {
  sqfliteFfiInit();
  late Directory temp;
  late JournalDatabaseOwner owner;
  late SqlitePracticeStartService service;
  void reopen() {
    owner = JournalDatabaseOwner(
      open: () => JournalDatabase.open(
        factory: databaseFactoryFfi,
        path: '${temp.path}/journal.db',
      ),
    );
    service = SqlitePracticeStartService(owner: owner, clock: TestClock());
  }

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('meloop-start-');
    reopen();
    await owner.transaction((db) async {
      await insertProfile(db, id(1), 'Guitar');
      await insertProfile(db, id(2), 'Piano');
    });
  });
  tearDown(() async {
    await owner.close();
    await temp.delete(recursive: true);
  });
  Future<PracticeDraft> start({
    int request = 10,
    int profile = 1,
    String title = '  Luye\u0302\u0323n đàn  ',
  }) => service.start(
    requestId: id(request),
    profileId: id(profile),
    title: title,
  );

  test('Start atomically creates running session and zero checkpoint; reopen keeps identity and saved-only history', () async {
    final draft = await start();
    expect(draft.session.id, id(10));
    expect(draft.session.profileId, id(1));
    expect(draft.session.state, PracticeState.running);
    expect(draft.session.title, 'Luyện đàn');
    expect(draft.session.practiceDate.value, '2026-09-30');
    expect(
      draft.session.startOffsetMinutes,
      TestClock().localNow().timeZoneOffset.inMinutes,
    );
    expect(draft.accumulatedMilliseconds, 0);
    expect(draft.checkpointAt, draft.session.createdAt);
    expect(draft.session.durationSeconds, isNull);
    expect(
      await SqliteJournalSessionReader(owner).saved(profileId: id(1)),
      isEmpty,
    );
    await owner.close();
    reopen();
    final restored = await SqliteJournalSessionReader(owner).unfinished();
    expect(restored!.session.id, id(10));
    expect(restored.session.title, 'Luyện đàn');
  });
  test('concurrent Start across owners and repeated request preserve original draft', () async {
    final results = await Future.wait([
      start(),
      start(profile: 2, request: 11),
    ]);
    expect(results.map((d) => d.session.id).toSet(), {id(10)});
    expect(
      (await start(profile: 2, title: 'Changed')).session.profileId,
      id(1),
    );
    expect(
      await owner.read((db) => db.query('practice_sessions')),
      hasLength(1),
    );
    expect(await owner.read((db) => db.query('session_drafts')), hasLength(1));
  });
  for (final state in ['paused', 'review']) {
    test(
      'existing $state draft from another profile is opened without mutation',
      () async {
        await owner.transaction((db) async {
          await insertSession(db, id: id(20), ownerId: id(2), state: state);
          await db.update(
            'session_drafts',
            {'accumulated_ms': 12345},
            where: 'session_id=?',
            whereArgs: [id(20)],
          );
        });
        final existing = await start();
        expect(existing.session.id, id(20));
        expect(existing.session.profileId, id(2));
        expect(existing.session.state.name, state);
        expect(existing.accumulatedMilliseconds, 12345);
      },
    );
  }
  test(
    'sidecar write failure rolls back session; same request retry succeeds',
    () async {
      await owner.read(
        (db) => db.execute(
          "CREATE TRIGGER injected_start BEFORE INSERT ON session_drafts BEGIN SELECT RAISE(ABORT,'injected'); END",
        ),
      );
      await expectLater(
        start(),
        throwsA(
          isA<JournalFailure>().having(
            (e) => e.code,
            'code',
            JournalFailureCode.storage,
          ),
        ),
      );
      expect(await owner.read((db) => db.query('practice_sessions')), isEmpty);
      await owner.read((db) => db.execute('DROP TRIGGER injected_start'));
      expect((await start()).session.id, id(10));
    },
  );
  test('invalid title/identity/missing profile and saved ID collision never create draft', () async {
    for (final title in ['', '   ', '\u200b', 'bad\n', 'x' * 101]) {
      await expectLater(start(title: title), throwsA(isA<JournalFailure>()));
    }
    await expectLater(
      service.start(requestId: 'bad', profileId: id(1), title: 'Valid'),
      throwsA(isA<JournalFailure>()),
    );
    await expectLater(start(profile: 99), throwsA(isA<JournalFailure>()));
    await owner.transaction(
      (db) => insertSession(db, id: id(10), ownerId: id(1)),
    );
    await expectLater(start(), throwsA(isA<JournalFailure>()));
    expect(await SqliteJournalSessionReader(owner).unfinished(), isNull);
    expect(
      await owner.read((db) => db.query('practice_sessions')),
      hasLength(1),
    );
  });
  test('corrupt sidecar is not replaced with a new draft', () async {
    await start();
    await owner.transaction((db) => db.delete('session_drafts'));
    await expectLater(
      start(request: 11),
      throwsA(
        isA<JournalFailure>().having(
          (e) => e.code,
          'code',
          JournalFailureCode.corruptData,
        ),
      ),
    );
    expect(
      await owner.read((db) => db.query('practice_sessions')),
      hasLength(1),
    );
  });
}
