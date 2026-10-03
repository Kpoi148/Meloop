import 'package:flutter/material.dart';

import '../../shared/journal/journal_text.dart';

import 'practice_session.dart';

/// Presentation totals for the records currently supplied to the UI.
class PracticeSessionSummary {
  PracticeSessionSummary(List<PracticeSession> sessions, DateTime now) {
    final today = DateUtils.dateOnly(now);
    days = List.unmodifiable(
      List.generate(
        DateTime.daysPerWeek,
        (index) => DateTime(
          today.year,
          today.month,
          today.day - DateTime.daysPerWeek + 1 + index,
        ),
      ),
    );
    final eligible = sessions
        .where((session) => !DateUtils.dateOnly(session.date).isAfter(today))
        .toList();
    latest = null;
    for (final session in eligible) {
      // Readers already order equal dates by creation time; keep the first tie.
      if (latest == null || session.date.isAfter(latest!.date)) {
        latest = session;
      }
    }
    final secondsByDay = [
      for (final day in days)
        sessions
            .where((session) => DateUtils.dateOnly(session.date) == day)
            .fold(0, (total, session) => total + session.duration.inSeconds),
    ];
    minutesByDay = List.unmodifiable([
      for (final seconds in secondsByDay) seconds ~/ Duration.secondsPerMinute,
    ]);
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
    final monday = DateTime(
      today.year,
      today.month,
      today.day - today.weekday + DateTime.monday,
    );
    qualifyingDaysThisWeek = practicedDays
        .where((day) => !day.isBefore(monday))
        .length;
    final recent = eligible
        .where(
          (session) => !DateUtils.dateOnly(session.date).isBefore(days.first),
        )
        .toList();
    mood = PracticeRatingSummary(
      recent.map((session) => session.mood).whereType<int>(),
    );
    focus = PracticeRatingSummary(
      recent.map((session) => session.focus).whereType<int>(),
    );
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
  late final List<DateTime> days;
  late final int qualifyingDaysThisWeek;
  late final PracticeRatingSummary mood, focus;
  late PracticeSession? latest;
  late final int minutes, count;
  late int consecutiveDays;
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
