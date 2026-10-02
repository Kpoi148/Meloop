import 'package:flutter/material.dart';

import '../theme/tokens/tempo_tokens.dart';

/// Values from the session detail and dialog rules in Tempo's CSS cascade.
abstract final class PracticeSessionDetailTokens {
  static const artSize = 250.0;
  static const instrumentArtSize = 220.0;
  static const topBarHeight = 38.0;
  static const topBarIconSize = 26.0;
  static const titleMargin = EdgeInsets.only(top: 4, bottom: 10);
  static const ratingsMargin = EdgeInsets.symmetric(vertical: 14);
  static const ratingPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 15,
  );
  static const ratingValueMargin = EdgeInsets.symmetric(vertical: 7);
  static const notePadding = EdgeInsets.symmetric(vertical: 16);
  static const nextMargin = 18.0;
  static const nextFill = Color(0xFFFFF0BE);
  static const nextBorder = Color(0xFFEDDAA0);
  static const cardFill = Color(0x55FFFFFF);
  static const nextPadding = EdgeInsets.all(18);
  static const recordingsMargin = EdgeInsets.only(top: 10, bottom: 14);
  // Include the CSS border in the content inset (3px 13px + 1px border).
  static const recordingsPadding = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 4,
  );
  static const recordingsArtSize = 47.0;
  static const recordingsGap = 15.0;
  static const actionsGap = 11.0;
  static const compactActionsWidth = 300.0;
  static const largeActionTextSize = 20.0;
  static const actionIconGap = 10.0;
  static const outlineBorder = Color(0xFFB6C3BB);
  static const destructiveFill = Color(0xFFA74331);
  static const dialogMaxWidth = 410.0;
  static const dialogInset = 17.0;
  static const dialogPadding = 25.0;
  static const dialogRadius = 23.0;
  static const dialogBarrier = Color(0x77001E34);
  static const dialogBlur = 4.0;
  static const dialogMessageTop = 20.0;
  static const dialogActionsTop = 20.0;

  static final heading = TempoType.heading.copyWith(
    fontSize: 34,
    height: 1.18,
    letterSpacing: -1.5,
  );
  static final meta = TempoType.body.copyWith(
    fontSize: 14,
    color: TempoColors.muted,
    letterSpacing: 0,
  );
  static final ratingLabel = TempoType.caption.copyWith(
    fontSize: 12,
    color: TempoColors.muted,
  );
  static final ratingValue = TempoType.section.copyWith(
    fontSize: 27,
    height: 36 / 27,
    letterSpacing: 0,
  );
  static final ratingSuffix = TempoType.caption.copyWith(
    fontSize: 13,
    height: 1.6,
    fontWeight: FontWeight.w700,
  );
  static final noteHeading = TempoType.title.copyWith(fontSize: 16);
  static final noteBody = TempoType.body.copyWith(
    fontSize: 15,
    height: 1.7,
    letterSpacing: 0,
  );
  static final nextBody = TempoType.body.copyWith(
    fontSize: 14,
    color: TempoColors.muted,
    letterSpacing: 0,
  );
  static final recordingsLabel = TempoType.compactTitle.copyWith(fontSize: 17);
  static final dialogHeading = TempoType.section.copyWith(fontSize: 24);
  static final dialogMessage = TempoType.body.copyWith(
    fontSize: 14,
    color: TempoColors.muted,
    letterSpacing: 0,
  );
  static final dialogAction = TempoType.button.copyWith(fontSize: 14);
}
