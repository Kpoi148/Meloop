import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

enum ProgressFilterPreset {
  sevenDays,
  thirtyDays,
  thisMonth,
  custom;

  static const extendedPeriodDays = 30;
  String label(AppLocalizations strings) => switch (this) {
    sevenDays => strings.progressDays(DateTime.daysPerWeek),
    thirtyDays => strings.progressDays(extendedPeriodDays),
    thisMonth => strings.progressFilterThisMonth,
    custom => strings.progressFilterCustom,
  };

  DateTimeRange? range(DateTime today, DateTime earliest) {
    final end = DateUtils.dateOnly(today);
    final start = switch (this) {
      sevenDays => DateTime(
        end.year,
        end.month,
        end.day - DateTime.daysPerWeek + 1,
      ),
      thirtyDays => DateTime(
        end.year,
        end.month,
        end.day - extendedPeriodDays + 1,
      ),
      thisMonth => DateTime(end.year, end.month),
      custom => null,
    };
    return start == null
        ? null
        : DateTimeRange(
            start: start.isBefore(earliest) ? earliest : start,
            end: end,
          );
  }

  static ProgressFilterPreset matching(
    DateTimeRange range,
    DateTime today,
    DateTime earliest,
  ) => values.firstWhere(
    (preset) => preset.range(today, earliest) == range,
    orElse: () => custom,
  );
}

int progressRangeDayCount(DateTimeRange range) =>
    DateTime.utc(range.end.year, range.end.month, range.end.day)
        .difference(
          DateTime.utc(range.start.year, range.start.month, range.start.day),
        )
        .inDays +
    1;
