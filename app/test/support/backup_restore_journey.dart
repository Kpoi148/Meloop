import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/backend/database/journal_database_owner.dart';
import 'package:meloop/backend/journal/backup_staging_database.dart';
import 'package:meloop/backend/journal/sqlite_instrument_profile_service.dart';
import 'package:meloop/backend/journal/sqlite_journal_backup_exporter.dart';
import 'package:meloop/backend/journal/sqlite_journal_backup_restorer.dart';
import 'package:meloop/backend/journal/sqlite_journal_readers.dart';
import 'package:meloop/backend/journal/sqlite_practice_statistics_reader.dart';
import 'package:meloop/backend/journal/stream_journal_backup_validator.dart';
import 'package:meloop/shared/journal/backup_restore.dart';
import 'package:meloop/shared/journal/backup_validation.dart';
import 'package:meloop/shared/journal/journal_models.dart';
import 'package:meloop/shared/profiles/instrument_profile_service.dart';

import 'backup_export_journey.dart' show BackupTestClock;

const restoreOldProfile = '00000000-0000-4000-8000-000000000090';
const restoreOldSession = '00000000-0000-4000-8000-000000000091';
const restoreDraft = '00000000-0000-4000-8000-000000000092';
const restoreClock = BackupTestClock();

String restoreId(int number) =>
    '00000000-0000-4000-8000-${number.toString().padLeft(12, '0')}';

Map<String, Object?> restoreJson({int profiles = 1}) {
  const stamp = '2026-10-03T00:00:00.000Z';
  return {
    'app': 'Meloop',
    'schemaVersion': 1,
    'exportedAt': stamp,
    'profiles': [
      for (var i = 1; i <= profiles; i++)
        {
          'id': restoreId(i),
          'name': 'Đàn $i',
          'instrumentType': 'other',
          'customType': 'Đàn tranh',
          'createdAt': stamp,
          'updatedAt': stamp,
        },
    ],
    'sessions': [
      if (profiles > 0)
        {
          'id': restoreId(11),
          'profileId': restoreId(1),
          'title': 'Luyện 🎵',
          'practiceDate': '2026-10-03',
          'durationSeconds': 90,
          'measuredDurationSeconds': 60,
          'startOffsetMinutes': 420,
          'practiced': '  Đổi dây\nGiữ nhịp  ',
          'difficulty': 'Nốt cao',
          'next': 'Luyện chậm',
          'mood': 4,
          'focus': null,
          'createdAt': stamp,
          'updatedAt': stamp,
        },
    ],
    'goals': [
      if (profiles > 0)
        {'profileId': restoreId(1), 'enabled': true, 'targetDays': 6},
    ],
    'settings': {
      'language': 'en',
      'reminder': {
        'enabled': true,
        'weekdays': [1, 7],
        'localTime': '08:15',
      },
      'metronome': {'bpm': 120, 'beatsPerBar': 3},
    },
  };
}

Future<BackupPreview> restorePreview({int profiles = 1}) =>
    const StreamJournalBackupValidator(clock: restoreClock).validate(
      Stream.value(utf8.encode(jsonEncode(restoreJson(profiles: profiles)))),
    );

Future<Map<String, Object?>> restoreSnapshot(JournalDatabaseOwner owner) =>
    owner.read((db) async {
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name",
      );
      return {
        for (final table in tables)
          table['name'] as String: await db.query(
            table['name'] as String,
            orderBy: 'rowid',
          ),
      };
    });

