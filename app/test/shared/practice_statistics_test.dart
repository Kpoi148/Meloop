import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/shared/journal/journal_models.dart';
import 'package:meloop/shared/journal/practice_date.dart';
import 'package:meloop/shared/journal/practice_statistics.dart';

PracticeStatisticsRecord record(
  String date,
  int seconds, {
  String profile = 'guitar',
  PracticeState state = PracticeState.saved,
}) => PracticeStatisticsRecord(
  profileId: profile,
  date: PracticeDate.parse(date),
  durationSeconds: seconds,
  state: state,
);

PracticeStatistics calculate(
  List<PracticeStatisticsRecord> records, {
  String today = '2026-10-01',
}) => PracticeStatistics.calculate(
  profileId: 'guitar',
  today: PracticeDate.parse(today),
  records: records,
);

void main() {
  test('sum seconds before formatting across dates and sessions', () {
    final stats = calculate([
      record('2026-09-30', 30),
      record('2026-10-01', 30),
      record('2026-10-01', 59),
    ]);
    expect(stats.totalSeconds, 119);
    expect(stats.minutes, 1);
    expect(stats.sessionCount, 3);
    expect(stats.dailySeconds.last, 89);
    expect(stats.minutesByDay.last, 1);
    expect(stats.consecutiveDays, 0);
    expect(stats.qualifyingDaysThisWeek, 0);
  });
  test(
    'one qualifying session counts its day once, excludes draft/owner/future',
    () {
      final stats = calculate([
        record('2026-10-01', 60),
        record('2026-10-01', 120),
        record('2026-09-30', 60, profile: 'flute'),
        record('2026-09-30', 600, state: PracticeState.review),
        record('2026-09-29', 600, state: PracticeState.paused),
        record('2026-09-28', 600, state: PracticeState.running),
        record('2026-10-02', 600),
      ]);
      expect(stats.totalSeconds, 180);
      expect(stats.sessionCount, 2);
      expect(stats.consecutiveDays, 1);
      expect(stats.qualifyingDaysThisWeek, 1);
    },
  );
  test('chart is rolling seven days, goal is Monday through today', () {
    final stats = calculate([
      record('2026-09-24', 600),
      record('2026-09-27', 60),
      record('2026-09-28', 60),
      record('2026-10-01', 60),
      record('2026-10-04', 60),
    ]);
    expect(stats.days.first, DateTime(2026, 9, 25));
    expect(stats.totalSeconds, 180);
    expect(stats.sessionCount, 3);
    expect(stats.qualifyingDaysThisWeek, 2);
    final monday = calculate([record('2026-10-04', 60)], today: '2026-10-05');
    expect(monday.totalSeconds, 60);
    expect(monday.consecutiveDays, 1);
    expect(monday.qualifyingDaysThisWeek, 0);
  });
  test('streak uses full history, and can end yesterday', () {
    final records = [
      for (var day = 20; day <= 30; day++) record('2026-09-$day', 60),
    ];
    final stats = calculate(records);
    expect(stats.consecutiveDays, 11);
    expect(stats.sessionCount, 6);
    expect(stats.qualifyingDaysThisWeek, 3);
    expect(calculate(records, today: '2026-10-02').consecutiveDays, 0);
  });
  test(
    'calendar arithmetic handles year/leap boundaries and empty journal',
    () {
      final leap = calculate([record('2024-02-29', 60)], today: '2024-03-01');
      expect(leap.consecutiveDays, 1);
      expect(leap.days, contains(DateTime(2024, 2, 29)));
      final year = calculate([record('2025-12-31', 60)], today: '2026-01-01');
      expect(year.consecutiveDays, 1);
      final empty = calculate([], today: '2000-01-01');
      expect(empty.totalSeconds, 0);
      expect(empty.sessionCount, 0);
      expect(empty.consecutiveDays, 0);
      expect(empty.qualifyingDaysThisWeek, 0);
      expect(empty.dailySeconds, List.filled(DateTime.daysPerWeek, 0));
    },
  );
}
