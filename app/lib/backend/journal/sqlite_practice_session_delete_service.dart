import 'dart:math' as math;

import 'package:sqflite/sqflite.dart';

import '../../shared/journal/journal_failure.dart';
import '../../shared/journal/journal_models.dart';
import '../../shared/journal/journal_runtime.dart';
import '../../shared/journal/practice_session_delete_service.dart';
import '../database/journal_database_owner.dart';

class SqlitePracticeSessionDeleteService
    implements PracticeSessionDeleteService {
  const SqlitePracticeSessionDeleteService({
    required this.owner,
    this.clock = const DeviceJournalClock(),
  });

  final JournalDatabaseOwner owner;
  final JournalClock clock;

  @override
  Future<void> delete({
    required String profileId,
    required String sessionId,
  }) async {
    if (!JournalId.isValid(profileId) || !JournalId.isValid(sessionId)) {
      throw const JournalFailure(JournalFailureCode.invalidInput);
    }
    try {
      await owner.transaction((db) async {
        final rows = await db.query(
          'practice_sessions',
          where: 'id = ?',
          whereArgs: [sessionId],
        );
        if (rows.isEmpty) return;
        final session = rows.single;
        if (session['profile_id'] != profileId ||
            session['state'] != PracticeState.saved.name) {
          throw const JournalFailure(JournalFailureCode.invalidInput);
        }
        if (session['deleted_at'] != null) return;
        final recordings = await db.query(
          'recordings',
          columns: ['id'],
          where: 'session_id = ?',
          whereArgs: [sessionId],
          limit: 1,
        );
        if (recordings.isEmpty) {
          await db.delete(
            'practice_sessions',
            where: 'id = ? AND profile_id = ? AND state = ?',
            whereArgs: [sessionId, profileId, PracticeState.saved.name],
          );
        } else {
          // Keep the FK owner for independent recordings; exclude this journal
          // entry from the saved view. Never cascade audio deletion or cleanup.
          final now = math.max(
            clock.utcNow().millisecondsSinceEpoch,
            session['updated_at'] as int,
          );
          await db.update(
            'practice_sessions',
            {'deleted_at': now, 'updated_at': now},
            where: 'id = ? AND profile_id = ? AND state = ?',
            whereArgs: [sessionId, profileId, PracticeState.saved.name],
          );
        }
      });
    } on DatabaseException {
      throw const JournalFailure(JournalFailureCode.storage);
    }
  }
}
