import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/backend/database/journal_database.dart';
import 'package:meloop/backend/database/journal_database_owner.dart';
import 'package:meloop/backend/journal/sqlite_journal_bootstrap.dart';
import 'package:meloop/backend/journal/sqlite_instrument_profile_service.dart';
import 'package:meloop/backend/settings/sqlite_app_settings_store.dart';
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
  late SqliteJournalBootstrap bootstrap;
  void reopen() {
    owner = JournalDatabaseOwner(
      open: () => JournalDatabase.open(
        factory: databaseFactoryFfi,
        path: '${temp.path}/journal.db',
      ),
    );
    bootstrap = SqliteJournalBootstrap(
      owner: owner,
      clock: TestClock(),
      initialLanguage: 'vi',
    );
  }

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('meloop-bootstrap-');
    reopen();
  });
  tearDown(() async {
    await owner.close();
    await temp.delete(recursive: true);
  });

  test('empty, lone selection repair and multiple profiles preserve language and last choice on reopen', () async {
    expect((await bootstrap.read()).directory.profiles, isEmpty);
    await SqliteAppSettingsStore(
      owner: owner,
      clock: TestClock(),
    ).writeLanguageCode('en');
    await owner.transaction((db) => insertProfile(db, id(1), 'Guitar'));
    expect((await bootstrap.read()).directory.selectedProfileId, id(1));
    await owner.transaction((db) => insertProfile(db, id(2), 'Piano'));
    await SqliteInstrumentProfileService(
      owner: owner,
      clock: TestClock(),
      initialLanguage: 'vi',
    ).select(id(2));
    await owner.close();
    reopen();
    final result = await bootstrap.read();
    expect(result.directory.profiles, hasLength(2));
    expect(result.directory.selectedProfileId, id(2));
    expect(await SqliteAppSettingsStore(owner: owner).readLanguageCode(), 'en');
  });

  test('missing selected ID is repaired without selecting first of multiple profiles', () async {
    await owner.transaction((db) async {
      await insertProfile(db, id(1), 'Guitar');
      await insertProfile(db, id(2), 'Piano');
    });
    await owner.read((db) async {
      await db.execute('PRAGMA foreign_keys=OFF');
      await db.insert('app_preferences', {
        'id': 1,
        'language': 'en',
        'selected_profile_id': id(99),
        'updated_at': 0,
      });
      await db.execute('PRAGMA foreign_keys=ON');
    });
    expect((await bootstrap.read()).directory.selectedProfileId, isNull);
    expect(
      await owner.read((db) => db.rawQuery('PRAGMA foreign_key_check')),
      isEmpty,
    );
  });

  test('draft keeps owner/state/checkpoint/review and saved counts exclude unfinished', () async {
    await owner.transaction((db) async {
      await insertProfile(db, id(1), 'Guitar');
      await insertProfile(db, id(2), 'Piano');
      await insertSession(db, id: id(10), ownerId: id(1), state: 'running');
      await insertSession(db, id: id(11), ownerId: id(2));
      await db.update(
        'session_drafts',
        {'accumulated_ms': 754000},
        where: 'session_id=?',
        whereArgs: [id(10)],
      );
    });
    final service = SqliteInstrumentProfileService(
      owner: owner,
      clock: TestClock(),
      initialLanguage: 'vi',
    );
    await service.select(id(2));
    final snapshot = await bootstrap.read();
    expect(snapshot.draft!.session.profileId, id(1));
    expect(snapshot.draft!.session.state, PracticeState.running);
    expect(snapshot.draft!.accumulatedMilliseconds, 754000);
    expect(snapshot.directory.selectedProfileId, id(2));
    expect(snapshot.directory.byId(id(1))!.savedSessionCount, 0);
    expect(snapshot.directory.byId(id(2))!.savedSessionCount, 1);
    await owner.close();
    reopen();
    expect((await bootstrap.read()).draft!.accumulatedMilliseconds, 754000);
  });

  test(
    'corrupt review is an error and is not discarded or returned as no draft',
    () async {
      await owner.transaction((db) async {
        await insertProfile(db, id(1), 'Guitar');
        await insertSession(db, id: id(10), ownerId: id(1), state: 'review');
        await db.update(
          'session_drafts',
          {'review_input_json': '{broken'},
          where: 'session_id=?',
          whereArgs: [id(10)],
        );
      });
      await expectLater(
        bootstrap.read(),
        throwsA(
          isA<JournalFailure>().having(
            (e) => e.code,
            'code',
            JournalFailureCode.corruptData,
          ),
        ),
      );
      expect(
        await owner.read((db) => db.query('session_drafts')),
        hasLength(1),
      );
    },
  );

  test('failed selection repair remains an error and can retry', () async {
    await owner.transaction((db) => insertProfile(db, id(1), 'Guitar'));
    await owner.read(
      (db) => db.execute(
        "CREATE TRIGGER injected_preferences BEFORE INSERT ON app_preferences BEGIN SELECT RAISE(ABORT,'injected'); END",
      ),
    );
    await expectLater(
      bootstrap.read(),
      throwsA(
        isA<JournalFailure>().having(
          (e) => e.code,
          'code',
          JournalFailureCode.storage,
        ),
      ),
    );
    await owner.read((db) => db.execute('DROP TRIGGER injected_preferences'));
    expect((await bootstrap.read()).directory.selectedProfileId, id(1));
  });
}
