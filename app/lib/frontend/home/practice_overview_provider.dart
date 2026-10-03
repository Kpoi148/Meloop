import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/journal/weekly_practice_goal.dart';
import '../application/startup_controller.dart';
import '../practice_sessions/practice_session.dart';
import '../practice_sessions/practice_session_summary.dart';

typedef WeeklyPracticeGoalLoader = Future<WeeklyPracticeGoal?> Function(
  String profileId,
);
final weeklyPracticeGoalLoaderProvider = Provider<WeeklyPracticeGoalLoader>(
  (ref) =>
      (_) async => null,
);
final weeklyPracticeGoalProvider = FutureProvider.autoDispose
    .family<WeeklyPracticeGoal?, String>(
      (ref, profileId) =>
          ref.watch(weeklyPracticeGoalLoaderProvider)(profileId),
    );

/// Refreshes calendar totals at midnight without changing stored practice dates.
final practiceCalendarDayProvider = Provider.autoDispose<DateTime>((ref) {
  final now = ref.watch(practiceSessionsClockProvider)();
  final tomorrow = DateTime(now.year, now.month, now.day + 1);
  final timer = Timer(tomorrow.difference(now), ref.invalidateSelf);
  ref.onDispose(timer.cancel);
  return DateUtils.dateOnly(now);
});

class PracticeOverview {
  const PracticeOverview({required this.summary, required this.goal});
  final PracticeSessionSummary summary;
  final WeeklyPracticeGoal? goal;
}

/// Home and Progress consume the same unfiltered, profile-scoped saved records.
final practiceOverviewProvider = Provider.autoDispose
    .family<AsyncValue<PracticeOverview>, PreviewInstrumentProfile>((
      ref,
      profile,
    ) {
      final sessions = ref.watch(practiceSessionsProvider(profile));
      final goal = ref.watch(weeklyPracticeGoalProvider(profile.id));
      final today = ref.watch(practiceCalendarDayProvider);
      // Never present a failed read as a successful empty journal or retain stale totals.
      if (sessions.hasError) {
        return AsyncError(sessions.error!, sessions.stackTrace!);
      }
      if (goal.hasError) return AsyncError(goal.error!, goal.stackTrace!);
      if (sessions.isLoading || goal.isLoading) return const AsyncLoading();
      return AsyncData(
        PracticeOverview(
          summary: PracticeSessionSummary(
            sessions.requireValue
                .where((session) => session.profileId == profile.id)
                .toList(),
            today,
            profileId: profile.id,
          ),
          goal: goal.requireValue,
        ),
      );
    });
