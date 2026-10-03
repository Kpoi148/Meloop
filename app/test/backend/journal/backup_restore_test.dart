import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/backend/database/journal_database.dart';
import 'package:meloop/backend/database/journal_database_owner.dart';
import 'package:meloop/backend/journal/backup_staging_database.dart';
import 'package:meloop/backend/journal/sqlite_journal_backup_restorer.dart';
import 'package:meloop/backend/journal/stream_journal_backup_validator.dart';
import 'package:meloop/shared/journal/backup_restore.dart';
import 'package:meloop/shared/journal/backup_validation.dart';
import 'package:meloop/shared/journal/journal_backup.dart';
import 'package:meloop/shared/journal/journal_failure.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../support/backup_restore_journey.dart';

Future<Database> openStage() =>
    openBackupStagingDatabase(factory: databaseFactoryFfi);
Future<Database> openLive() => JournalDatabase.open(
  factory: databaseFactoryFfi,
  path: inMemoryDatabasePath,
);

void main() {
  sqfliteFfiInit();
  late JournalDatabaseOwner owner;
  setUp(() {
    owner = JournalDatabaseOwner(open: openLive);
  });
  tearDown(() => owner.close());

  test('SQLite restore: cancel, draft, rollback, retry, audio queue, settings, stats and Free quota', () async {
    await runBackupRestoreJourney(owner, openStage);
  });
  test('private staging connections are independent and released after replacement', () async {
    final a = await openStage(), b = await openStage();
    try {
      expect(identical(a, b), isFalse);
      await a.execute('CREATE TABLE isolation(value INTEGER)');
      expect(
        await b.rawQuery(
          "SELECT name FROM sqlite_master WHERE name='isolation'",
        ),
        isEmpty,
      );
    } finally {
      await a.close();
      await b.close();
    }
    Database? stage;
    final restorer = SqliteJournalBackupRestorer(
      owner: owner,
      clock: restoreClock,
      openStaging: () async => stage = await openStage(),
    );
    await restorer.restore(backup: await restorePreview(), confirmed: true);
    expect(stage!.isOpen, isFalse);
  });
  test('forged preview is revalidated before staging, unsupported input cannot change source', () async {
    await seedRestoreSource(owner);
    final before = await restoreSnapshot(owner);
    final valid = (await restorePreview()).document;
    var opens = 0;
    final restorer = SqliteJournalBackupRestorer(
      owner: owner,
      clock: restoreClock,
      openStaging: () async {
        opens++;
        return openStage();
      },
    );
    final invalid = BackupPreview(
      JournalBackupDocument(
        exportedAt: valid.exportedAt,
        profiles: valid.profiles,
        sessions: valid.sessions,
        goals: [
          BackupGoal(profileId: restoreId(77), enabled: true, targetDays: 4),
        ],
        settings: valid.settings,
      ),
    );
    await expectLater(
      restorer.restore(backup: invalid, confirmed: true),
      throwsA(isA<BackupValidationFailure>()),
    );
    expect(opens, 0);
    expect(await restoreSnapshot(owner), before);
    final wrongVersion = restoreJson()..['schemaVersion'] = 2;
    await expectLater(
      const StreamJournalBackupValidator(clock: restoreClock)
          .validate(Stream.value(utf8.encode(jsonEncode(wrongVersion)))),
      throwsA(isA<BackupValidationFailure>()),
    );
    expect(await restoreSnapshot(owner), before);
  });
  test(
    'staging open and staging write failure preserve source and allow retry',
    () async {
      await seedRestoreSource(owner);
      final before = await restoreSnapshot(owner);
      final preview = await restorePreview();
      var attempts = 0;
      Database? stage;
      final restorer = SqliteJournalBackupRestorer(
        owner: owner,
        clock: restoreClock,
        openStaging: () async {
          attempts++;
          stage = await openStage();
          if (attempts == 1) {
            await stage!.close();
            throw const BackupRestoreFailure(BackupRestoreFailureCode.storage);
          }
          if (attempts == 2) {
            await stage!.execute(
              "CREATE TRIGGER reject_stage BEFORE INSERT ON weekly_goals BEGIN SELECT RAISE(ABORT,'test_stage_failure'); END",
            );
          }
          return stage!;
        },
      );
      for (var i = 0; i < 2; i++) {
        await expectLater(
          restorer.restore(backup: preview, confirmed: true),
          restoreFailure(BackupRestoreFailureCode.storage),
        );
        expect(await restoreSnapshot(owner), before);
        expect(stage!.isOpen, isFalse);
      }
      await restorer.restore(backup: preview, confirmed: true);
    },
  );
  test('busy restore rejected and a draft created during staging is checked at commit', () async {
    await seedRestoreSource(owner);
    final stageReady = Completer<void>(), release = Completer<void>();
    final restorer = SqliteJournalBackupRestorer(
      owner: owner,
      clock: restoreClock,
      openStaging: () async {
        stageReady.complete();
        await release.future;
        return openStage();
      },
    );
    final preview = await restorePreview();
    final pending = restorer.restore(backup: preview, confirmed: true);
    await stageReady.future;
    await expectLater(
      restorer.restore(backup: preview, confirmed: true),
      restoreFailure(BackupRestoreFailureCode.busy),
    );
    await owner.transaction(
      (db) => db.insert('practice_sessions', {
        'id': restoreDraft,
        'profile_id': restoreOldProfile,
        'state': 'review',
        'title': 'Concurrent draft',
        'practice_date': '2026-10-03',
        'start_offset_minutes': 0,
        'created_at': 1,
        'updated_at': 1,
      }),
    );
    final before = await restoreSnapshot(owner);
    final expectation = expectLater(
      pending,
      restoreFailure(BackupRestoreFailureCode.unfinishedSession),
    );
    release.complete();
    await expectation;
    expect(await restoreSnapshot(owner), before);
  });
  test(
    'failure at transaction completion rolls back replacement and cleanup',
    () async {
      await owner.close();
      final fault = CommitFailureOwner();
      owner = fault;
      await seedRestoreSource(owner);
      final before = await restoreSnapshot(owner);
      final restorer = SqliteJournalBackupRestorer(
        owner: owner,
        clock: restoreClock,
        openStaging: openStage,
      );
      fault.fail = true;
      await expectLater(
        restorer.restore(backup: await restorePreview(), confirmed: true),
        restoreFailure(BackupRestoreFailureCode.storage),
      );
      expect(await restoreSnapshot(owner), before);
      fault.fail = false;
      await restorer.restore(backup: await restorePreview(), confirmed: true);
    },
  );
  test('post-commit failures are pending success; effects see committed data and purchase remains', () async {
    await seedRestoreSource(owner);
    await owner.transaction((db) async {
      await db.execute(
        'CREATE TABLE device_purchase(identity TEXT, entitlement TEXT)',
      );
      await db.insert('device_purchase', {
        'identity': 'fake-store-identity',
        'entitlement': 'pro',
      });
    });
    final effects = TestDeviceEffects(owner);
    final restorer = SqliteJournalBackupRestorer(
      owner: owner,
      clock: restoreClock,
      openStaging: openStage,
      deviceEffects: effects,
    );
    final preview = await restorePreview();
    final result = await restorer.restore(backup: preview, confirmed: true);
    expect(effects.calls, ['cleanup', 'reminders']);
    expect(result.cleanupPending, isTrue);
    expect(result.remindersPending, isTrue);
    final snapshot = await restoreSnapshot(owner);
    expect(snapshot['device_purchase'], [
      {'identity': 'fake-store-identity', 'entitlement': 'pro'},
    ]);
    expect((snapshot['instrument_profiles'] as List).length, 1);
    effects.fail = false;
    // Retry DEVICE effects only: a post-commit cleanup error never reimports.
    expect(await effects.drainCleanupQueue(), isTrue);
    expect(await effects.reconcileReminders(), isFalse);
    expect((await restoreSnapshot(owner))['file_cleanup_queue'], isEmpty);
  });
  test(
    'bounded copy handles multiple batches without losing records',
    () async {
      final json = restoreJson();
      final prototype = (json['sessions'] as List).single as Map;
      json['sessions'] = [
        for (var i = 0; i < 600; i++) {...prototype, 'id': restoreId(1000 + i)},
      ];
      final preview = await const StreamJournalBackupValidator(
        clock: restoreClock,
      ).validate(Stream.value(utf8.encode(jsonEncode(json))));
      final restorer = SqliteJournalBackupRestorer(
        owner: owner,
        clock: restoreClock,
        openStaging: openStage,
      );
      final result = await restorer.restore(backup: preview, confirmed: true);
      expect(result.sessionCount, 600);
      expect(
        (await restoreSnapshot(owner))['practice_sessions'],
        hasLength(600),
      );
    },
  );
  test('closed live owner reports closed without touching staging or reopening source', () async {
    await owner.close();
    final restorer = SqliteJournalBackupRestorer(
      owner: owner,
      clock: restoreClock,
      openStaging: openStage,
    );
    await expectLater(
      restorer.restore(backup: await restorePreview(), confirmed: true),
      throwsA(
        isA<JournalFailure>().having(
          (e) => e.code,
          'code',
          JournalFailureCode.closed,
        ),
      ),
    );
  });
}

