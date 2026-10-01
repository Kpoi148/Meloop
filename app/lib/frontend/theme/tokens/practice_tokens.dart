import 'package:flutter/material.dart';

import 'tempo_tokens.dart';

/// Dimensions from Tempo's final timer composition at 390 / 460 px.
abstract final class PracticeTempo {
  static const profileCover = 111.0;
  static const compactProfileCover = 96.0;
  static const stageHeight = 400.0;
  static const wideStageHeight = 455.0;
  static const readoutTop = 115.0;
  static const wideReadoutTop = 140.0;
  static const readoutLeft = 117.0;
  static const wideReadoutLeft = 145.0;
  static const compactReadoutLeft = 96.0;
  static const readoutRight = 14.0;
  static const wideReadoutRight = 20.0;
  static const wideContentWidth = 400.0;
  static const compactContentWidth = 320.0;
  static const timerButtonHeight = 60.0;
  static const fabSize = 60.0;
  static const fabClearance = fabSize + TempoSpace.xl;
  static const detailArtSize = 220.0;
  static const toolArtSize = 190.0;
  static const toolCardHeight = 242.0;
  static const toolFooterMinHeight = 77.0;
  static const toolCardRadius = 23.0;
  static const toolArrowSize = 27.0;
  static const toolYellow = Color(0xFFFFF1CA);
  static const toolSage = Color(0xFFE1EBDE);
  static const toolYellowFooter = Color(0xFFFFF5DC);
  static const toolSageFooter = Color(0xFFEAF0E5);
  static const toolTitle = TextStyle(
    fontFamily: TempoType.fontFamily,
    fontSize: 16,
    height: 1.1,
    letterSpacing: -.65,
    fontWeight: FontWeight.w700,
  );
  static const toolCaption = TextStyle(
    fontFamily: TempoType.fontFamily,
    fontSize: 10,
    height: 1.45,
  );
  static const setupStageHeight = 370.0;
  static const wideSetupStageHeight = 430.0;
  static const setupHeadingTop = 21.0;
  static const setupProfileOverlap = 32.0;
  static const setupBarGap = 7.0;
  static const setupProfilePadding = EdgeInsets.symmetric(
    horizontal: 17,
    vertical: 13,
  );
  static const readout = TextStyle(
    fontFamily: TempoType.fontFamily,
    fontSize: 83,
    height: 1.15,
    letterSpacing: -5,
    fontWeight: FontWeight.w700,
  );
  static const longReadout = TextStyle(
    fontFamily: TempoType.fontFamily,
    fontSize: 64,
    height: 1.15,
    letterSpacing: -3,
    fontWeight: FontWeight.w700,
  );
}
