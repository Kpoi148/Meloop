import 'package:flutter/material.dart';

import '../theme/tokens/tempo_tokens.dart';

/// The metro screen's final style.css + fidelity.css cascade.
abstract final class MetronomeTokens {
  static const smallPageBreakpoint = 359.0;
  static const smallPageInset = 16.0;
  static const topBarHeight = 38.0;
  static const topBarButtonSize = 37.0;
  static const heroHeight = 270.0;
  static const artSize = 275.0;
  static const roundButtonSize = 48.0;
  static const roundIconSize = 28.0;
  static const bpmBottomGap = 18.0;
  static const bpmUnitGap = 4.0;
  static const rangePadding = 18.0;
  static const rangeHeight = 30.0;
  static const rangeMargin = 2.0;
  static const rangeLabelGap = 4.0;
  static const rangeTrackHeight = 8.0;
  static const rangeThumbRadius = 7.5;
  static const rangeInactive = Color(0xFFEFEFEF);
  static const rangeBorder = Color(0xFFB2B2B2);
  static const rangeBorderWidth = .5;
  static const cardFill = Color(0x55FFFFFF);
  static const beatMargin = 24.0;
  static const beatSize = 13.0;
  static const beatGap = 11.0;
  static const firstBeatStroke = 2.0;
  static const beatFill = Color(0xFFD7DFD4);
  static const activeBeatScale = 1.2;
  static const fieldMargin = 17.0;
  static const fieldLabelGap = 9.0;
  static const fieldHeight = 50.0;
  static const selectIconSize = 12.0;
  static const fieldContentInset = EdgeInsets.only(left: 18, right: 4);
  static const actionIconGap = 10.0;
  static const footnoteMargin = EdgeInsets.symmetric(
    horizontal: 4,
    vertical: 13,
  );

  static final topBarTitle = TempoType.label.copyWith(
    fontSize: 17,
    height: 1.5,
    letterSpacing: 0,
  );
  static final bpmValue = TempoType.metric.copyWith(
    fontSize: 72,
    height: 1.1,
    letterSpacing: -3,
  );
  static final bpmUnit = TempoType.caption.copyWith(
    fontSize: 13,
    letterSpacing: 0,
    color: TempoColors.muted,
  );
  static final rangeLabel = TempoType.caption.copyWith(
    height: 1.25,
    letterSpacing: 0,
    color: TempoColors.muted,
  );
  static final fieldLabel = TempoType.label.copyWith(
    height: 1.25,
    letterSpacing: 0,
  );
  static final fieldValue = TempoType.body.copyWith(
    height: 1.375,
    letterSpacing: 0,
  );
  static final footnote = TempoType.caption.copyWith(
    height: 1.7,
    letterSpacing: 0,
    color: TempoColors.muted,
  );
}
