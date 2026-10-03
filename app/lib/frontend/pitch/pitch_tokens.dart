import 'package:flutter/material.dart';

import '../theme/tokens/tempo_tokens.dart';

/// Tuner rules from Tempo's final style.css / fidelity.css cascade.
abstract final class PitchTokens {
  static const pageInset = 18.0;
  static const topBarGap = 23.0;
  static const heroHeight = 270.0;
  static const artworkSize = 275.0;
  static const cardInset = 18.0;
  static const cardFill = Color(0x55FFFFFF);
  static const pillFill = Color(0xFFE7EBDD);
  static const pillInset = EdgeInsets.symmetric(horizontal: 9, vertical: 5);
  static const gaugeHeight = 95.0;
  static const gaugeTopGap = 18.0;
  static const gaugeBottomGap = 10.0;
  static const gaugeStroke = 2.0;
  static const tickStroke = 1.0;
  static const tickColor = Color(0x44AEC0B3);
  static const gaugeIntervals = 10;
  static const gaugeRangeCents = 50.0;
  static const needleHeightFraction = .75;
  static const needleWidth = 3.0;
  static const footnoteInset = EdgeInsets.symmetric(
    horizontal: 4,
    vertical: 13,
  );
  static const buttonHeight = 53.0;
  static const measurementDigits = 1;
  static const centsDigits = 0;

  static final note = TempoType.metric.copyWith(
    fontSize: 78,
    height: 1.1,
    fontWeight: FontWeight.w600,
    letterSpacing: -3,
  );
  static final pill = TempoType.caption.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );
  static final footnote = TempoType.caption.copyWith(
    height: 1.7,
    letterSpacing: 0,
    color: TempoColors.muted,
  );
  static final action = TempoType.label.copyWith(fontSize: 17);
}
