import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../backend/database/journal_database_owner.dart';
import '../backend/database/journal_database.dart';
import '../backend/journal/sqlite_journal_backup_exporter.dart';
import '../backend/journal/stream_journal_backup_validator.dart';
import '../backend/journal/sqlite_journal_backup_restorer.dart';
import '../shared/journal/backup_restore.dart';
import '../shared/journal/backup_validation.dart';
import '../shared/journal/journal_backup.dart';
import '../shared/journal/journal_models.dart';
import '../backend/journal/sqlite_journal_readers.dart';
import '../backend/journal/sqlite_practice_statistics_reader.dart';
import '../shared/journal/practice_statistics.dart';
import '../backend/journal/sqlite_practice_timer_store.dart';
import '../backend/journal/sqlite_practice_review_service.dart';
import '../backend/journal/sqlite_practice_session_delete_service.dart';
import '../backend/journal/sqlite_practice_session_update_service.dart';
import '../shared/journal/practice_session_update_service.dart';
import '../shared/journal/practice_review_service.dart';
import '../shared/journal/practice_session_delete_service.dart';
import '../backend/journal/practice_timer.dart';
import '../backend/journal/practice_screen_awake.dart';
import '../shared/journal/practice_timer_service.dart';
import '../backend/settings/sqlite_app_settings_store.dart';
import '../shared/journal/journal_readers.dart';
import '../shared/journal/journal_runtime.dart';
import '../shared/settings/app_settings_store.dart';

final journalDatabaseOpenerProvider = Provider<JournalDatabaseOpener>(
  (ref) => JournalDatabase.open,
);

/// Lazy and scope-owned. Preview profiles continue using their separate store.
final journalDatabaseOwnerProvider = Provider<JournalDatabaseOwner>((ref) {
  final owner = JournalDatabaseOwner(
    open: ref.watch(journalDatabaseOpenerProvider),
  );
  ref.onDispose(() => unawaited(owner.close()));
  return owner;
});

final journalClockProvider = Provider<JournalClock>(
  (ref) => const DeviceJournalClock(),
);
// The caller supplies the active app language for a pristine database.
final journalBackupExporterProvider =
    Provider.family<JournalBackupExporter, JournalLanguage>(
      (ref, language) => SqliteJournalBackupExporter(
        owner: ref.watch(journalDatabaseOwnerProvider),
        clock: ref.watch(journalClockProvider),
        initialLanguage: language,
      ),
    );
final journalIdentifiersProvider = Provider<JournalIdentifiers>(
  (ref) => const UuidJournalIdentifiers(),
);
final journalBackupValidatorProvider = Provider<JournalBackupValidator>(
  (ref) => StreamJournalBackupValidator(clock: ref.watch(journalClockProvider)),
);
// Device adapters are deferred; a null adapter leaves durable work pending.
final backupRestoreDeviceEffectsProvider =
    Provider<BackupRestoreDeviceEffects?>((ref) => null);
final journalBackupRestorerProvider = Provider<JournalBackupRestorer>(
  (ref) => SqliteJournalBackupRestorer(
    owner: ref.watch(journalDatabaseOwnerProvider),
    clock: ref.watch(journalClockProvider),
    deviceEffects: ref.watch(backupRestoreDeviceEffectsProvider),
  ),
);
final journalReviewServiceProvider = Provider<PracticeReviewService>(
  (ref) => SqlitePracticeReviewService(
    owner: ref.watch(journalDatabaseOwnerProvider),
    clock: ref.watch(journalClockProvider),
  ),
);
final journalSessionUpdateServiceProvider =
    Provider<PracticeSessionUpdateService>(
      (ref) => SqlitePracticeSessionUpdateService(
        owner: ref.watch(journalDatabaseOwnerProvider),
        clock: ref.watch(journalClockProvider),
      ),
    );
final journalSessionDeleteServiceProvider =
    Provider<PracticeSessionDeleteService>(
      (ref) => SqlitePracticeSessionDeleteService(
        owner: ref.watch(journalDatabaseOwnerProvider),
        clock: ref.watch(journalClockProvider),
      ),
    );
final journalMonotonicClockProvider = Provider<MonotonicClock>(
  (ref) => StopwatchMonotonicClock(),
);
final journalScreenAwakeProvider = Provider<PracticeScreenAwake>(
  (ref) => AndroidPracticeScreenAwake(),
);
final journalPracticeTimerProvider = Provider<PracticeTimerService>((ref) {
  final timer = PracticeTimer(
    store: SqlitePracticeTimerStore(
      owner: ref.watch(journalDatabaseOwnerProvider),
      clock: ref.watch(journalClockProvider),
    ),
    clock: ref.watch(journalMonotonicClockProvider),
    screenAwake: ref.watch(journalScreenAwakeProvider),
  );
  ref.onDispose(() => unawaited(timer.close()));
  return timer;
});
final journalProfileReaderProvider = Provider<JournalProfileReader>(
  (ref) => SqliteJournalProfileReader(ref.watch(journalDatabaseOwnerProvider)),
);
final journalSessionReaderProvider = Provider<JournalSessionReader>(
  (ref) => SqliteJournalSessionReader(ref.watch(journalDatabaseOwnerProvider)),
);
final journalStatisticsReaderProvider = Provider<PracticeStatisticsReader>(
  (ref) => SqlitePracticeStatisticsReader(
    owner: ref.watch(journalDatabaseOwnerProvider),
    clock: ref.watch(journalClockProvider),
  ),
);
final journalPreferencesReaderProvider = Provider<JournalPreferencesReader>(
  (ref) =>
      SqliteJournalPreferencesReader(ref.watch(journalDatabaseOwnerProvider)),
);

final journalSettingsStoreProvider = Provider<AppSettingsStore>(
  (ref) => SqliteAppSettingsStore(
    owner: ref.watch(journalDatabaseOwnerProvider),
    clock: ref.watch(journalClockProvider),
  ),
);
