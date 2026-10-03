import 'package:sqflite/sqflite.dart';

import '../../shared/journal/backup_restore.dart';
import '../../shared/journal/backup_validation.dart';
import '../../shared/journal/journal_backup.dart';
import '../../shared/journal/journal_failure.dart';
import '../../shared/journal/journal_models.dart';
import '../../shared/journal/journal_runtime.dart';
import '../database/journal_database_owner.dart';
import 'backup_staging_database.dart';
import 'stream_journal_backup_validator.dart';

class SqliteJournalBackupRestorer implements JournalBackupRestorer {
  SqliteJournalBackupRestorer({
    required this.owner,
    this.clock = const DeviceJournalClock(),
    BackupStagingOpener? openStaging,
    this.deviceEffects,
  }) : openStaging = openStaging ?? openBackupStagingDatabase;
  final JournalDatabaseOwner owner;
  final JournalClock clock;
  final BackupStagingOpener openStaging;
  final BackupRestoreDeviceEffects? deviceEffects;
  bool _busy = false;

  @override
  Future<BackupRestoreResult> restore({
    required BackupPreview backup,
    required bool confirmed,
  }) async {
    if (!confirmed) {
      throw const BackupRestoreFailure(
        BackupRestoreFailureCode.confirmationRequired,
      );
    }
    if (_busy) throw const BackupRestoreFailure(BackupRestoreFailureCode.busy);
    _busy = true;
    Database? stage;
    try {
      if (backup.document.sessions.any((s) => s.state != PracticeState.saved)) {
        throw const BackupValidationFailure(
          BackupValidationFailureCode.invalidBackup,
        );
      }
      // Recheck date/ranges/caps even when the caller constructed a preview.
      final validated = await StreamJournalBackupValidator(clock: clock)
          .validate(Stream.value(backup.document.encode()));
      final document = validated.document;
      final now = clock.utcNow().millisecondsSinceEpoch;
      stage = await openStaging();
      await populateBackupStagingDatabase(stage, document, now);
      final staged = stage;
      final queued = await owner.transaction((db) async {
        final draft = await db.query(
          'practice_sessions',
          columns: ['id'],
          where: "state <> 'saved'",
          limit: 1,
        );
        if (draft.isNotEmpty) {
          throw const BackupRestoreFailure(
            BackupRestoreFailureCode.unfinishedSession,
          );
        }
        final reminders = await db.query(
          'reminder_settings',
          columns: ['schedule_revision'],
        );
        final revision = reminders.isEmpty
            ? 1
            : (reminders.single['schedule_revision'] as int) + 1;
        // Queue old app-private paths in the SAME transaction. Rollback leaves
        // both recordings and queue unchanged; deletion triggers deduplicate.
        for (final paths in const [
          ('audio', 'local_relative_path'),
          ('audio_temp', 'temp_relative_path'),
        ]) {
          await db.rawInsert(
            '''
INSERT OR IGNORE INTO file_cleanup_queue(storage_namespace,relative_path,reason,created_at)
SELECT ?, ${paths.$2}, 'restore', ? FROM recordings WHERE ${paths.$2} IS NOT NULL
''',
            [paths.$1, now],
          );
        }
        await db.delete('recordings');
        await db.delete('practice_sessions');
        await db.delete('instrument_profiles');
        await db.delete('app_preferences');
        await db.delete('reminder_settings');
        await db.delete('metronome_settings');
        await copyBackupStagingDatabase(staged, db, revision);
        if ((await db.rawQuery('PRAGMA foreign_key_check')).isNotEmpty) {
          throw const FormatException('Invalid replacement database');
        }
        return Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM file_cleanup_queue'),
            )! >
            0;
      });
      // Commit succeeded. Any subsequent failure is pending device work, never
      // a replacement failure inviting the caller to repeat destructive writes.
      var cleanupPending = queued;
      var remindersPending = true;
      if (deviceEffects != null) {
        if (queued) {
          try {
            cleanupPending = !await deviceEffects!.drainCleanupQueue();
          } catch (_) {
            cleanupPending = true;
          }
        }
        try {
          remindersPending = !await deviceEffects!.reconcileReminders();
        } catch (_) {
          remindersPending = true;
        }
      }
      return BackupRestoreResult(
        profileCount: validated.profileCount,
        sessionCount: validated.sessionCount,
        language: document.settings.language,
        selectedProfileId: document.profiles.length == 1
            ? document.profiles.single.id
            : null,
        cleanupPending: cleanupPending,
        remindersPending: remindersPending,
      );
    } on BackupFailure {
      throw const BackupValidationFailure(
        BackupValidationFailureCode.capacityExceeded,
      );
    } on DatabaseException {
      throw const BackupRestoreFailure(BackupRestoreFailureCode.storage);
    } on JournalFailure catch (error) {
      if (error.code == JournalFailureCode.closed) rethrow;
      throw const BackupRestoreFailure(BackupRestoreFailureCode.storage);
    } on FormatException {
      throw const BackupRestoreFailure(BackupRestoreFailureCode.storage);
    } finally {
      try {
        await stage?.close();
      }
      // Closing isolated in-memory staging cannot undo a successful commit.
      catch (_) {
        /* Connection cleanup only; no journal data is logged. */
      }
      _busy = false;
    }
  }
}
