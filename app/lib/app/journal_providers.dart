import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../backend/database/journal_database_owner.dart';
import '../backend/database/journal_database.dart';
import '../backend/journal/sqlite_journal_readers.dart';
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
final journalIdentifiersProvider = Provider<JournalIdentifiers>(
  (ref) => const UuidJournalIdentifiers(),
);
final journalProfileReaderProvider = Provider<JournalProfileReader>(
  (ref) => SqliteJournalProfileReader(ref.watch(journalDatabaseOwnerProvider)),
);
final journalSessionReaderProvider = Provider<JournalSessionReader>(
  (ref) => SqliteJournalSessionReader(ref.watch(journalDatabaseOwnerProvider)),
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
