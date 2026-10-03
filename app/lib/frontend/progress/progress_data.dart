import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/journal/journal_text.dart';
import '../../shared/journal/weekly_practice_goal.dart';
import '../application/startup_controller.dart';
import '../home/practice_overview_provider.dart';
import '../practice_sessions/practice_session.dart';
import '../practice_sessions/practice_session_summary.dart';

typedef ProgressQuery = ({
  PreviewInstrumentProfile profile,
  DateTimeRange? range,
});

/// Presentation only: all charts use the same profile and inclusive date range.
final practiceProgressProvider = Provider.autoDispose
    .family<AsyncValue<ProgressData>, ProgressQuery>((ref, query) {
      final records = ref.watch(practiceSessionsProvider(query.profile));
      final goal = ref.watch(weeklyPracticeGoalProvider(query.profile.id));
      final today = ref.watch(practiceCalendarDayProvider);
      if (records.hasError) {
        return AsyncError(records.error!, records.stackTrace!);
      }
      if (goal.hasError) return AsyncError(goal.error!, goal.stackTrace!);
      if (records.isLoading || goal.isLoading) return const AsyncLoading();
      return AsyncData(
        ProgressData.fromSessions(
          records.requireValue,
          profileId: query.profile.id,
          today: today,
          range: query.range,
          goal: goal.requireValue,
        ),
      );
    });

class ProgressDay {
  const ProgressDay({
    required this.date,
    required this.minutes,
    required this.mood,
    required this.focus,
  });
  final DateTime date;
  final int minutes;
  final double? mood, focus;
}

class ProgressData {
  ProgressData.fromSessions(
    List<PracticeSession> sessions, {
    required String profileId,
    required DateTime today,
    DateTimeRange? range,
    this.goal,
  }) {
    final current = DateUtils.dateOnly(today);
    final start = DateUtils.dateOnly(
      range?.start ??
          DateTime(
            current.year,
            current.month,
            current.day - DateTime.daysPerWeek + 1,
          ),
    );
    final end = DateUtils.dateOnly(range?.end ?? current);
    final eligible = sessions
        .where(
          (s) =>
              s.profileId == profileId &&
              !DateUtils.dateOnly(s.date).isAfter(current),
        )
        .toList();
    final selected = eligible
        .where(
          (s) =>
              !DateUtils.dateOnly(s.date).isBefore(start) &&
              !DateUtils.dateOnly(s.date).isAfter(end),
        )
        .toList();
    final byDate = <DateTime, List<PracticeSession>>{};
    for (final session in selected) {
      byDate
          .putIfAbsent(DateUtils.dateOnly(session.date), () => [])
          .add(session);
    }
    final calendar = <ProgressDay>[];
    for (
      var day = start;
      !day.isAfter(end);
      day = DateTime(day.year, day.month, day.day + 1)
    ) {
      final daily = byDate[day] ?? const <PracticeSession>[];
      calendar.add(
        ProgressDay(
          date: day,
          minutes:
              daily.fold(0, (sum, s) => sum + s.duration.inSeconds) ~/
              Duration.secondsPerMinute,
          mood: _ratings(daily.map((s) => s.mood)).average,
          focus: _ratings(daily.map((s) => s.focus)).average,
        ),
      );
    }
    days = List.unmodifiable(calendar);
    minutes =
        selected.fold(0, (sum, s) => sum + s.duration.inSeconds) ~/
        Duration.secondsPerMinute;
    count = selected.length;
    mood = _ratings(selected.map((s) => s.mood));
    focus = _ratings(selected.map((s) => s.focus));
    final summary = PracticeSessionSummary(
      eligible,
      current,
      profileId: profileId,
    );
    consecutiveDays = summary.consecutiveDays;
    goalDays = summary.qualifyingDaysThisWeek;
  }

  static PracticeRatingSummary _ratings(Iterable<int?> values) =>
      PracticeRatingSummary(
        values.whereType<int>().where(
          (v) =>
              v >= PracticeRules.minimumRating &&
              v <= PracticeRules.maximumRating,
        ),
      );
  late final List<ProgressDay> days;
  late final int minutes, count, consecutiveDays, goalDays;
  late final PracticeRatingSummary mood, focus;
  final WeeklyPracticeGoal? goal;
}
