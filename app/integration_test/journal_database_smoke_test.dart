import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meloop/backend/database/journal_database.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Android SQLite opens an empty v1 with foreign keys', (
    tester,
  ) async {
    final db = await JournalDatabase.open(path: inMemoryDatabasePath);
    try {
      expect(await db.getVersion(), 1);
      expect(
        (await db.rawQuery('PRAGMA foreign_keys')).single.values.single,
        1,
      );
      expect(await db.query('instrument_profiles'), isEmpty);
      expect(await db.query('practice_sessions'), isEmpty);
      expect(await db.query('file_cleanup_queue'), isEmpty);
      expect(await db.rawQuery('PRAGMA foreign_key_check'), isEmpty);
    } finally {
      await db.close();
    }
  });
}
