import 'package:flutter/material.dart';

import '../../shared/journal/journal_text.dart';

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
    final secondsByDay = [
      for (final day in days)
        sessions
            .where((session) => DateUtils.dateOnly(session.date) == day)
            .fold(0, (total, session) => total + session.duration.inSeconds),
    ];
    minutesByDay = [
      for (final seconds in secondsByDay) seconds ~/ Duration.secondsPerMinute,
    ];
    minutes =
        secondsByDay.fold(0, (total, value) => total + value) ~/
        Duration.secondsPerMinute;
    count = sessions
        .where(
          (session) =>
              !DateUtils.dateOnly(session.date).isBefore(days.first) &&
              !DateUtils.dateOnly(session.date).isAfter(today),
        )
        .length;
    final practicedDays = sessions
        .where(
          (session) =>
              session.duration >= PracticeRules.qualifyingDayDuration &&
              !DateUtils.dateOnly(session.date).isAfter(today),
        )
        .map((session) => DateUtils.dateOnly(session.date))
        .toSet();
    consecutiveDays = 0;
    var day = today;
    if (!practicedDays.contains(day)) {
      day = DateTime(day.year, day.month, day.day - 1);
    }
    while (practicedDays.contains(day)) {
      consecutiveDays++;
      day = DateTime(day.year, day.month, day.day - 1);
    }
  }
  late final List<int> minutesByDay;
  late final int minutes, count;
  late int consecutiveDays;
}
