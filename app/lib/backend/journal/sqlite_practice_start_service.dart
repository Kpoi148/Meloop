import 'package:sqflite/sqflite.dart';

import '../../shared/journal/journal_failure.dart';
import '../../shared/journal/journal_models.dart';
import '../../shared/journal/journal_runtime.dart';
import '../../shared/journal/journal_text.dart';
import '../../shared/journal/practice_date.dart';
import '../../shared/journal/practice_start_service.dart';
import '../database/journal_database_owner.dart';
import 'sqlite_journal_readers.dart';
import 'pause_other_practice_sessions.dart';

class SqlitePracticeStartService implements PracticeStartService {
  const SqlitePracticeStartService({
    required this.owner,
    this.clock = const DeviceJournalClock(),
  });
  final JournalDatabaseOwner owner;
  final JournalClock clock;

  @override
  Future<PracticeDraft> start({
    required String requestId,
    required String profileId,
    required String title,
  }) async {
    if (!JournalId.isValid(requestId) || !JournalId.isValid(profileId)) {
      throw const JournalFailure(JournalFailureCode.invalidInput);
    }
    final normalized = JournalText.sessionTitle(title);
    try {
      return await owner.transaction((db) async {
        final existing = await readUnfinishedDraft(db, profileId: profileId);
        if (existing != null) return existing;
        final profiles = await db.query(
          'instrument_profiles',
          columns: ['id'],
          where: 'id = ?',
          whereArgs: [profileId],
        );
        final collision = await db.query(
          'practice_sessions',
          columns: ['id'],
          where: 'id = ?',
          whereArgs: [requestId],
        );
        if (profiles.isEmpty || collision.isNotEmpty) {
          throw const JournalFailure(JournalFailureCode.invalidInput);
        }
        final local = clock.localNow();
        final now = clock.utcNow().millisecondsSinceEpoch;
        await pauseOtherPracticeSessions(db, sessionId: requestId, now: now);
        await db.insert('practice_sessions', {
          'id': requestId,
          'profile_id': profileId,
          'state': PracticeState.running.name,
          'title': normalized,
          'title_search': JournalText.searchKey(normalized),
          'practice_date': PracticeDate.fromLocal(local).value,
          'start_offset_minutes': local.timeZoneOffset.inMinutes,
          'created_at': now,
          'updated_at': now,
        });
        // Schema v1 creates the sidecar in this same transaction. Read it before
        // returning so malformed/incomplete data never produces success.
        return (await readUnfinishedDraft(
          db,
          profileId: profileId,
          sessionId: requestId,
        ))!;
      });
    } on DatabaseException {
      throw const JournalFailure(JournalFailureCode.storage);
    }
  }
}
