import '../../shared/settings/app_settings_store.dart';
import '../database/journal_database.dart';

/// Stores UC-20 alongside the other device-local application preferences.
class SqliteAppSettingsStore implements AppSettingsStore {
  const SqliteAppSettingsStore();

  @override
  Future<String?> readLanguageCode() async {
    final database = await JournalDatabase.open();
    try {
      final rows = await database.query(
        'app_preferences',
        columns: const ['language'],
        where: 'id = ?',
        whereArgs: const [1],
        limit: 1,
      );
      return rows.isEmpty ? null : rows.single['language'] as String?;
    } finally {
      await database.close();
    }
  }

  @override
  Future<void> writeLanguageCode(String languageCode) async {
    if (languageCode != 'vi' && languageCode != 'en') {
      throw ArgumentError.value(languageCode, 'languageCode');
    }
    final database = await JournalDatabase.open();
    try {
      await database.rawInsert(
        '''
INSERT INTO app_preferences (id, language, selected_profile_id, updated_at)
VALUES (1, ?, NULL, ?)
ON CONFLICT(id) DO UPDATE SET
  language = excluded.language,
  updated_at = excluded.updated_at
''',
        [languageCode, DateTime.now().millisecondsSinceEpoch],
      );
    } finally {
      await database.close();
    }
  }
}
