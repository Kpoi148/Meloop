import 'package:sqflite/sqflite.dart';

/// A cold process may leave a Running row at its last checkpoint. Only the
/// foreground timer can run; other profiles retain exactly their stored time.
Future<void> pauseOtherPracticeSessions(
  DatabaseExecutor db, {
  required String sessionId,
  required int now,
}) async {
  await db.rawUpdate(
    '''
UPDATE practice_sessions SET state = 'paused', updated_at = MAX(updated_at, ?)
WHERE state = 'running' AND id <> ?
''',
    [now, sessionId],
  );
}
