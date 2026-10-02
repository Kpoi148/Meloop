import 'package:flutter/material.dart';

import '../theme/tokens/tempo_tokens.dart';

abstract final class PracticeSessionFormTokens {
  static const introHeight = 128.0;
  static const introInset = EdgeInsets.only(left: 4, right: 4, bottom: 18);
  static const artSize = 116.0;
  static const artTop = 8.0;
  static const artRight = -22.0;
  static const artOpacity = .87;
  static const headingTop = 8.0;
  static const subtitleGap = 9.0;
  static const labelGap = 9.0;
  static const fieldGap = 17.0;
  static const dateRowGap = fieldGap;
  static const dividerGap = 37.0;
  static final heading = TempoType.heading.copyWith(fontSize: 31, height: 1.18);
  static final subtitle = TempoType.body.copyWith(
    fontSize: 15,
    letterSpacing: 0,
    color: TempoColors.muted,
  );
  static final label = TempoType.label.copyWith(
    fontSize: 16,
    height: 1.3,
    letterSpacing: 0,
  );
  static final input = TempoType.body.copyWith(
    fontSize: 16,
    height: 1.3,
    letterSpacing: 0,
  );
  static final note = TempoType.body.copyWith(
    fontSize: 16,
    height: 1.55,
    letterSpacing: 0,
  );
}

abstract final class PracticeSessionFormLimits {
  static const minimumNewMinutes = 1;
  static const minimumEditMinutes = 0;
  static const maximumMinutes = Duration.minutesPerDay;
  static const minimumSeconds = 1;
  static const maximumSeconds = maximumMinutes * Duration.secondsPerMinute;
  static const minimumBpm = 20;
  static const maximumBpm = 400;
}
