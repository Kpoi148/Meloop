import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/app/journal_providers.dart';
import 'package:meloop/backend/database/journal_database.dart';
import 'package:meloop/shared/journal/journal_models.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  test(
    'app scope supplies one lazy database to settings and all readers',
    () async {
      var opens = 0;
      Database? opened;
      final container = ProviderContainer(
        overrides: [
          journalDatabaseOpenerProvider.overrideWithValue(() async {
            opens++;
            return opened = await JournalDatabase.open(
              factory: databaseFactoryFfi,
              path: inMemoryDatabasePath,
            );
          }),
        ],
      );
      final owner = container.read(journalDatabaseOwnerProvider);
      addTearDown(() async {
        container.dispose();
        await owner.close();
      });
      final settings = container.read(journalSettingsStoreProvider);
      final profiles = container.read(journalProfileReaderProvider);
      final sessions = container.read(journalSessionReaderProvider);
      final prefs = container.read(journalPreferencesReaderProvider);
      expect(opens, 0);
      await settings.writeLanguageCode('en');
      expect(await profiles.list(), isEmpty);
      expect(await sessions.unfinished(), isNull);
      expect((await prefs.read())!.language, JournalLanguage.en);
      expect(opens, 1);
      container.dispose();
      await owner.close();
      expect(opened!.isOpen, false);
    },
  );
}
