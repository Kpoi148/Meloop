import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n.dart';
import '../application/startup_controller.dart';
import '../components/meloop_ui.dart';
import '../practice_sessions/practice_session_summary.dart';
import '../showcase/preview_copy.dart';
import 'overview_widgets.dart';
import 'practice_overview_provider.dart';

/// The default seven-day progress view shares Home's data and calculations.
class PracticeProgressPage extends StatelessWidget {
  const PracticeProgressPage({
    super.key,
    required this.profile,
    required this.overview,
    required this.onRetry,
    required this.onHistory,
    required this.onInstrument,
  });
  final PreviewInstrumentProfile profile;
  final AsyncValue<PracticeOverview> overview;
  final VoidCallback onRetry, onHistory, onInstrument;
  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final largeText = MediaQuery.textScalerOf(context).scale(16) > 24;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: TempoSpace.page,
      children: [
        MeloopTopBar(
          title: strings.navProgress,
          trailing: largeText
              ? null
              : SelectedInstrumentChip(
                  profile: profile,
                  onPressed: onInstrument,
                ),
        ),
        if (largeText)
          Align(
            alignment: Alignment.centerLeft,
            child: SelectedInstrumentChip(
              profile: profile,
              onPressed: onInstrument,
            ),
          ),
        Text(strings.progressHeading, style: TempoType.heading),
        Text(profileDisplayName(strings, profile), style: TempoType.label),
        overview.when(
          skipLoadingOnRefresh: false,
          data: (data) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: TempoSpace.page,
            children: [
              PracticeStatisticsCard(summary: data.summary),
              WeeklyGoalStrip(summary: data.summary, goal: data.goal),
              Text(strings.qualifyingPracticeDayHint, style: TempoType.caption),
              if (data.summary.latest == null)
                MeloopStateView(
                  state: MeloopViewState.empty,
                  title: strings.noProgressTitle,
                  message: strings.noProgressMessage,
                ),
              Text(strings.practiceRatingsHeading, style: TempoType.section),
              Text(strings.practiceRatingsPeriod, style: TempoType.caption),
              MeloopCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: TempoSpace.md,
                  children: [
                    _RatingSummary(
                      label: strings.mood,
                      summary: data.summary.mood,
                    ),
                    _RatingSummary(
                      label: strings.focusLevel,
                      summary: data.summary.focus,
                    ),
                  ],
                ),
              ),
              Text(strings.practiceRatingsDisclaimer, style: TempoType.caption),
              MeloopButton(
                label: strings.practiceViewHistory,
                style: MeloopButtonStyle.outline,
                onPressed: onHistory,
              ),
            ],
          ),
          error: (_, _) => MeloopStateView(
            state: MeloopViewState.error,
            title: strings.practiceOverviewLoadFailed,
            actionLabel: strings.retry,
            onAction: onRetry,
          ),
          loading: () => MeloopStateView(
            state: MeloopViewState.loading,
            title: strings.practiceOverviewLoading,
          ),
        ),
      ],
    );
  }
}

class _RatingSummary extends StatelessWidget {
  const _RatingSummary({required this.label, required this.summary});
  final String label;
  final PracticeRatingSummary summary;
  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: TempoSpace.md,
      children: [
        Text(label, style: TempoType.label),
        Text(
          summary.average == null
              ? strings.practiceNoRatings
              : strings.practiceRatingAverage(
                  NumberFormat(
                    '0.0',
                    strings.localeName,
                  ).format(summary.average),
                  summary.count,
                ),
        ),
      ],
    );
  }
}
