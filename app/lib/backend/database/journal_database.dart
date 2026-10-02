import 'package:sqflite/sqflite.dart';

import 'migration_runner.dart';
import 'migrations/v001_initial_schema.dart';
import 'migrations/v002_session_bpm.dart';
import 'migrations/v003_profile_practice_drafts.dart';
import 'migrations/v004_saved_session_deletion.dart';

class JournalDatabase {
  JournalDatabase._();

  static const filename = 'meloop.db';
  static const schemaVersion = 4;

  static Future<Database> open({DatabaseFactory? factory, String? path}) async {
    final selectedFactory = factory ?? databaseFactory;
    // A relative filename uses sqflite's app-private Android database directory.
    return selectedFactory.openDatabase(path ?? filename, options: options());
  }

  /// Exposed for migration fault-injection tests and alternate factories.
  static OpenDatabaseOptions options({MigrationRunner? runner}) {
    final migrations =
        runner ??
        MigrationRunner(const [
          initialSchema,
          sessionBpmSchema,
          profilePracticeDraftsSchema,
          savedSessionDeletionSchema,
        ]);
    return OpenDatabaseOptions(
      version: migrations.version,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
        final rows = await database.rawQuery('PRAGMA foreign_keys');
        if (rows.single.values.single != 1) {
          throw StateError('SQLite foreign-key enforcement is unavailable.');
        }
      },
      onCreate: (database, version) =>
          migrations.apply(database, from: 0, to: version),
      onUpgrade: (database, oldVersion, newVersion) =>
          migrations.apply(database, from: oldVersion, to: newVersion),
      onDowngrade: (database, oldVersion, newVersion) async {
        throw UnsupportedSchemaVersion(oldVersion, newVersion);
      },
    );
  }
}
