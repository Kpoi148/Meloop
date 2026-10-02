import 'package:flutter/material.dart';

import 'practice_session.dart';

/// Presentation totals for the records currently supplied to the UI.
class PracticeSessionSummary {
  PracticeSessionSummary(List<PracticeSession> sessions, DateTime now) {
    final today = DateUtils.dateOnly(now);
    final days = List.generate(
      DateTime.daysPerWeek,
      (index) => DateTime(
        today.year,
        today.month,
        today.day - DateTime.daysPerWeek + 1 + index,
      ),
    );
    minutesByDay = [
      for (final day in days)
        sessions
            .where((session) => DateUtils.dateOnly(session.date) == day)
            .fold(0, (total, session) => total + session.duration.inMinutes),
    ];
    minutes = minutesByDay.fold(0, (total, value) => total + value);
    count = sessions
        .where(
          (session) =>
              !DateUtils.dateOnly(session.date).isBefore(days.first) &&
              !DateUtils.dateOnly(session.date).isAfter(today),
        )
        .length;
    final practicedDays = sessions
        .map((session) => DateUtils.dateOnly(session.date))
        .toSet();
    consecutiveDays = 0;
    var day = today;
    while (practicedDays.contains(day)) {
      consecutiveDays++;
      day = DateTime(day.year, day.month, day.day - 1);
    }
  }
  late final List<int> minutesByDay;
  late final int minutes, count;
  late int consecutiveDays;
}
