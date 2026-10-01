import '../../shared/settings/app_settings_store.dart';
import '../../shared/journal/journal_runtime.dart';
import '../database/journal_database_owner.dart';

/// Stores UC-20 alongside the other device-local application preferences.
class SqliteAppSettingsStore implements AppSettingsStore {
  const SqliteAppSettingsStore({
    required this.owner,
    this.clock = const DeviceJournalClock(),
  });
  final JournalDatabaseOwner owner;
  final JournalClock clock;

  @override
  Future<String?> readLanguageCode() async {
    return owner.read((database) async {
      final rows = await database.query(
        'app_preferences',
        columns: const ['language'],
        where: 'id = ?',
        whereArgs: const [1],
        limit: 1,
      );
      return rows.isEmpty ? null : rows.single['language'] as String?;
    });
  }

  @override
  Future<void> writeLanguageCode(String languageCode) async {
    if (languageCode != 'vi' && languageCode != 'en') {
      throw ArgumentError.value(languageCode, 'languageCode');
    }
    await owner.transaction((database) async {
      await database.rawInsert(
        '''
INSERT INTO app_preferences (id, language, selected_profile_id, updated_at)
VALUES (1, ?, NULL, ?)
ON CONFLICT(id) DO UPDATE SET
  language = excluded.language,
  updated_at = excluded.updated_at
''',
        [languageCode, clock.utcNow().millisecondsSinceEpoch],
      );
    });
  }
}
