import 'package:flutter/material.dart';

import '../theme/tokens/tempo_tokens.dart';

/// Tempo styles with the compact header requested for the sessions tab.
abstract final class PracticeSessionsTokens {
  static const narrowViewport = 359.0;
  static const compactCardWidth = 300.0;
  static const narrowPageInset = 16.0;
  static const introMargin = EdgeInsets.symmetric(vertical: TempoSpace.page);
  static const subtitleGap = TempoSpace.sm;
  static const introArtGap = TempoSpace.lg;
  static const introArtSize = 96.0;
  static const narrowIntroArtSize = 80.0;
  static const introArtMaxTextScale = 1.25;
  static const introArtOpacity = .87;
  static const chipArtSize = 39.0;
  static const chipGap = 7.0;
  // Include the CSS border in Material's inner padding.
  static const chipPadding = EdgeInsets.fromLTRB(4, 4, 12, 4);
  static const chipBorder = Color(0xFFD6DCD3);
  static const searchBottomGap = 17.0;
  static const filterChoiceGap = 7.0;
  // CSS padding is 9 px / 12 px, with a 1 px border on each side.
  static const filterChoicePadding = EdgeInsets.symmetric(
    vertical: 10,
    horizontal: 13,
  );
  static const dayGap = 23.0;
  static const dayBottomGap = 9.0;
  static const cardArtWidth = 108.0;
  static const cardArtHeight = 135.0;
  static const cardPadding = EdgeInsets.symmetric(horizontal: 11, vertical: 13);
  static const cardTextGap = 7.0;
  static const cardFill = Color(0x77FFFFFF);
  static const cardArtFill = Color(0xFFF2EDDD);
  static const indicatorIconSize = 13.0;
  static const createIconGap = 10.0;

  static final heading = TempoType.heading.copyWith(fontSize: 31);
  static final subtitle = TempoType.body.copyWith(
    fontSize: 15,
    height: 1.45,
    letterSpacing: 0,
    color: TempoColors.muted,
  );
  static final chipLabel = TempoType.body.copyWith(
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
  );
  static final dayLabel = TempoType.caption.copyWith(
    fontSize: 13,
    letterSpacing: 0,
    color: TempoColors.muted,
    fontWeight: FontWeight.w600,
  );
  static final filterChoiceLabel = TempoType.body.copyWith(
    fontSize: 13,
    height: 16 / 13,
    letterSpacing: 0,
  );
  static final cardTitle = TempoType.title.copyWith(fontSize: 19);
  static final cardMeta = TempoType.caption.copyWith(
    letterSpacing: 0,
    fontWeight: FontWeight.w500,
  );
  static final cardNotes = TempoType.body.copyWith(
    fontSize: 13,
    letterSpacing: 0,
  );
  static final indicator = TempoType.compactBody.copyWith(
    fontSize: 11,
    letterSpacing: 0,
    color: TempoColors.muted,
  );
}
