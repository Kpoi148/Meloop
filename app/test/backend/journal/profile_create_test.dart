import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/backend/database/journal_database.dart';
import 'package:meloop/backend/database/journal_database_owner.dart';
import 'package:meloop/backend/journal/sqlite_instrument_profile_service.dart';
import 'package:meloop/backend/settings/sqlite_app_settings_store.dart';
import 'package:meloop/shared/profiles/instrument_profile_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'journal_foundation_test.dart' show insertSession;

String id(int number) =>
    '00000000-0000-4000-8000-${number.toString().padLeft(12, '0')}';
Matcher failure(ProfileServiceError code) =>
    throwsA(isA<ProfileServiceException>().having((e) => e.code, 'code', code));

void main() {
  sqfliteFfiInit();
  late Directory temp;
  late JournalDatabaseOwner owner;
  late SqliteInstrumentProfileService service;
  void reopen() {
    owner = JournalDatabaseOwner(
      open: () => JournalDatabase.open(
        factory: databaseFactoryFfi,
        path: '${temp.path}/test.db',
      ),
    );
    service = SqliteInstrumentProfileService(
      owner: owner,
      initialLanguage: 'vi',
    );
  }

  Future<ProfileDirectory> create(
    int number,
    String name, {
    InstrumentType type = InstrumentType.guitar,
    String custom = '',
  }) => service.create(
    requestId: id(number),
    name: name,
    instrumentType: type,
    customType: custom,
  );
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('meloop-profile-');
    reopen();
  });
  tearDown(() async {
    await owner.close();
    await temp.delete(recursive: true);
  });

  test('profile, disabled goal, selection persist; retry after reopen is idempotent', () async {
    await SqliteAppSettingsStore(owner: owner).writeLanguageCode('en');
    final created = await create(
      1,
      '  Đàn 🎸  ',
      type: InstrumentType.other,
      custom: '  Đàn tranh  ',
    );
    expect(created.selectedProfile!.name, 'Đàn 🎸');
    expect(created.selectedProfile!.customType, 'Đàn tranh');
    expect(created.isPro, isFalse);
    final goals = await owner.read((db) => db.query('weekly_goals'));
    expect(goals.single['enabled'], 0);
    expect(goals.single['target_days'], 4);
    await owner.close();
    reopen();
    final retried = await create(
      1,
      'Đàn 🎸',
      type: InstrumentType.other,
      custom: 'Đàn tranh',
    );
    expect(retried.profiles, hasLength(1));
    expect(retried.selectedProfileId, id(1));
    expect(await SqliteAppSettingsStore(owner: owner).readLanguageCode(), 'en');
    await expectLater(
      create(1, 'Changed'),
      failure(ProfileServiceError.invalidInput),
    );
  });

  test('case folding, NFC and whitespace uniqueness retain accents', () async {
    await create(1, '  Straße  Đàn  ');
    await expectLater(
      create(2, 'STRASSE   ĐÀN'),
      failure(ProfileServiceError.duplicateName),
    );
    await create(2, 'STRASSE Dan');
    expect((await service.load()).profiles, hasLength(2));
  });

  test('length is counted after NFC; rejects controls, invisibles and invalid other', () async {
    await create(1, List.filled(50, 'e\u0301').join());
    for (final value in ['', '\u200b', 'x\n', List.filled(51, '🎸').join()]) {
      await expectLater(
        create(2, value),
        failure(ProfileServiceError.invalidInput),
      );
    }
    await expectLater(
      create(2, 'Other', type: InstrumentType.other),
      failure(ProfileServiceError.invalidInput),
    );
    await expectLater(
      create(
        2,
        'Other',
        type: InstrumentType.other,
        custom: List.filled(41, 'x').join(),
      ),
      failure(ProfileServiceError.invalidInput),
    );
    final result = await create(2, 'Predefined', custom: 'discard');
    expect(result.selectedProfile!.customType, isEmpty);
  });

  test('concurrent duplicate requests commit exactly once; Free limit holds on backend', () async {
    await Future.wait([create(1, 'First'), create(1, 'First')]);
    await create(2, 'Second');
    await create(3, 'Third');
    await expectLater(
      create(4, 'Fourth'),
      failure(ProfileServiceError.freeLimit),
    );
    expect((await create(1, 'First')).profiles, hasLength(3));
    expect(await owner.read((db) => db.query('weekly_goals')), hasLength(3));
  });

  test(
    'goal failure rolls back profile and selection; retry preserves request ID',
    () async {
      await create(1, 'Existing');
      await owner.read(
        (db) => db.execute(
          "CREATE TRIGGER injected_goal_failure BEFORE INSERT ON weekly_goals BEGIN SELECT RAISE(ABORT, 'injected'); END",
        ),
      );
      await expectLater(
        create(2, 'Retry'),
        failure(ProfileServiceError.storage),
      );
      final before = await service.load();
      expect(before.profiles, hasLength(1));
      expect(before.selectedProfileId, id(1));
      await owner.read(
        (db) => db.execute('DROP TRIGGER injected_goal_failure'),
      );
      expect((await create(2, 'Retry')).selectedProfileId, id(2));
    },
  );

  test('selection write failure rolls back profile and goal', () async {
    await owner.read(
      (db) => db.execute(
        "CREATE TRIGGER injected_preferences_failure BEFORE INSERT ON app_preferences BEGIN SELECT RAISE(ABORT, 'injected'); END",
      ),
    );
    await expectLater(
      create(1, 'Failed'),
      failure(ProfileServiceError.storage),
    );
    expect((await service.load()).profiles, isEmpty);
    expect(await owner.read((db) => db.query('weekly_goals')), isEmpty);
  });

  test(
    'existing profile controls use journal and never touch preview storage',
    () async {
      await create(1, 'One');
      await create(2, 'Two');
      await service.select(id(1));
      await service.rename(profileId: id(1), name: ' Renamed ');
      await expectLater(
        service.rename(profileId: id(2), name: 'RENAMED'),
        failure(ProfileServiceError.duplicateName),
      );
      final impact = await service.deletionImpact(id(1));
      expect(impact.savedSessionCount, 0);
      expect(impact.recordingCount, 0);
      final result = await service.delete(id(1));
      expect(result.profiles.single.id, id(2));
      expect(result.selectedProfileId, isNull);
      expect(await owner.read((db) => db.query('weekly_goals')), hasLength(1));
    },
  );

  test(
    'profile controls protect unfinished session and saved-only counts',
    () async {
      await create(1, 'Protected');
      await owner.transaction(
        (db) => insertSession(db, id: id(10), ownerId: id(1), state: 'running'),
      );
      expect((await service.load()).profiles.single.savedSessionCount, 0);
      await expectLater(
        service.deletionImpact(id(1)),
        failure(ProfileServiceError.unfinishedSession),
      );
      await expectLater(
        service.delete(id(1)),
        failure(ProfileServiceError.unfinishedSession),
      );
      expect((await service.load()).profiles, hasLength(1));
      expect(
        await owner.read((db) => db.query('practice_sessions')),
        hasLength(1),
      );
    },
  );

  test(
    'storage failure stays an error rather than an empty directory',
    () async {
      await owner.close();
      await expectLater(service.load(), failure(ProfileServiceError.storage));
      await expectLater(
        create(1, 'Retry'),
        failure(ProfileServiceError.storage),
      );
    },
  );
}
