import 'package:flutter/material.dart';

import '../theme/tokens/tempo_tokens.dart';

abstract final class ProgressFilterTokens {
  static const popupHeightFraction = .86;
  static const popupInsetPadding = EdgeInsets.symmetric(
    horizontal: TempoSpace.page,
    vertical: TempoSpace.xl,
  );
  static const headerHeight = 126.0;
  static const compactHeaderHeight = 108.0;
  static const artworkSize = 112.0;
  static const artworkWidthFraction = .38;
  static const artworkRight = -8.0;
  static const artworkTop = 24.0;
  static const headerTextFraction = .64;
  static const headerGradientStops = [.35, .50, .75];
  static const scrollPadding = EdgeInsets.all(TempoSpace.lg);
  static const badgePadding = EdgeInsets.symmetric(horizontal: 10, vertical: 5);
  static const presetPadding = EdgeInsets.symmetric(horizontal: TempoSpace.xs);
  static const presetLabelPadding = EdgeInsets.symmetric(
    horizontal: TempoSpace.xs,
  );
  static const calendarCellHeight = 44.0;
  static const calendarCircleSize = 34.0;
  static const calendarTextWidthFactor = 1.8;
  static const calendarTextHeightFactor = 1.5;
  static const calendarPadding = EdgeInsets.all(TempoSpace.md);
  static const footerPadding = EdgeInsets.fromLTRB(16, 12, 16, 16);
  static final profile = TempoType.caption.copyWith(
    color: TempoColors.ink,
    fontWeight: FontWeight.w600,
  );
  static final title = TempoType.heading.copyWith(
    fontSize: 23,
    height: 1.25,
    letterSpacing: -.6,
  );
  static final subtitle = TempoType.body.copyWith(
    fontSize: 13,
    height: 1.6,
    color: TempoColors.muted,
  );
  static final badge = TempoType.label.copyWith(
    fontSize: 11,
    height: 1.4,
    fontWeight: FontWeight.w700,
  );
  static final dateLabel = TempoType.caption.copyWith(
    fontSize: 11,
    height: 1.5,
    letterSpacing: 0,
  );
  static final dateValue = TempoType.label.copyWith(
    fontSize: 14,
    height: 1.5,
    letterSpacing: 0,
  );
  static final calendarDay = TempoType.body.copyWith(fontSize: 14, height: 1.5);
  static final calendarWeekday = TempoType.caption.copyWith(
    fontSize: 11,
    height: 1.5,
    color: TempoColors.muted,
  );
  static final footerNote = TempoType.caption.copyWith(
    color: TempoColors.muted,
    height: 1.5,
  );
}
