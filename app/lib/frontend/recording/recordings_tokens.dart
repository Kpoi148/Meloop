import 'package:flutter/material.dart';

import '../theme/tokens/tempo_tokens.dart';

/// The recordings view and empty-state rules in the Tempo prototype.
abstract final class RecordingsTokens {
  static const introHeight = 152.0;
  static const introTopPadding = 14.0;
  static const headingWidthFactor = .85;
  static const subtitleWidthFactor = .75;
  static const artworkSize = 160.0;
  static const artworkRight = -15.0;
  static const artworkTop = -20.0;
  static const artworkOpacity = .85;
  static const emptyPadding = EdgeInsets.symmetric(
    horizontal: 17,
    vertical: 25,
  );
  static const emptyMessageTop = 10.0;
  static const emptyMessageBottom = 16.0;
  static const emptyRadius = 18.0;
  static const emptyBorder = Color(0xFFBECBC1);
  static const borderWidth = 1.0;
  static const dashLength = 3.0;
  static const dashGap = 3.0;
  static final heading = TempoType.heading.copyWith(
    fontSize: 31,
    shadows: const [
      Shadow(color: TempoColors.paper, offset: Offset(0, 1), blurRadius: 10),
    ],
  );
}
