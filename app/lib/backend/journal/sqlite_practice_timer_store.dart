import 'dart:math' as math;

import 'package:sqflite/sqflite.dart';

import '../../shared/journal/journal_failure.dart';
import '../../shared/journal/journal_models.dart';
import '../../shared/journal/journal_runtime.dart';
import '../../shared/journal/journal_text.dart';
import '../../shared/journal/practice_timer_service.dart';
import '../database/journal_database_owner.dart';
import 'sqlite_journal_readers.dart';

class SqlitePracticeTimerStore implements PracticeTimerStore {
  const SqlitePracticeTimerStore({
    required this.owner,
    this.clock = const DeviceJournalClock(),
  });
  final JournalDatabaseOwner owner;
  final JournalClock clock;
  @override
  Future<PracticeDraft> checkpoint({
    required String sessionId,
    required String profileId,
    required int accumulatedMilliseconds,
    required PracticeState state,
  }) async {
    if (!JournalId.isValid(sessionId) ||
        !JournalId.isValid(profileId) ||
        accumulatedMilliseconds < 0 ||
        accumulatedMilliseconds >
            PracticeRules.maximumDuration.inMilliseconds ||
        state == PracticeState.saved) {
      throw const JournalFailure(JournalFailureCode.invalidInput);
    }
    try {
      return await owner.transaction((db) async {
        final draft = await readUnfinishedDraft(db);
        if (draft == null ||
            draft.session.id != sessionId ||
            draft.session.profileId != profileId ||
            accumulatedMilliseconds < draft.accumulatedMilliseconds) {
          throw const JournalFailure(JournalFailureCode.invalidInput);
        }
        // Wall clock is metadata only. Moving it backward must not violate SQL
        // timestamps or affect the elapsed monotonic duration.
        final now = math.max(
          clock.utcNow().millisecondsSinceEpoch,
          math.max(
            draft.updatedAt.millisecondsSinceEpoch,
            draft.session.updatedAt.millisecondsSinceEpoch,
          ),
        );
        await db.update(
          'session_drafts',
          {
            'accumulated_ms': accumulatedMilliseconds,
            'checkpoint_at': now,
            'updated_at': now,
          },
          where: 'session_id = ?',
          whereArgs: [sessionId],
        );
        await db.update(
          'practice_sessions',
          {'state': state.name, 'updated_at': now},
          where: 'id = ? AND profile_id = ?',
          whereArgs: [sessionId, profileId],
        );
        return (await readUnfinishedDraft(db))!;
      });
    } on DatabaseException {
      throw const JournalFailure(JournalFailureCode.storage);
    }
  }
}
