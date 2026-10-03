import 'journal_models.dart';
import 'journal_text.dart';
import 'practice_date.dart';

/// Minimal, date-based input shared by the journal reader and UI adapter.
class PracticeStatisticsRecord {
  const PracticeStatisticsRecord({
    required this.profileId,
    required this.date,
    required this.durationSeconds,
    this.state = PracticeState.saved,
  });
  final String profileId;
  final PracticeDate date;
  final int durationSeconds;
  final PracticeState state;
}

/// Home's seven-day totals; streak and goal days use the complete saved history.
/// Calendar construction rather than 24-hour subtraction preserves local dates.
class PracticeStatistics {
  PracticeStatistics.calculate({
    required String profileId,
    required PracticeDate today,
    required Iterable<PracticeStatisticsRecord> records,
  }) {
    final current = DateTime.parse(today.value);
    days = List.unmodifiable(
      List.generate(
        DateTime.daysPerWeek,
        (index) => DateTime(
          current.year,
          current.month,
          current.day - DateTime.daysPerWeek + 1 + index,
        ),
      ),
    );
    final secondsByDate = <String, int>{};
    final countsByDate = <String, int>{};
    final qualifying = <String>{};
    for (final record in records) {
      if (record.profileId != profileId ||
          record.state != PracticeState.saved ||
          record.date.isAfter(today)) {
        continue;
      }
      final date = record.date.value;
      secondsByDate.update(
        date,
        (value) => value + record.durationSeconds,
        ifAbsent: () => record.durationSeconds,
      );
      countsByDate.update(date, (value) => value + 1, ifAbsent: () => 1);
      if (record.durationSeconds >=
          PracticeRules.qualifyingDayDuration.inSeconds) {
        qualifying.add(date);
      }
    }
    dailySeconds = List.unmodifiable([
      for (final day in days) secondsByDate[_dateKey(day)] ?? 0,
    ]);
    totalSeconds = dailySeconds.fold(0, (sum, value) => sum + value);
    sessionCount = days.fold(
      0,
      (sum, day) => sum + (countsByDate[_dateKey(day)] ?? 0),
    );
    final monday = DateTime(
      current.year,
      current.month,
      current.day - current.weekday + DateTime.monday,
    );
    qualifyingDaysThisWeek = qualifying
        .where((date) => date.compareTo(_dateKey(monday)) >= 0)
        .length;
    var streak = 0;
    var day = current;
    if (!qualifying.contains(_dateKey(day))) {
      day = DateTime(day.year, day.month, day.day - 1);
    }
    while (qualifying.contains(_dateKey(day))) {
      streak++;
      day = DateTime(day.year, day.month, day.day - 1);
    }
    consecutiveDays = streak;
  }
  late final List<DateTime> days;
  late final List<int> dailySeconds;
  late final int totalSeconds, sessionCount, qualifyingDaysThisWeek;
  late final int consecutiveDays;

  int get minutes => totalSeconds ~/ Duration.secondsPerMinute;
  List<int> get minutesByDay => List.unmodifiable([
    for (final seconds in dailySeconds) seconds ~/ Duration.secondsPerMinute,
  ]);

  // Chart labels may precede the earliest permitted practice date.
  static String _dateKey(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';
}

abstract interface class PracticeStatisticsReader {
  Future<PracticeStatistics> read(String profileId);
}
