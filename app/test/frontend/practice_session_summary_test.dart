import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/frontend/practice_sessions/practice_session.dart';
import 'package:meloop/frontend/practice_sessions/practice_session_summary.dart';

PracticeSession session(int day, int seconds) => PracticeSession(
  id: 'day-$day-seconds-$seconds',
  profileId: 'summary-test',
  date: DateTime(2026, 9, day),
  title: 'Summary fixture',
  duration: Duration(seconds: seconds),
);

void main() {
  test('explicit selected profile ignores records from another owner', () {
    final summary = PracticeSessionSummary(
      [
        PracticeSession(
          id: 'guitar',
          profileId: 'summary-test',
          date: DateTime(2026, 9, 30),
          title: 'Guitar',
          duration: const Duration(seconds: 600),
          mood: 5,
          focus: 1,
        ),
        PracticeSession(
          id: 'flute',
          profileId: 'selected-flute',
          date: DateTime(2026, 9, 30),
          title: 'Flute',
          duration: const Duration(seconds: 30),
          mood: 1,
          focus: 5,
        ),
      ],
      DateTime(2026, 9, 30),
      profileId: 'selected-flute',
    );
    expect(summary.count, 1);
    expect(summary.minutes, 0);
    expect(summary.consecutiveDays, 0);
    expect(summary.qualifyingDaysThisWeek, 0);
    expect(summary.latest!.id, 'flute');
    expect(summary.mood.average, 1);
    expect(summary.focus.average, 5);
    expect(summary.mood.count, 1);
  });
  final today = DateTime(2026, 9, 30);
  test(
    'calendar week, seven-day chart and streak have independent boundaries',
    () {
      final monday = DateTime(2026, 10, 5);
      final summary = PracticeSessionSummary([
        session(30, 60),
        session(31, 60),
        session(32, 60),
        session(33, 60),
        session(34, 60),
        session(35, 30),
        session(35, 30),
        session(36, 60),
      ], monday);
      expect(summary.days.first, DateTime(2026, 9, 29));
      expect(summary.days.last, monday);
      expect(summary.minutes, 6);
      expect(summary.count, 7);
      expect(summary.consecutiveDays, 5);
      expect(summary.qualifyingDaysThisWeek, 0);
      expect(summary.latest!.date, monday);
    },
  );
  test(
    'empty data and missing ratings have no invented totals or zero scores',
    () {
      final summary = PracticeSessionSummary([], today);
      expect(summary.count, 0);
      expect(summary.minutesByDay, List.filled(7, 0));
      expect(summary.latest, isNull);
      expect(summary.qualifyingDaysThisWeek, 0);
      expect(summary.mood.average, isNull);
      expect(summary.focus.count, 0);
    },
  );
  test(
    'ratings count actual responses and round half-up only after aggregation',
    () {
      expect(PracticeRatingSummary([1, 1, 1, 2]).average, 1.3);
      expect(PracticeRatingSummary([5, 4, 3]).count, 3);
    },
  );
  test('editing 60 seconds to 30 removes its qualifying-day contribution', () {
    expect(PracticeSessionSummary([session(30, 60)], today).consecutiveDays, 1);
    expect(PracticeSessionSummary([session(30, 30)], today).consecutiveDays, 0);
    expect(
      PracticeSessionSummary([
        session(30, 30),
        session(30, 60),
      ], today).consecutiveDays,
      1,
    );
    expect(
      PracticeSessionSummary([
        session(30, 30),
        session(30, 30),
      ], today).consecutiveDays,
      0,
    );
  });
  test(
    'seconds are summed before display rounding and streak may end yesterday',
    () {
      final summary = PracticeSessionSummary([
        session(29, 90),
        session(28, 30),
      ], today);
      expect(summary.minutes, 2);
      expect(summary.consecutiveDays, 1);
      expect(
        PracticeSessionSummary([
          session(29, 60),
          session(28, 60),
        ], today).consecutiveDays,
        2,
      );
      expect(
        PracticeSessionSummary([session(28, 60)], today).consecutiveDays,
        0,
      );
    },
  );
}
