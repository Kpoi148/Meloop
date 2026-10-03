import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n.dart';
import '../application/startup_controller.dart';
import '../components/meloop_ui.dart';
import '../home/practice_overview_provider.dart';
import 'progress_charts.dart';
import 'progress_data.dart';
import 'progress_filter_popup.dart';
import 'progress_tokens.dart';
import 'progress_widgets.dart';

class PracticeProgressPage extends ConsumerStatefulWidget {
  const PracticeProgressPage({
    super.key,
    required this.profile,
    required this.onRetry,
    required this.onHistory,
    required this.onInstrument,
    this.isPro = false,
    this.onViewPro,
  });
  final PreviewInstrumentProfile profile;
  final VoidCallback onRetry, onHistory, onInstrument;
  final bool isPro;
  final VoidCallback? onViewPro;
  @override
  ConsumerState<PracticeProgressPage> createState() =>
      _PracticeProgressPageState();
}

class _PracticeProgressPageState extends ConsumerState<PracticeProgressPage> {
  DateTimeRange? _range;

  @override
  void didUpdateWidget(PracticeProgressPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isPro) _range = null;
  }

  Future<void> _filter() async {
    if (!widget.isPro) {
      await showProgressProAccess(context, onViewPro: widget.onViewPro);
      return;
    }
    final today = ref.read(practiceCalendarDayProvider);
    final initial =
        _range ??
        DateTimeRange(
          start: DateTime(
            today.year,
            today.month,
            today.day - DateTime.daysPerWeek + 1,
          ),
          end: today,
        );
    final result = await showProgressFilter(
      context,
      profile: widget.profile,
      today: today,
      initialRange: initial,
    );
    if (result != null && mounted && widget.isPro) {
      setState(() => _range = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final data = ref.watch(
      practiceProgressProvider((profile: widget.profile, range: _range)),
    );
    final largeText =
        MediaQuery.textScalerOf(context).scale(16) / 16 >
        ProgressTokens.largeTextThreshold;
    final period = _range == null
        ? strings.lastSevenDays
        : strings.progressPeriod(
            DateFormat.MMMd(strings.localeName).format(_range!.start),
            DateFormat.yMMMd(strings.localeName).format(_range!.end),
          );
    final chip = ProgressInstrumentChip(
      profile: widget.profile,
      onPressed: widget.onInstrument,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (largeText)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: TempoSpace.sm,
            children: [
              Text(strings.navProgress, style: ProgressTokens.pageTitle),
              chip,
            ],
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  strings.navProgress,
                  style: ProgressTokens.pageTitle,
                ),
              ),
              chip,
            ],
          ),
        const SizedBox(height: TempoSpace.md),
        const _ProgressHeading(),
        data.when(
          skipLoadingOnRefresh: false,
          loading: () => MeloopStateView(
            state: MeloopViewState.loading,
            title: strings.practiceOverviewLoading,
          ),
          error: (_, _) => MeloopStateView(
            state: MeloopViewState.error,
            title: strings.practiceOverviewLoadFailed,
            actionLabel: strings.retry,
            onAction: widget.onRetry,
          ),
          data: (value) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: ProgressTokens.chartPadding,
                decoration: BoxDecoration(
                  color: TempoColors.teal,
                  borderRadius: BorderRadius.circular(TempoRadius.card),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: TempoSpace.sm,
                      children: [
                        Text(period, style: ProgressTokens.chartTitle),
                        _ProgressFilter(onPressed: _filter),
                      ],
                    ),
                    const SizedBox(height: ProgressTokens.metricsTop),
                    _ProgressMetrics(data: value, largeText: largeText),
                    const SizedBox(height: ProgressTokens.metricsBottom),
                    ProgressMinutesChart(days: value.days),
                  ],
                ),
              ),
              if (_range != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => setState(() => _range = null),
                    child: Text(strings.lastSevenDays),
                  ),
                ),
              if (value.count == 0) ...[
                const SizedBox(height: TempoSpace.sm),
                MeloopStateView(
                  state: MeloopViewState.empty,
                  title: strings.noProgressTitle,
                  message: strings.noProgressMessage,
                ),
              ],
              const SizedBox(height: ProgressTokens.detailGap),
              ProgressTogether(data: value),
              const SizedBox(height: TempoSpace.page),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ProgressTokens.fineGap,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      strings.practiceRatingsHeading,
                      style: ProgressTokens.ratingsHeading,
                    ),
                    const SizedBox(height: TempoSpace.xs),
                    Text(
                      strings.progressRatingsPeriod(period),
                      style: ProgressTokens.ratingsPeriod,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: ProgressTokens.detailGap),
              ProgressRatingCard(
                days: value.days,
                summary: value.mood,
                mood: true,
              ),
              const SizedBox(height: TempoSpace.sm),
              ProgressRatingCard(
                days: value.days,
                summary: value.focus,
                mood: false,
              ),
              const SizedBox(height: TempoSpace.sm),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ProgressTokens.fineGap,
                ),
                child: Text(
                  strings.practiceRatingsDisclaimer,
                  style: ProgressTokens.disclaimer,
                ),
              ),
              const SizedBox(height: TempoSpace.lg),
              ProgressLink(
                label: strings.progressAdjustGoal,
                icon: MeloopIcons.target,
              ),
              const SizedBox(height: TempoSpace.sm),
              ProgressLink(
                label: strings.progressHistory,
                icon: MeloopIcons.book,
                sage: true,
                onPressed: widget.onHistory,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProgressHeading extends StatelessWidget {
  const _ProgressHeading();
  @override
  Widget build(BuildContext context) {
    final pageWidth = MediaQuery.sizeOf(context).width;
    final wide = pageWidth >= ProgressTokens.widePageWidth;
    final largeText =
        MediaQuery.textScalerOf(context).scale(16) / 16 >
        ProgressTokens.largeTextThreshold;
    final words = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.progressEyebrow, style: ProgressTokens.eyebrow),
        const SizedBox(height: ProgressTokens.detailGap),
        Text(
          context.l10n.progressHeading,
          style: wide ? ProgressTokens.wideHeading : ProgressTokens.heading,
        ),
      ],
    );
    if (largeText) {
      return Padding(
        padding: const EdgeInsets.only(
          top: TempoSpace.md,
          bottom: TempoSpace.page,
        ),
        child: words,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        double textHeight(String text, TextStyle style) {
          final painter = TextPainter(
            text: TextSpan(text: text, style: style),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
          )..layout(maxWidth: constraints.maxWidth);
          final height = painter.height;
          painter.dispose();
          return height;
        }

        final contentHeight =
            ProgressTokens.headingPadding.top +
            textHeight(context.l10n.progressEyebrow, ProgressTokens.eyebrow) +
            ProgressTokens.detailGap +
            textHeight(
              context.l10n.progressHeading,
              wide ? ProgressTokens.wideHeading : ProgressTokens.heading,
            );
        return SizedBox(
          height: math.max(
            contentHeight,
            wide
                ? ProgressTokens.wideHeadingHeight
                : ProgressTokens.headingHeight,
          ),
          child: OverflowBox(
            minWidth: constraints.maxWidth + TempoSpace.page * 2,
            maxWidth: constraints.maxWidth + TempoSpace.page * 2,
            child: ClipRect(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const Positioned(
                    right: ProgressTokens.artworkRight,
                    top: ProgressTokens.artworkTop,
                    child: MeloopArt.scene(
                      MeloopScene.guitar,
                      size: ProgressTokens.artworkSize,
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          TempoColors.paper,
                          TempoColors.paper.withValues(alpha: .9),
                          TempoColors.paper.withValues(alpha: 0),
                        ],
                        stops: ProgressTokens.headingGradientStops,
                      ),
                    ),
                  ),
                  Padding(padding: ProgressTokens.headingPadding, child: words),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProgressFilter extends StatelessWidget {
  const _ProgressFilter({required this.onPressed});
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: context.l10n.progressDateRange,
    child: InkWell(
      key: const Key('progress-filter'),
      onTap: onPressed,
      borderRadius: BorderRadius.circular(TempoRadius.pill),
      child: Container(
        padding: ProgressTokens.filterPadding,
        decoration: BoxDecoration(
          border: Border.all(color: ProgressTokens.filterBorder),
          borderRadius: BorderRadius.circular(TempoRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: ProgressTokens.filterGap,
          children: [
            const MeloopIcon(
              MeloopIcons.settings,
              size: ProgressTokens.filterIconSize,
              color: TempoColors.white,
            ),
            Text(
              context.l10n.progressFilter,
              style: ProgressTokens.filterLabel,
            ),
            Container(
              padding: ProgressTokens.badgePadding,
              decoration: BoxDecoration(
                color: TempoColors.yellow,
                borderRadius: BorderRadius.circular(TempoRadius.chip),
              ),
              child: Text(
                context.l10n.progressProBadge,
                style: ProgressTokens.badge,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ProgressMetrics extends StatelessWidget {
  const _ProgressMetrics({required this.data, required this.largeText});
  final ProgressData data;
  final bool largeText;
  @override
  Widget build(BuildContext context) {
    Widget metric(String value, String label, Key key) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, key: key, style: ProgressTokens.metric),
        const SizedBox(height: ProgressTokens.metricLabelGap),
        Text(label, style: ProgressTokens.metricLabel),
      ],
    );
    final minutes = metric(
      '${data.minutes}',
      context.l10n.progressMusicMinutes,
      const Key('overview-minutes'),
    );
    final count = metric(
      '${data.count}',
      context.l10n.progressSavedSessions,
      const Key('overview-count'),
    );
    if (largeText) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: TempoSpace.md,
        children: [minutes, count],
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: ProgressTokens.fineGap),
              child: minutes,
            ),
          ),
          const VerticalDivider(
            width: 1,
            thickness: 1,
            color: ProgressTokens.metricDivider,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                left: ProgressTokens.secondMetricInset,
              ),
              child: count,
            ),
          ),
        ],
      ),
    );
  }
}
