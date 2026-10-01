import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meloop/backend/database/journal_database.dart';
import 'package:meloop/backend/database/journal_database_owner.dart';
import 'package:meloop/backend/journal/sqlite_journal_readers.dart';
import 'package:meloop/backend/settings/sqlite_app_settings_store.dart';
import 'package:meloop/shared/journal/journal_runtime.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Android shared owner rolls back and persists settings on reopen', (
    tester,
  ) async {
    // Unique isolated test file, never the user's meloop.db or preview store.
    final path =
        '${await getDatabasesPath()}/foundation-test-${const UuidJournalIdentifiers().newId()}.db';
    var owner = JournalDatabaseOwner(
      open: () => JournalDatabase.open(path: path),
    );
    try {
      final settings = SqliteAppSettingsStore(owner: owner);
      final profiles = SqliteJournalProfileReader(owner);
      expect(await profiles.list(), isEmpty);
      await settings.writeLanguageCode('en');
      await expectLater(
        owner.transaction((db) async {
          await db.rawUpdate(
            "UPDATE app_preferences SET language = 'vi' WHERE id = 1",
          );
          throw StateError('Injected rollback');
        }),
        throwsStateError,
      );
      expect(await settings.readLanguageCode(), 'en');
      expect(await profiles.list(), isEmpty);
      await owner.close();
      owner = JournalDatabaseOwner(
        open: () => JournalDatabase.open(path: path),
      );
      expect(
        await SqliteAppSettingsStore(owner: owner).readLanguageCode(),
        'en',
      );
      expect(await owner.read((db) => db.getVersion()), 1);
      expect(
        await owner.read((db) => db.rawQuery('PRAGMA foreign_key_check')),
        isEmpty,
      );
    } finally {
      await owner.close();
      await deleteDatabase(path);
    }
  });
}
