import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n.dart';
import '../../shared/journal/weekly_practice_goal.dart';
import '../application/startup_controller.dart';
import '../components/meloop_ui.dart';
import '../practice_sessions/practice_session_summary.dart';
import '../showcase/preview_copy.dart';
import 'overview_tokens.dart';

class SelectedInstrumentChip extends StatelessWidget {
  const SelectedInstrumentChip({
    super.key,
    required this.profile,
    this.onPressed,
  });
  final PreviewInstrumentProfile profile;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => Semantics(
    label: context.l10n.changeInstrument,
    button: true,
    child: InkWell(
      key: const Key('choose-profile'),
      onTap: onPressed,
      borderRadius: BorderRadius.circular(TempoRadius.pill),
      child: Container(
        constraints: BoxConstraints(
          minHeight: TempoSize.touchTarget,
          maxWidth:
              (MediaQuery.sizeOf(context).width - TempoSpace.page * 2).clamp(
                0,
                TempoSize.contentMaxWidth,
              ) *
              (MediaQuery.textScalerOf(context).scale(16) > 24
                  ? 1
                  : OverviewTokens.chipWidthFraction),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: TempoSpace.sm,
          vertical: TempoSpace.xs,
        ),
        decoration: BoxDecoration(
          color: TempoColors.paper.withValues(alpha: .9),
          border: Border.all(color: TempoColors.line),
          borderRadius: BorderRadius.circular(TempoRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MeloopArt.instrument(
              profile.instrument,
              size: OverviewTokens.chipArtSize,
            ),
            const SizedBox(width: TempoSpace.sm),
            Flexible(
              child: Text(
                profileInstrumentLabel(context.l10n, profile),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: TempoSpace.sm),
            const MeloopIcon(MeloopIcons.down, size: TempoSize.smallIcon),
          ],
        ),
      ),
    ),
  );
}

class PracticeStatisticsCard extends StatelessWidget {
  const PracticeStatisticsCard({
    super.key,
    required this.summary,
    this.onProgress,
  });
  final PracticeSessionSummary summary;
  final VoidCallback? onProgress;
  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final maxMinutes = summary.minutesByDay.fold(
      0,
      (largest, value) => value > largest ? value : largest,
    );
    return MeloopCard(
      color: TempoColors.teal,
      padding: OverviewTokens.cardPadding,
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: TempoColors.white),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(strings.lastSevenDays, style: TempoType.compactTitle),
                if (onProgress != null)
                  TextButton(
                    onPressed: onProgress,
                    style: TextButton.styleFrom(
                      foregroundColor: TempoColors.white,
                    ),
                    child: Text(strings.details, style: TempoType.caption),
                  ),
              ],
            ),
            const SizedBox(height: TempoSpace.sm),
            MeloopResponsiveRow(
              children: [
                OverviewMetric(
                  value: '${summary.minutes}',
                  label: strings.practiceMinutes,
                  metricKey: const Key('overview-minutes'),
                ),
                OverviewMetric(
                  value: '${summary.count}',
                  label: strings.practiceSessions,
                  metricKey: const Key('overview-count'),
                ),
                OverviewMetric(
                  value: '${summary.consecutiveDays}',
                  label: strings.consecutiveDays,
                  metricKey: const Key('overview-streak'),
                ),
              ],
            ),
            const SizedBox(height: TempoSpace.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < summary.days.length; i++)
                  Expanded(
                    child: Semantics(
                      label: strings.practiceChartDay(
                        DateFormat.yMd(strings.localeName)
                            .format(summary.days[i]),
                        summary.minutesByDay[i],
                      ),
                      excludeSemantics: true,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: TempoSpace.xs,
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${summary.minutesByDay[i]}',
                              style: TempoType.caption,
                            ),
                            SizedBox(
                              height: OverviewTokens.chartHeight,
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  key: ValueKey(
                                    'practice-bar-${summary.days[i].toIso8601String()}',
                                  ),
                                  height:
                                      maxMinutes == 0 ||
                                          summary.minutesByDay[i] == 0
                                      ? OverviewTokens.minimumBarHeight
                                      : OverviewTokens.chartHeight *
                                            summary.minutesByDay[i] /
                                            maxMinutes,
                                  decoration: BoxDecoration(
                                    color: i == summary.days.length - 1
                                        ? TempoColors.yellow
                                        : TempoColors.chart,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(
                                        OverviewTokens.chartBarRadius,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: TempoSpace.xs),
                            Text(
                              DateFormat.E(strings.localeName)
                                  .format(summary.days[i]),
                              style: TempoType.caption,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class OverviewMetric extends StatelessWidget {
  const OverviewMetric({
    super.key,
    required this.value,
    required this.label,
    this.metricKey,
  });
  final String value, label;
  final Key? metricKey;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, key: metricKey, style: TempoType.metric),
      Text(
        label,
        style: TempoType.caption.copyWith(height: 1.1),
        textAlign: TextAlign.center,
      ),
    ],
  );
}

class WeeklyGoalStrip extends StatelessWidget {
  const WeeklyGoalStrip({super.key, required this.summary, required this.goal});
  final PracticeSessionSummary summary;
  final WeeklyPracticeGoal? goal;
  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final enabled = goal?.enabled == true;
    return Row(
      children: [
        const MeloopIcon(MeloopIcons.target, size: OverviewTokens.goalArtSize),
        const SizedBox(width: TempoSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: TempoSpace.sm,
                children: [
                  Text(strings.weeklyGoal, style: TempoType.label),
                  Text(
                    enabled
                        ? strings.goalProgress(
                            summary.qualifyingDaysThisWeek,
                            goal!.targetDays,
                          )
                        : strings.weeklyGoalOff,
                    key: const Key('overview-weekly-goal'),
                    style: TempoType.caption,
                  ),
                ],
              ),
              if (enabled) ...[
                const SizedBox(height: TempoSpace.sm),
                LinearProgressIndicator(
                  value: (summary.qualifyingDaysThisWeek / goal!.targetDays)
                      .clamp(0, 1),
                  minHeight: OverviewTokens.goalBarHeight,
                  color: TempoColors.yellow,
                  backgroundColor: TempoColors.line,
                  borderRadius: BorderRadius.circular(TempoRadius.chip),
                ),
              ],
              const SizedBox(height: TempoSpace.xs),
              Text(strings.mondayToSunday, style: TempoType.caption),
              Text(
                strings.qualifyingDaysThisWeek(summary.qualifyingDaysThisWeek),
                style: TempoType.caption,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
