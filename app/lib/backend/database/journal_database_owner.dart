import 'dart:async';

import 'package:sqflite/sqflite.dart';

import '../../shared/journal/journal_failure.dart';
import 'journal_database.dart';

typedef JournalDatabaseOpener = Future<Database> Function();

/// One owner per app scope. All work and close are serialized, including open.
/// Callbacks must not close/retain the executor or reenter this owner.
class JournalDatabaseOwner {
  JournalDatabaseOwner({JournalDatabaseOpener? open})
    : _open = open ?? JournalDatabase.open;

  final JournalDatabaseOpener _open;
  static final Object _activeOwner = Object();
  Database? _database;
  Future<void> _tail = Future<void>.value();
  Future<void>? _closeFuture;

  Future<T> read<T>(Future<T> Function(DatabaseExecutor executor) action) =>
      _accept(() async => action(await _connection()));

  Future<T> transaction<T>(
    Future<T> Function(DatabaseExecutor executor) action,
  ) => _accept(() async => (await _connection()).transaction(action));

  Future<Database> _connection() async => _database ??= await _open();

  Future<T> _accept<T>(Future<T> Function() action) {
    if (Zone.current[_activeOwner] == this) {
      return Future<T>.error(
        StateError('Journal callbacks cannot reenter their database owner.'),
      );
    }
    if (_closeFuture != null) {
      return Future<T>.error(const JournalFailure(JournalFailureCode.closed));
    }
    final result = _tail.then(
      (_) => runZoned(action, zoneValues: {_activeOwner: this}),
    );
    // Errors remain on result; they must not poison later operations or retries.
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  /// Terminal and idempotent. Waits for accepted operations before closing.
  Future<void> close() {
    if (Zone.current[_activeOwner] == this) {
      return Future<void>.error(
        StateError('Journal callbacks cannot close their database owner.'),
      );
    }
    return _closeFuture ??= _tail.then((_) async {
      final database = _database;
      _database = null;
      if (database != null) await database.close();
    });
  }
}
