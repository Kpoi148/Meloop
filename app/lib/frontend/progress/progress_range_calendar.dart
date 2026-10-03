import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n.dart';
import '../components/meloop_ui.dart';
import 'progress_charts.dart';
import 'progress_filter_tokens.dart';

class ProgressRangeCalendar extends StatelessWidget {
  const ProgressRangeCalendar({
    super.key,
    required this.month,
    required this.range,
    required this.firstDate,
    required this.lastDate,
    required this.onDay,
    required this.onMonth,
  });
  final DateTime month, firstDate, lastDate;
  final DateTimeRange range;
  final ValueChanged<DateTime> onDay;
  final ValueChanged<int> onMonth;

  @override
  Widget build(BuildContext context) {
    final previous = DateTime(month.year, month.month - 1);
    final next = DateTime(month.year, month.month + 1);
    final canPrevious = !previous.isBefore(
      DateTime(firstDate.year, firstDate.month),
    );
    final canNext = !next.isAfter(DateTime(lastDate.year, lastDate.month));
    final firstWeekday = month.weekday - DateTime.monday;
    final dayCount = DateUtils.getDaysInMonth(month.year, month.month);
    final rows =
        (firstWeekday + dayCount + DateTime.daysPerWeek - 1) ~/
        DateTime.daysPerWeek;
    final scaledFont = MediaQuery.textScalerOf(context)
        .scale(ProgressFilterTokens.calendarDay.fontSize!);
    final cellHeight = math.max(
      ProgressFilterTokens.calendarCellHeight,
      scaledFont * ProgressFilterTokens.calendarTextHeightFactor +
          TempoSpace.md,
    );
    final circleSize = math.max(
      ProgressFilterTokens.calendarCircleSize,
      scaledFont * ProgressFilterTokens.calendarTextHeightFactor +
          TempoSpace.sm,
    );
    return Container(
      key: const Key('progress-range-calendar'),
      padding: ProgressFilterTokens.calendarPadding,
      decoration: BoxDecoration(
        color: TempoColors.fieldFill,
        border: Border.all(color: TempoColors.line),
        borderRadius: BorderRadius.circular(TempoRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  DateFormat.yMMMM(context.l10n.localeName).format(month),
                  key: const Key('progress-calendar-month'),
                  style: TempoType.label,
                ),
              ),
              IconButton(
                key: const Key('progress-calendar-previous'),
                tooltip: MaterialLocalizations.of(context).previousMonthTooltip,
                onPressed: canPrevious ? () => onMonth(-1) : null,
                icon: const MeloopIcon(
                  MeloopIcons.back,
                  size: TempoSize.smallIcon,
                ),
              ),
              IconButton(
                key: const Key('progress-calendar-next'),
                tooltip: MaterialLocalizations.of(context).nextMonthTooltip,
                onPressed: canNext ? () => onMonth(1) : null,
                icon: const MeloopIcon(
                  MeloopIcons.arrow,
                  size: TempoSize.smallIcon,
                ),
              ),
            ],
          ),
          const SizedBox(height: TempoSpace.xs),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = math.max(
                constraints.maxWidth,
                DateTime.daysPerWeek *
                    (scaledFont * ProgressFilterTokens.calendarTextWidthFactor +
                        TempoSpace.sm),
              );
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: width,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          for (var i = 0; i < DateTime.daysPerWeek; i++)
                            Expanded(
                              child: ExcludeSemantics(
                                child: Text(
                                  progressWeekday(
                                    context,
                                    DateTime(
                                      lastDate.year,
                                      lastDate.month,
                                      lastDate.day -
                                          lastDate.weekday +
                                          DateTime.monday +
                                          i,
                                    ),
                                  ),
                                  style: ProgressFilterTokens.calendarWeekday,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: TempoSpace.sm),
                      for (var row = 0; row < rows; row++)
                        Row(
                          children: [
                            for (
                              var column = 0;
                              column < DateTime.daysPerWeek;
                              column++
                            )
                              Expanded(
                                child: _day(
                                  context,
                                  row * DateTime.daysPerWeek +
                                      column -
                                      firstWeekday +
                                      1,
                                  dayCount,
                                  cellHeight,
                                  circleSize,
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _day(
    BuildContext context,
    int number,
    int dayCount,
    double height,
    double circle,
  ) {
    if (number < 1 || number > dayCount) return SizedBox(height: height);
    final date = DateTime(month.year, month.month, number);
    final enabled = !date.isBefore(firstDate) && !date.isAfter(lastDate);
    final selected = !date.isBefore(range.start) && !date.isAfter(range.end);
    final start = date == range.start;
    final end = date == range.end;
    final endpoint = start || end;
    return Semantics(
      label: DateFormat.yMMMMEEEEd(context.l10n.localeName).format(date),
      button: true,
      enabled: enabled,
      selected: selected,
      excludeSemantics: true,
      child: InkWell(
        key: ValueKey('progress-calendar-day-${date.toIso8601String()}'),
        onTap: enabled ? () => onDay(date) : null,
        borderRadius: BorderRadius.circular(TempoRadius.field),
        child: SizedBox(
          height: height,
          child: Center(
            child: Container(
              height: circle,
              decoration: BoxDecoration(
                color: selected ? TempoColors.selection : null,
                borderRadius: BorderRadius.horizontal(
                  left: start ? Radius.circular(circle / 2) : Radius.zero,
                  right: end ? Radius.circular(circle / 2) : Radius.zero,
                ),
              ),
              child: Center(
                child: Container(
                  width: circle,
                  height: circle,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: endpoint ? TempoColors.teal : null,
                    border: date == lastDate && !endpoint
                        ? Border.all(color: TempoColors.line)
                        : null,
                  ),
                  child: Text(
                    NumberFormat.decimalPattern(context.l10n.localeName)
                        .format(number),
                    style: ProgressFilterTokens.calendarDay.copyWith(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                      color: endpoint
                          ? TempoColors.white
                          : enabled
                          ? TempoColors.ink
                          : TempoColors.fieldBorder,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
