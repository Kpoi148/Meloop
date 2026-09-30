import 'package:sqflite/sqflite.dart';

class SchemaMigration {
  const SchemaMigration({required this.version, required this.statements});

  final int version;
  final List<String> statements;
}

class UnsupportedSchemaVersion implements Exception {
  const UnsupportedSchemaVersion(this.found, this.supported);

  final int found;
  final int supported;

  @override
  String toString() =>
      'UnsupportedSchemaVersion(found: $found, supported: $supported)';
}

class MigrationRunner {
  MigrationRunner(List<SchemaMigration> migrations)
    : migrations = List.unmodifiable(migrations) {
    for (var index = 0; index < this.migrations.length; index++) {
      if (this.migrations[index].version != index + 1) {
        throw ArgumentError('Migration versions must be contiguous from 1.');
      }
    }
    if (this.migrations.isEmpty) {
      throw ArgumentError('At least one migration is required.');
    }
  }

  final List<SchemaMigration> migrations;

  int get version => migrations.last.version;

  /// Call only inside an openDatabase migration callback or a transaction.
  /// sqflite rolls back DDL and user_version when the callback throws.
  Future<void> apply(
    DatabaseExecutor executor, {
    required int from,
    required int to,
  }) async {
    if (from < 0 || from > version || to != version || from > to) {
      throw UnsupportedSchemaVersion(from, version);
    }
    for (final migration in migrations) {
      if (migration.version > from && migration.version <= to) {
        for (final statement in migration.statements) {
          await executor.execute(statement);
        }
      }
    }
    final violations = await executor.rawQuery('PRAGMA foreign_key_check');
    if (violations.isNotEmpty) {
      throw StateError('Migration left invalid foreign-key references.');
    }
  }
}
