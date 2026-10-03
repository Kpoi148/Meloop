import '../../shared/journal/practice_date.dart';
import '../../shared/journal/practice_statistics.dart';
import 'practice_session.dart';

/// UI adapter only. The journal and Home use the same calendar/domain rules.
class PracticeSessionSummary {
  PracticeSessionSummary(
    List<PracticeSession> sessions,
    DateTime now, {
    String? profileId,
  }) : _statistics = PracticeStatistics.calculate(
         profileId: profileId ?? sessions.firstOrNull?.profileId ?? '',
         today: PracticeDate.fromLocal(now),
         records: sessions.map(
           (session) => PracticeStatisticsRecord(
             profileId: session.profileId,
             date: PracticeDate.fromLocal(session.date),
             durationSeconds: session.duration.inSeconds,
           ),
         ),
       ) {
    final selectedProfileId =
        profileId ?? sessions.firstOrNull?.profileId ?? '';
    final today = PracticeDate.fromLocal(now);
    final eligible = sessions
        .where(
          (session) =>
              session.profileId == selectedProfileId &&
              !PracticeDate.fromLocal(session.date).isAfter(today),
        )
        .toList();
    PracticeSession? mostRecent;
    for (final session in eligible) {
      // Readers order equal practice dates by creation time; keep the first tie.
      if (mostRecent == null || session.date.isAfter(mostRecent.date)) {
        mostRecent = session;
      }
    }
    latest = mostRecent;
    final recent = eligible.where(
      (session) => !DateTime(
        session.date.year,
        session.date.month,
        session.date.day,
      ).isBefore(days.first),
    );
    mood = PracticeRatingSummary(
      recent.map((session) => session.mood).whereType<int>(),
    );
    focus = PracticeRatingSummary(
      recent.map((session) => session.focus).whereType<int>(),
    );
  }

  final PracticeStatistics _statistics;
  late final PracticeSession? latest;
  late final PracticeRatingSummary mood, focus;
  List<DateTime> get days => _statistics.days;
  int get qualifyingDaysThisWeek => _statistics.qualifyingDaysThisWeek;
  List<int> get minutesByDay => _statistics.minutesByDay;
  int get minutes => _statistics.minutes;
  int get count => _statistics.sessionCount;
  int get consecutiveDays => _statistics.consecutiveDays;
}

class PracticeRatingSummary {
  PracticeRatingSummary(Iterable<int> ratings) {
    final values = ratings.toList();
    count = values.length;
    average = values.isEmpty
        ? null
        : (values.fold(0, (sum, rating) => sum + rating) * 10 / count).round() /
              10;
  }
  late final int count;
  late final double? average;
}
