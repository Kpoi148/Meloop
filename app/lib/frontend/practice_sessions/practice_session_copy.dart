import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';

String practiceGroupDayLabel(
  AppLocalizations strings,
  DateTime date,
  DateTime now,
) {
  final day = DateUtils.dateOnly(date);
  final today = DateUtils.dateOnly(now);
  if (day == today) return strings.practiceTodayLabel;
  if (day == DateTime(today.year, today.month, today.day - 1)) {
    return strings.practiceYesterdayLabel;
  }
  return DateFormat('dd/MM/yyyy', strings.localeName).format(day);
}

String practiceDayLabel(AppLocalizations strings, DateTime date, DateTime now) {
  final day = DateUtils.dateOnly(date);
  final today = DateUtils.dateOnly(now);
  final yesterday = DateTime(today.year, today.month, today.day - 1);
  final formatted = DateFormat.yMd(strings.localeName).format(day);
  if (day == today) return strings.practiceToday(formatted);
  if (day == yesterday) return strings.practiceYesterday(formatted);
  return DateFormat.yMMMEd(strings.localeName).format(day);
}

String practiceDuration(AppLocalizations strings, Duration duration) {
  if (duration.inHours > 0) {
    return strings.practiceHoursMinutes(
      duration.inHours,
      duration.inMinutes.remainder(Duration.minutesPerHour),
    );
  }
  if (duration.inMinutes > 0) {
    return strings.practiceDurationMinutes(duration.inMinutes);
  }
  return strings.practiceDurationSeconds(duration.inSeconds);
}

String draftDuration(int seconds) {
  final duration = Duration(seconds: seconds);
  final minutes = duration.inMinutes.toString().padLeft(2, '0');
  final remaining = duration.inSeconds
      .remainder(Duration.secondsPerMinute)
      .toString()
      .padLeft(2, '0');
  return '$minutes:$remaining';
}
