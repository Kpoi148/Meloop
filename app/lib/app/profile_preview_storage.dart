import 'package:sqflite/sqflite.dart';

import '../frontend/showcase/profile_preview_storage.dart';

/// Keeps UI prototype profiles across Android process restarts.
class SqliteProfilePreviewStorage implements ProfilePreviewStorage {
  SqliteProfilePreviewStorage({DatabaseFactory? factory, String? path})
    : _factory = factory ?? databaseFactory,
      _path = path ?? 'meloop_profile_ui_preview.db';

  final DatabaseFactory _factory;
  final String _path;
  Database? _database;

  Future<Database> _open() async => _database ??= await _factory.openDatabase(
    _path,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (database, version) => database.execute(
        'CREATE TABLE profile_ui_state ('
        'id INTEGER PRIMARY KEY CHECK (id = 1), snapshot TEXT NOT NULL)',
      ),
    ),
  );

  @override
  Future<String?> read() async {
    final rows = await (await _open()).query('profile_ui_state', limit: 1);
    return rows.isEmpty ? null : rows.single['snapshot']! as String;
  }

  @override
  Future<void> write(String snapshot) async {
    await (await _open()).insert('profile_ui_state', {
      'id': 1,
      'snapshot': snapshot,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
