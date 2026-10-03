import 'dart:math' as math;

import 'package:sqflite/sqflite.dart';

import '../../shared/journal/journal_failure.dart';
import '../../shared/journal/journal_models.dart';
import '../../shared/journal/journal_runtime.dart';
import '../../shared/journal/practice_review_service.dart';
import '../../shared/journal/practice_session_update_service.dart';
import '../database/journal_database_owner.dart';
import 'journal_row_mapper.dart';
import 'practice_review_validation.dart';

class SqlitePracticeSessionUpdateService
    implements PracticeSessionUpdateService {
  const SqlitePracticeSessionUpdateService({
    required this.owner,
    this.clock = const DeviceJournalClock(),
  });
  final JournalDatabaseOwner owner;
  final JournalClock clock;

  @override
  Future<PracticeSession> update({
    required String profileId,
    required String sessionId,
    required PracticeReviewValues values,
  }) async {
    if (!JournalId.isValid(profileId) || !JournalId.isValid(sessionId)) {
      throw const JournalFailure(JournalFailureCode.invalidInput);
    }
    final fields = validatedReviewFields(values, clock);
    try {
      return await owner.transaction((db) async {
        final rows = await db.query(
          'practice_sessions',
          where:
              'id = ? AND profile_id = ? AND state = ? AND deleted_at IS NULL',
          whereArgs: [sessionId, profileId, PracticeState.saved.name],
        );
        if (rows.isEmpty) {
          throw const JournalFailure(JournalFailureCode.invalidInput);
        }
        final previous = sessionFromRow(rows.single);
        await db.update(
          'practice_sessions',
          {
            ...fields,
            'updated_at': math.max(
              clock.utcNow().millisecondsSinceEpoch,
              previous.updatedAt.millisecondsSinceEpoch,
            ),
          },
          where: 'id = ? AND profile_id = ?',
          whereArgs: [sessionId, profileId],
        );
        return sessionFromRow(
          (await db.query(
            'practice_sessions',
            where: 'id = ?',
            whereArgs: [sessionId],
          )).single,
        );
      });
    } on DatabaseException {
      throw const JournalFailure(JournalFailureCode.storage);
    }
  }
}