Future<void> seedRestoreSource(JournalDatabaseOwner owner) =>
    owner.transaction((db) async {
      final now = restoreClock.utcNow().millisecondsSinceEpoch;
      await db.insert('instrument_profiles', {
        'id': restoreOldProfile,
        'name': 'Old guitar',
        'name_key': 'old guitar',
        'instrument_type': 'guitar',
        'created_at': now,
        'updated_at': now,
      });
      await db.insert('practice_sessions', {
        'id': restoreOldSession,
        'profile_id': restoreOldProfile,
        'state': 'review',
        'title': 'Old note',
        'practice_date': '2026-10-03',
        'start_offset_minutes': 0,
        'created_at': now,
        'updated_at': now,
      });
      await db.insert('recordings', {
        'id': restoreId(93),
        'session_id': restoreOldSession,
        'status': 'ready',
        'local_relative_path': 'private/old.m4a',
        'filename': 'old.m4a',
        'duration_ms': 1000,
        'size_bytes': 20,
        'sample_rate_hz': 44100,
        'channel_count': 1,
        'created_at': now,
        'updated_at': now,
      });
      await db.update(
        'practice_sessions',
        {
          'state': 'saved',
          'duration_seconds': 60,
          'measured_duration_seconds': 0,
          'deleted_at': now,
        },
        where: 'id=?',
        whereArgs: [restoreOldSession],
      );
      await db.insert('weekly_goals', {
        'profile_id': restoreOldProfile,
        'enabled': 0,
        'updated_at': now,
      });
      await db.insert('app_preferences', {
        'id': 1,
        'language': 'vi',
        'selected_profile_id': restoreOldProfile,
        'updated_at': now,
      });
      await db.insert('reminder_settings', {
        'id': 1,
        'enabled': 1,
        'weekdays_mask': 2,
        'schedule_revision': 8,
        'applied_revision': 8,
        'last_delivered_local_date': '2026-10-03',
        'updated_at': now,
      });
      await db.insert('metronome_settings', {
        'id': 1,
        'bpm': 80,
        'beats_per_bar': 4,
        'updated_at': now,
      });
      await db.insert('file_cleanup_queue', {
        'storage_namespace': 'audio_temp',
        'relative_path': 'old-pending.tmp',
        'reason': 'orphan_temp',
        'attempt_count': 2,
        'last_error_code': 'io',
        'created_at': now,
      });
    });

Matcher restoreFailure(BackupRestoreFailureCode code) =>
    throwsA(isA<BackupRestoreFailure>().having((e) => e.code, 'code', code));

