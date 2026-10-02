import 'package:flutter/material.dart';

import 'tempo_tokens.dart';

/// Dimensions from Tempo's final timer composition at 390 / 460 px.
abstract final class PracticeTempo {
  static const instrumentAsset =
      'assets/illustrations/practice-instruments.png';
  static const timerFrameAsset =
      'assets/illustrations/practice-timer-frame.png';
  static const guitarTimerAsset = 'assets/illustrations/fidelity-timer.png';
  static const guitarCoverAsset = 'assets/illustrations/fidelity-setup.png';
  static const instrumentColumns = 4;
  static const instrumentRows = 2;
  static const otherInstrumentCell = 7;
  static const profileCoverBackground = Color(0xFFF4DB7B);
  static const profileArtSize = 170.0;
  static const profileArtLeft = -28.0;
  static const profileArtTop = -22.0;
  static const guitarCoverAlignment = Alignment(0, .4);
  static const profileGap = 15.0;
  static const titleIconGap = 9.0;
  static const titleIconSize = 20.0;
  static const pagePadding = EdgeInsets.fromLTRB(20, 14, 20, 30);
  static const stageOverlap = 5.0;
  static const stageInstrumentScale = .72;
  static const stageInstrumentLeft = -45.0;
  static const stageInstrumentTopFraction = .25;
  static const compactStageInstrumentScale = .48;
  static const compactStageInstrumentLeft = -80.0;
  static const compactStageInstrumentTopFraction = .46;
  static const fluteRotationDivisor = 6;
  static const actionGap = 10.0;
  static const toolsActionBackground = Color(0xFFDEE8DD);
  static const toolsButtonHeight = 54.0;
  static const profileName = TextStyle(
    fontFamily: TempoType.fontFamily,
    fontSize: 20,
    height: 1.3,
    letterSpacing: -.6,
    fontWeight: FontWeight.w700,
  );
  static const titleCaption = TextStyle(
    fontFamily: TempoType.fontFamily,
    fontSize: 13,
    height: 1.4,
    color: Color(0xFF64877E),
  );
  static const sessionName = TextStyle(
    fontFamily: TempoType.fontFamily,
    fontSize: 23,
    height: 1.2,
    letterSpacing: -.75,
    fontWeight: FontWeight.w700,
  );
  static const runningLabel = TextStyle(
    fontFamily: TempoType.fontFamily,
    fontSize: 16,
    height: 1.5,
    letterSpacing: .2,
    fontWeight: FontWeight.w700,
  );
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
  static const wideReadout = TextStyle(
    fontFamily: TempoType.fontFamily,
    fontSize: 92,
    height: 1.15,
    letterSpacing: -5,
    fontWeight: FontWeight.w700,
  );
  static const compactReadout = TextStyle(
    fontFamily: TempoType.fontFamily,
    fontSize: 74,
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
