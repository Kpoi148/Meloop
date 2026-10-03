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
       );

  final PracticeStatistics _statistics;
  List<int> get minutesByDay => _statistics.minutesByDay;
  int get minutes => _statistics.minutes;
  int get count => _statistics.sessionCount;
  int get consecutiveDays => _statistics.consecutiveDays;
}
