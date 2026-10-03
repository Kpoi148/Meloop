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
        session(30, 600),
        PracticeSession(
          id: 'flute',
          profileId: 'selected-flute',
          date: DateTime(2026, 9, 30),
          title: 'Flute',
          duration: const Duration(seconds: 30),
        ),
      ],
      DateTime(2026, 9, 30),
      profileId: 'selected-flute',
    );
    expect(summary.count, 1);
    expect(summary.minutes, 0);
    expect(summary.consecutiveDays, 0);
  });
  final today = DateTime(2026, 9, 30);
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