class CommitFailureOwner extends JournalDatabaseOwner {
  CommitFailureOwner() : super(open: openLive);
  bool fail = false;
  @override
  Future<T> transaction<T>(Future<T> Function(DatabaseExecutor) action) =>
      super.transaction((db) async {
        final result = await action(db);
        if (fail) {
          throw const BackupRestoreFailure(BackupRestoreFailureCode.storage);
        }
        return result;
      });
}

class TestDeviceEffects implements BackupRestoreDeviceEffects {
  TestDeviceEffects(this.owner);
  final JournalDatabaseOwner owner;
  bool fail = true;
  final calls = <String>[];
  Future<void> checkCommitted() async {
    final snapshot = await restoreSnapshot(owner);
    expect((snapshot['recordings'] as List), isEmpty);
    expect(
      ((snapshot['instrument_profiles'] as List).single as Map)['id'],
      restoreId(1),
    );
  }

  @override
  Future<bool> drainCleanupQueue() async {
    calls.add('cleanup');
    await checkCommitted();
    if (fail) throw StateError('test_device_cleanup_error');
    await owner.transaction((db) => db.delete('file_cleanup_queue'));
    return true;
  }

  @override
  Future<bool> reconcileReminders() async {
    calls.add('reminders');
    await checkCommitted();
    if (fail) throw StateError('test_permission_error');
    return false; // Permission denied: keep the reminder revision unapplied.
  }
}
