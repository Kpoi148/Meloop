import '../../shared/journal/journal_failure.dart';
import '../../shared/journal/journal_runtime.dart';
import '../../shared/journal/practice_date.dart';
import '../../shared/journal/practice_statistics.dart';
import '../database/journal_database_owner.dart';
import 'sqlite_journal_readers.dart';

/// Reads saved, non-deleted rows only; never mutates source data or caches totals.
class SqlitePracticeStatisticsReader implements PracticeStatisticsReader {
  const SqlitePracticeStatisticsReader({
    required this.owner,
    this.clock = const DeviceJournalClock(),
  });
  final JournalDatabaseOwner owner;
  final JournalClock clock;

  @override
  Future<PracticeStatistics> read(String profileId) async {
    final today = PracticeDate.fromLocal(clock.localNow());
    final sessions = await SqliteJournalSessionReader(owner)
        .saved(profileId: profileId, through: today);
    return PracticeStatistics.calculate(
      profileId: profileId,
      today: today,
      records: sessions.map((session) {
        final seconds = session.durationSeconds;
        if (seconds == null) {
          throw const JournalFailure(JournalFailureCode.corruptData);
        }
        return PracticeStatisticsRecord(
          profileId: session.profileId,
          state: session.state,
          date: session.practiceDate,
          durationSeconds: seconds,
        );
      }),
    );
  }
}
