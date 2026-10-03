import 'package:flutter/material.dart';

import '../theme/tokens/tempo_tokens.dart';

/// The recordings view and empty-state rules in the Tempo prototype.
abstract final class RecordingsTokens {
  static const pagePadding = EdgeInsets.fromLTRB(20, 22, 20, 30);
  static const topBarGap = 16.0;
  static const introInset = EdgeInsets.fromLTRB(4, 0, 4, 16);
  static const headingArtworkGap = 12.0;
  static const artworkSize = 160.0;
  static const artworkMinSize = 112.0;
  static const artworkWidthFactor = .42;
  static const artworkOpacity = .85;
  static const footerInset = EdgeInsets.fromLTRB(20, 12, 20, 12);
  static const footerHintGap = 8.0;
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
  static const cardPadding = 15.0;
  static const cardGap = 13.0;
  static const cardRadius = 18.0;
  static const cardFill = Color(0x66FFFFFF);
  static const instrumentSize = 62.0;
  static const instrumentFill = Color(0xFFEEEADB);
  static const metadataGap = 5.0;
  static const playerGap = 12.0;
  static const playerHeight = 35.0;
  static const playerControlSize = 30.0;
  static const playerPadding = EdgeInsets.symmetric(horizontal: 12);
  static const actionsTop = 16.0;
  static const actionHeight = 19.0;
  static const playerVolumeSize = 32.0;
  static const playerTrackMargin = 12.0;
  static const actionGap = 20.0;
  static const actionIconSize = 16.0;
  static const actionIconGap = 4.0;
  static const emptyTop = 14.0;
  static const compactTextThreshold = 20.0;
  static final cardTitle = TempoType.title.copyWith(fontSize: 16);
  static final metadata = TempoType.caption.copyWith(color: TempoColors.muted);
  static final action = TempoType.caption.copyWith(color: TempoColors.ink);
  static final playerTime = TempoType.caption.copyWith(
    fontSize: 13,
    color: const Color(0xFF202124),
    fontFeatures: const [FontFeature.tabularFigures()],
  );
  static final heading = TempoType.heading.copyWith(fontSize: 28);
}
