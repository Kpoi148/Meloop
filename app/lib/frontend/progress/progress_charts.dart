import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n.dart';
import '../components/meloop_ui.dart';
import '../practice_sessions/practice_session_summary.dart';
import 'progress_data.dart';
import 'progress_tokens.dart';
import 'progress_widgets.dart';

String progressWeekday(BuildContext context, DateTime date) =>
    context.l10n.localeName == 'vi'
    ? date.weekday == DateTime.sunday
          ? context.l10n.progressSunday
          : context.l10n.progressWeekday(date.weekday + 1)
    : DateFormat.E(context.l10n.localeName).format(date);

String progressRatingNumber(BuildContext context, double? value) =>
    value == null
    ? context.l10n.progressMissingValue
    : NumberFormat('0.0', context.l10n.localeName).format(value);

class ProgressMinutesChart extends StatelessWidget {
  const ProgressMinutesChart({super.key, required this.days});
  final List<ProgressDay> days;
  @override
  Widget build(BuildContext context) {
    final maxMinutes = days.fold(
      ProgressTokens.minimumMinutesScale,
      (largest, day) => math.max(largest, day.minutes),
    );
    return _CalendarChart(
      count: days.length,
      minimumDayWidth: ProgressTokens.minimumMinutesDayWidth,
      gap: ProgressTokens.minutesBarGap,
      builder: (index) {
        final day = days[index];
        final last = index == days.length - 1;
        return Semantics(
          label: context.l10n.practiceChartDay(
            DateFormat.yMd(context.l10n.localeName).format(day.date),
            day.minutes,
          ),
          excludeSemantics: true,
          child: Column(
            children: [
              SizedBox(
                height:
                    ProgressTokens.barAreaHeight *
                    MediaQuery.textScalerOf(context).scale(12) /
                    12,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('${day.minutes}', style: ProgressTokens.barValue),
                    const SizedBox(height: TempoSpace.xs),
                    Container(
                      key: ValueKey(
                        'progress-minutes-bar-${day.date.toIso8601String()}',
                      ),
                      height: math.max(
                        ProgressTokens.minimumMinutesBarHeight,
                        day.minutes /
                            maxMinutes *
                            ProgressTokens.maximumBarHeight,
                      ),
                      decoration: BoxDecoration(
                        color: last ? TempoColors.yellow : TempoColors.chart,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(ProgressTokens.minutesBarRadius),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: TempoSpace.xs),
              Text(
                progressWeekday(context, day.date),
                style: ProgressTokens.dayLabel.copyWith(
                  color: last ? TempoColors.yellow : TempoColors.white,
                  fontWeight: last ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          ),
        );
      },
      baseline: true,
    );
  }
}

class ProgressRatingCard extends StatelessWidget {
  const ProgressRatingCard({
    super.key,
    required this.days,
    required this.summary,
    required this.mood,
  });
  final List<ProgressDay> days;
  final PracticeRatingSummary summary;
  final bool mood;
  @override
  Widget build(BuildContext context) {
    final label = mood ? context.l10n.mood : context.l10n.progressFocus;
    final compact =
        MediaQuery.sizeOf(context).width < ProgressTokens.compactPageWidth;
    final largeText =
        MediaQuery.textScalerOf(context).scale(16) / 16 >
        ProgressTokens.largeTextThreshold;
    final summaryWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ProgressRoundIcon(
              icon: MeloopIcons.target,
              mood: mood,
              sage: !mood,
              small: true,
            ),
            const SizedBox(width: TempoSpace.sm),
            Expanded(child: Text(label, style: ProgressTokens.ratingLabel)),
          ],
        ),
        const SizedBox(height: ProgressTokens.fineGap),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: progressRatingNumber(context, summary.average)),
              TextSpan(
                text: context.l10n.progressRatingDenominator,
                style: ProgressTokens.ratingDenominator,
              ),
            ],
          ),
          style: ProgressTokens.ratingNumber,
          semanticsLabel: summary.average == null
              ? context.l10n.practiceNoRatings
              : context.l10n.practiceRatingAverage(
                  progressRatingNumber(context, summary.average),
                  summary.count,
                ),
        ),
        const SizedBox(height: TempoSpace.xs),
        Text(
          summary.average == null
              ? context.l10n.practiceNoRatings
              : context.l10n.progressRatingCaption(summary.count),
          style: ProgressTokens.ratingCaption,
        ),
      ],
    );
    final chart = Padding(
      padding: const EdgeInsets.only(top: ProgressTokens.fineGap),
      child: _CalendarChart(
        count: days.length,
        minimumDayWidth: ProgressTokens.minimumDayWidth,
        gap: compact
            ? ProgressTokens.compactRatingBarGap
            : ProgressTokens.ratingBarGap,
        builder: (index) {
          final day = days[index];
          final value = mood ? day.mood : day.focus;
          final formatted = progressRatingNumber(context, value);
          final date = DateFormat.yMd(context.l10n.localeName).format(day.date);
          return Semantics(
            label: value == null
                ? context.l10n.progressUnratedDay(date, label)
                : context.l10n.progressRatedDay(date, label, formatted),
            excludeSemantics: true,
            child: Column(
              children: [
                SizedBox(
                  height:
                      ProgressTokens.ratingChartHeight *
                      MediaQuery.textScalerOf(context).scale(9) /
                      9,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        formatted,
                        style: ProgressTokens.ratingDay,
                        softWrap: false,
                      ),
                      const SizedBox(height: TempoSpace.xs),
                      if (value != null)
                        Container(
                          key: ValueKey(
                            'progress-${mood ? 'mood' : 'focus'}-bar-${day.date.toIso8601String()}',
                          ),
                          height: value * ProgressTokens.ratingHeightPerPoint,
                          decoration: BoxDecoration(
                            color: index == days.length - 1
                                ? TempoColors.yellow
                                : ProgressTokens.ratingBarFill,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(
                                ProgressTokens.ratingBarRadius,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: TempoSpace.xs),
                      Text(
                        progressWeekday(context, day.date),
                        style: ProgressTokens.ratingDay,
                        softWrap: false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    return Container(
      key: ValueKey('progress-${mood ? 'mood' : 'focus'}-card'),
      padding: compact
          ? ProgressTokens.compactRatingPadding
          : ProgressTokens.ratingPadding,
      decoration: BoxDecoration(
        border: Border.all(color: TempoColors.line),
        borderRadius: BorderRadius.circular(TempoRadius.recent),
      ),
      child: largeText
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: TempoSpace.md,
              children: [summaryWidget, chart],
            )
          : LayoutBuilder(
              builder: (context, constraints) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width:
                        constraints.maxWidth *
                        (compact
                            ? ProgressTokens.compactRatingSummaryFraction
                            : ProgressTokens.ratingSummaryFraction),
                    child: summaryWidget,
                  ),
                  SizedBox(
                    width: compact
                        ? ProgressTokens.compactRatingBarGap
                        : ProgressTokens.ratingColumnGap,
                  ),
                  Expanded(child: chart),
                ],
              ),
            ),
    );
  }
}

/// Longer ranges scroll instead of compressing day labels beyond readability.
class _CalendarChart extends StatelessWidget {
  const _CalendarChart({
    required this.count,
    required this.minimumDayWidth,
    required this.gap,
    required this.builder,
    this.baseline = false,
  });
  final int count;
  final double minimumDayWidth, gap;
  final Widget Function(int) builder;
  final bool baseline;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = MediaQuery.textScalerOf(context).scale(12) / 12;
      final width = math.max(
        constraints.maxWidth,
        count * minimumDayWidth * scale + math.max(0, count - 1) * gap,
      );
      final dayWidth = (width - math.max(0, count - 1) * gap) / count;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: width,
          child: Stack(
            children: [
              if (baseline)
                Positioned(
                  left: 0,
                  right: 0,
                  top: ProgressTokens.barAreaHeight * scale,
                  child: const Divider(
                    height: 1,
                    thickness: 1,
                    color: ProgressTokens.chartBaseline,
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                spacing: gap,
                children: [
                  for (var i = 0; i < count; i++)
                    SizedBox(width: dayWidth, child: builder(i)),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
