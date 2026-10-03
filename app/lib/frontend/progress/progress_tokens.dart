import 'package:flutter/material.dart';

import '../theme/tokens/tempo_tokens.dart';

/// Measurements from the Progress rules in style.css + fidelity.css.
abstract final class ProgressTokens {
  static const headingHeight = 144.0;
  static const wideHeadingHeight = 166.0;
  static const widePageWidth = 440.0;
  static const compactPageWidth = 359.0;
  static const compactPageInset = 16.0;
  static EdgeInsets pagePadding(double width) => EdgeInsets.fromLTRB(
    width < compactPageWidth ? compactPageInset : TempoSpace.page,
    TempoSpace.pageTop,
    width < compactPageWidth ? compactPageInset : TempoSpace.page,
    TempoSpace.pageBottom,
  );
  static const largeTextThreshold = 1.3;
  static const detailGap = 9.0;
  static const fineGap = 2.0;
  static const metricLabelGap = 5.0;
  static const chipArtSize = 39.0;
  static const chipGap = 7.0;
  static const chipWidthFraction = .55;
  static const chipPadding = EdgeInsets.fromLTRB(3, 3, 11, 3);
  static const chipBorder = Color(0xFFD6DCD3);
  static const filterGap = 6.0;
  static const filterIconSize = 16.0;
  static const badgePadding = EdgeInsets.symmetric(horizontal: 5, vertical: 3);
  static const artworkSize = 258.0;
  static const artworkRight = -75.0;
  static const artworkTop = -48.0;
  static const headingPadding = EdgeInsets.fromLTRB(20, 13, 20, 0);
  static const headingGradientStops = [0.37, 0.49, 0.69];
  static const chartPadding = EdgeInsets.fromLTRB(14, 13, 14, 12);
  static const filterPadding = EdgeInsets.symmetric(horizontal: 8, vertical: 5);
  static const filterBorder = Color(0xFF98B8B5);
  static const metricsTop = 14.0;
  static const metricsBottom = 7.0;
  static const secondMetricInset = 27.0;
  static const barAreaHeight = 74.0;
  static const maximumBarHeight = 48.0;
  static const minimumMinutesScale = 35;
  static const minimumMinutesBarHeight = 2.0;
  static const minutesBarRadius = 5.0;
  static const minutesBarGap = 10.0;
  static const chartBaseline = Color(0x77B4D4D1);
  static const metricDivider = Color(0x7AB0C8C5);
  static const togetherFill = Color(0xFFEDF0E7);
  static const togetherDivider = Color(0xFFC9D5CB);
  static const togetherPadding = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 13,
  );
  static const togetherGap = 13.0;
  static const roundIconSize = 40.0;
  static const roundIconGlyph = 26.0;
  static const roundIconFill = Color(0xFFFFE8A3);
  static const sageIconFill = Color(0xFFC2DBD0);
  static const ratingIconSize = 34.0;
  static const ratingIconGlyph = 25.0;
  static const ratingPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 13,
  );
  static const compactRatingPadding = EdgeInsets.symmetric(
    horizontal: 9,
    vertical: 11,
  );
  static const ratingSummaryFraction = .44;
  static const compactRatingSummaryFraction = .42;
  static const ratingColumnGap = 9.0;
  static const ratingChartHeight = 83.0;
  static const ratingBarGap = 6.0;
  static const compactRatingBarGap = 3.0;
  static const ratingHeightPerPoint = 8.0;
  static const ratingBarFill = Color(0xFF99BFB0);
  static const ratingBarRadius = 4.0;
  static const minimumDayWidth = 19.0;
  static const minimumMinutesDayWidth = 32.0;
  static const linkHeight = 55.0;
  static const linkPadding = EdgeInsets.symmetric(horizontal: 10, vertical: 6);
  static const noteInk = Color(0xFF456977);
  static const eyebrowInk = Color(0xFF426570);

  static final pageTitle = TempoType.heading.copyWith(
    height: 1.3,
    letterSpacing: -1.4,
  );
  static final heading = TempoType.heading.copyWith(
    fontSize: 33,
    height: 1.09,
    letterSpacing: -1.3,
  );
  static final wideHeading = heading.copyWith(fontSize: 38);
  static final eyebrow = TempoType.label.copyWith(
    fontSize: 10,
    height: 1.5,
    letterSpacing: 1.2,
    color: eyebrowInk,
  );
  static final chartTitle = TempoType.compactTitle.copyWith(
    letterSpacing: -.35,
    color: TempoColors.white,
  );
  static final metric = TempoType.metric.copyWith(
    fontSize: 53,
    color: TempoColors.white,
  );
  static final metricLabel = TempoType.caption.copyWith(
    height: 1.4,
    letterSpacing: 0,
    color: TempoColors.white,
  );
  static final filterLabel = TempoType.caption.copyWith(
    height: 1.25,
    color: TempoColors.white,
  );
  static final badge = TempoType.label.copyWith(
    fontSize: 9,
    height: 11 / 9,
    fontWeight: FontWeight.w700,
  );
  static final barValue = TempoType.caption.copyWith(
    height: 1.5,
    fontWeight: FontWeight.w600,
    color: TempoColors.white,
  );
  static final dayLabel = TempoType.caption.copyWith(
    height: 17 / 12,
    letterSpacing: 0,
  );
  static final togetherLabel = TempoType.caption.copyWith(
    fontSize: 11,
    height: 1.6,
    letterSpacing: 0,
  );
  static final togetherValue = TempoType.section.copyWith(
    fontSize: 22,
    height: 30 / 22,
    letterSpacing: -.7,
  );
  static final hint = togetherLabel.copyWith(
    height: 1.5,
    color: TempoColors.muted,
  );
  static final ratingsHeading = TempoType.section.copyWith(
    fontSize: 25,
    letterSpacing: -1,
  );
  static final ratingsPeriod = TempoType.caption.copyWith(
    height: 1.5,
    color: noteInk,
    letterSpacing: 0,
  );
  static final ratingLabel = TempoType.label.copyWith(
    fontSize: 14,
    height: 1.6,
    fontWeight: FontWeight.w700,
    letterSpacing: -.3,
  );
  static final ratingNumber = TempoType.metric.copyWith(
    fontSize: 34,
    height: 41 / 34,
    letterSpacing: -1,
  );
  static final ratingDenominator = ratingNumber.copyWith(fontSize: 20);
  static final ratingCaption = TempoType.caption.copyWith(
    fontSize: 9,
    height: 1.5,
    color: TempoColors.muted,
    letterSpacing: 0,
  );
  static final ratingDay = ratingCaption.copyWith(color: TempoColors.ink);
  static final disclaimer = hint.copyWith(height: 1.6, color: noteInk);
  static final link = TempoType.label.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );
}