Future<void> runBackupRestoreJourney(
  JournalDatabaseOwner owner,
  BackupStagingOpener openStage,
) async {
  await seedRestoreSource(owner);
  final preview = await restorePreview();
  final restorer = SqliteJournalBackupRestorer(
    owner: owner,
    clock: restoreClock,
    openStaging: openStage,
  );
  final before = await restoreSnapshot(owner);
  await expectLater(
    restorer.restore(backup: preview, confirmed: false),
    restoreFailure(BackupRestoreFailureCode.confirmationRequired),
  );
  expect(await restoreSnapshot(owner), before);
  await owner.transaction((db) async {
    await db.insert('practice_sessions', {
      'id': restoreDraft,
      'profile_id': restoreOldProfile,
      'state': 'paused',
      'title': 'Draft intact',
      'practice_date': '2026-10-03',
      'start_offset_minutes': 0,
      'created_at': restoreClock.utcNow().millisecondsSinceEpoch,
      'updated_at': restoreClock.utcNow().millisecondsSinceEpoch,
    });
  });
  final withDraft = await restoreSnapshot(owner);
  await expectLater(
    restorer.restore(backup: preview, confirmed: true),
    restoreFailure(BackupRestoreFailureCode.unfinishedSession),
  );
  expect(await restoreSnapshot(owner), withDraft);
  await owner.transaction((db) async {
    await db.delete(
      'practice_sessions',
      where: 'id=?',
      whereArgs: [restoreDraft],
    );
    await db.execute(
      "CREATE TRIGGER reject_restore BEFORE INSERT ON practice_sessions WHEN NEW.id='${restoreId(11)}' BEGIN SELECT RAISE(ABORT, 'test_storage_failure'); END",
    );
  });
  await expectLater(
    restorer.restore(backup: preview, confirmed: true),
    restoreFailure(BackupRestoreFailureCode.storage),
  );
  expect(await restoreSnapshot(owner), before);
  await owner.transaction((db) => db.execute('DROP TRIGGER reject_restore'));
  final result = await restorer.restore(backup: preview, confirmed: true);
  expect(result.profileCount, 1);
  expect(result.sessionCount, 1);
  expect(result.selectedProfileId, restoreId(1));
  expect(result.language, JournalLanguage.en);
  expect(result.cleanupPending, isTrue);
  expect(result.remindersPending, isTrue);
  final after = await restoreSnapshot(owner);
  expect(after['recordings'], isEmpty);
  expect(after['session_drafts'], isEmpty);
  final queue = after['file_cleanup_queue'] as List<Map<String, Object?>>;
  expect(queue.length, 2);
  expect(
    queue.where((row) => row['reason'] == 'restore').single['relative_path'],
    'private/old.m4a',
  );
  expect(
    queue
        .where((row) => row['reason'] == 'orphan_temp')
        .single['attempt_count'],
    2,
  );
  final reminders =
      (after['reminder_settings'] as List<Map<String, Object?>>).single;
  expect(reminders['schedule_revision'], 9);
  expect(reminders['applied_revision'], isNull);
  expect(reminders['last_delivered_local_date'], isNull);
  expect(reminders['weekdays_mask'], 65);
  expect(reminders['local_time_minutes'], 495);
  final saved = (await SqliteJournalSessionReader(
    owner,
  ).saved(profileId: restoreId(1))).single;
  expect(saved.practiced, '  Đổi dây\nGiữ nhịp  ');
  expect(saved.measuredDurationSeconds, 60);
  expect(saved.focus, isNull);
  expect(saved.bpm, isNull);
  final storedSession =
      (after['practice_sessions'] as List<Map<String, Object?>>).single;
  expect(storedSession['title_search'], 'luyen 🎵');
  expect(storedSession['practiced_search'], '  doi day\ngiu nhip  ');
  expect(storedSession['difficulty_search'], 'not cao');
  expect(storedSession['next_search'], 'luyen cham');
  expect(
    (after['instrument_profiles'] as List<Map<String, Object?>>)
        .single['name_key'],
    'đàn 1',
  );
  final overview = await SqlitePracticeStatisticsReader(
    owner: owner,
    clock: restoreClock,
  ).read(restoreId(1));
  expect(overview.qualifyingDaysThisWeek, 1);
  final bytes = await SqliteJournalBackupExporter(
    owner: owner,
    initialLanguage: JournalLanguage.vi,
    clock: restoreClock,
  ).export();
  expect(jsonDecode(utf8.decode(bytes)), {
    ...preview.document.toJson(),
    'exportedAt': restoreClock.utcNow().toIso8601String(),
  });
  // New explicit replacement is deterministic, with no duplicated sessions or queue.
  await restorer.restore(backup: preview, confirmed: true);
  expect((await restoreSnapshot(owner))['file_cleanup_queue'], queue);
  final multi = await restorePreview(profiles: 4);
  final multiple = await restorer.restore(backup: multi, confirmed: true);
  expect(multiple.selectedProfileId, isNull);
  final service = SqliteInstrumentProfileService(
    owner: owner,
    initialLanguage: 'vi',
    clock: restoreClock,
  );
  expect((await service.load()).profiles.length, 4);
  expect((await service.load()).isPro, isFalse);
  await service.rename(profileId: restoreId(4), name: 'Đàn đổi tên');
  expect((await service.load()).byId(restoreId(4))!.name, 'Đàn đổi tên');
  expect(
    (await SqliteJournalBackupExporter(
      owner: owner,
      initialLanguage: JournalLanguage.vi,
      clock: restoreClock,
    ).export()),
    isNotEmpty,
  );
  await expectLater(
    service.create(
      requestId: restoreId(80),
      name: 'New piano',
      instrumentType: InstrumentType.piano,
      customType: '',
    ),
    throwsA(
      isA<ProfileServiceException>().having(
        (e) => e.code,
        'code',
        ProfileServiceError.freeLimit,
      ),
    ),
  );
  await service.delete(restoreId(4));
  expect((await service.load()).canCreate, isFalse);
  await service.delete(restoreId(3));
  expect((await service.load()).canCreate, isTrue);
  await service.create(
    requestId: restoreId(80),
    name: 'New piano',
    instrumentType: InstrumentType.piano,
    customType: '',
  );
  expect((await service.load()).profiles.length, 3);
  final empty = await restorer.restore(
    backup: await restorePreview(profiles: 0),
    confirmed: true,
  );
  expect(empty.profileCount, 0);
  expect(empty.selectedProfileId, isNull);
  expect(
    await SqliteJournalSessionReader(owner).saved(profileId: restoreId(1)),
    isEmpty,
  );
  expect((await service.load()).profiles, isEmpty);
  // Unknown tables model device purchase identity: replacement never touches them.
}
