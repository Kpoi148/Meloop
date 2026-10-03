import 'package:flutter/material.dart';

import '../../app/meloop_app.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/journal/weekly_practice_goal.dart';
import '../../shared/settings/app_settings_store.dart';
import '../application/app_settings_controller.dart';
import '../application/startup_controller.dart';
import '../components/meloop_ui.dart';
import '../home/practice_overview_provider.dart';
import '../practice_sessions/practice_session.dart';
import 'meloop_ui_showcase.dart';

/// Isolated, memory-only source for comparing UC-14 with the HTML prototype.
/// The journal entry point continues to read the existing saved sessions.
abstract final class ProgressExamples {
  static const profiles = [
    PreviewInstrumentProfile(
      id: 'progress-guitar',
      instrument: MeloopInstrument.guitar,
    ),
    PreviewInstrumentProfile(
      id: 'progress-piano',
      instrument: MeloopInstrument.piano,
    ),
  ];
  static const targetDays = 5;
  static const guitarDays = [
    (minutes: 20, mood: 4, focus: 4),
    (minutes: 0, mood: 0, focus: 0),
    (minutes: 25, mood: 4, focus: 3),
    (minutes: 0, mood: 0, focus: 0),
    (minutes: 30, mood: 3, focus: 4),
    (minutes: 25, mood: 5, focus: 5),
    (minutes: 35, mood: 5, focus: 4),
  ];
  static const pianoDays = [
    (minutes: 15, mood: 3, focus: 3),
    (minutes: 20, mood: 4, focus: 4),
    (minutes: 0, mood: 0, focus: 0),
    (minutes: 25, mood: 4, focus: 5),
    (minutes: 0, mood: 0, focus: 0),
    (minutes: 30, mood: 5, focus: 4),
    (minutes: 20, mood: 4, focus: 4),
  ];

  static List<PracticeSession> sessions(
    AppLocalizations strings,
    PreviewInstrumentProfile profile,
    DateTime today,
  ) {
    final values = profile.instrument == MeloopInstrument.piano
        ? pianoDays
        : guitarDays;
    return [
      for (var i = 0; i < values.length; i++)
        if (values[i].minutes > 0)
          PracticeSession(
            id: 'progress-${profile.id}-$i',
            profileId: profile.id,
            date: DateTime(
              today.year,
              today.month,
              today.day - values.length + 1 + i,
            ),
            title: strings.sampleSessionTitle,
            duration: Duration(minutes: values[i].minutes),
            mood: values[i].mood,
            focus: values[i].focus,
          ),
    ];
  }
}

MeloopApp createProgressPreviewApp({DateTime Function()? clock}) => MeloopApp(
  overrides: [
    appSettingsStoreProvider.overrideWithValue(InMemoryAppSettingsStore()),
    startupSnapshotProvider.overrideWithValue(
      StartupSnapshot(
        profiles: ProgressExamples.profiles,
        selectedProfileId: ProgressExamples.profiles.first.id,
        hasChosenProfile: true,
      ),
    ),
    meloopShellControllerProvider.overrideWith(_ProgressPreviewShell.new),
    if (clock != null) practiceSessionsClockProvider.overrideWithValue(clock),
    practiceSessionsLoaderProvider.overrideWith((ref) {
      final locale = ref.watch(appLocaleProvider).value ?? const Locale('vi');
      final strings = lookupAppLocalizations(locale);
      final now = ref.watch(practiceSessionsClockProvider);
      return (profile) async =>
          ProgressExamples.sessions(strings, profile, now());
    }),
    weeklyPracticeGoalLoaderProvider.overrideWithValue(
      (_) async => WeeklyPracticeGoal(
        enabled: true,
        targetDays: ProgressExamples.targetDays,
      ),
    ),
  ],
  home: const MeloopUiShowcase(developmentTools: false, isPro: true),
);

class _ProgressPreviewShell extends MeloopShellController {
  @override
  MeloopShellState build() => super.build().copyWith(selectedTab: 2);
}
