import 'package:flutter/material.dart';

/// Final cascade in Tempo's style.css + fidelity.css (September 2026).
abstract final class TempoColors {
  static const paper = Color(0xFFFDFBF4);
  static const ink = Color(0xFF003442);
  static const teal = Color(0xFF004651);
  static const yellow = Color(0xFFFFCC43);
  static const orange = Color(0xFFC75C28);
  static const muted = Color(0xFF5D7579);
  static const line = Color(0xFFDCE2D9);
  static const soft = Color(0xFFE9EEE3);
  static const fieldBorder = Color(0xFF9BADAE);
  static const fieldFill = Color(0x44FFFFFF);
  static const error = Color(0xFF9A3627);
  static const errorSurface = Color(0xFFFAE8DF);
  static const selection = Color(0xFFFFF1C2);
  static const white = Colors.white;
  static const chart = Color(0xFF82B7B4);
}

abstract final class TempoSpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const page = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const pageTop = 22.0;
  static const pageBottom = 30.0;
}

abstract final class TempoRadius {
  static const field = 12.0;
  static const chip = 10.0;
  static const card = 19.0;
  static const action = 17.0;
  static const recent = 16.0;
  static const button = 20.0;
  static const pill = 50.0;
}

abstract final class TempoSize {
  static const contentMaxWidth = 460.0;
  static const touchTarget = 48.0;
  static const buttonMinHeight = 57.0;
  static const fieldMinHeight = 49.0;
  static const prominentButtonMinHeight = 53.0;
  static const icon = 24.0;
  static const buttonIcon = 25.0;
  static const navigationIcon = 26.0;
  static const smallIcon = 18.0;
}

abstract final class TempoType {
  static const fontFamily = 'Be Vietnam Pro';
  static const welcome = TextStyle(
    fontFamily: fontFamily,
    fontSize: 39,
    height: 1.08,
    letterSpacing: -1.65,
    fontWeight: FontWeight.w700,
  );
  static const setup = TextStyle(
    fontFamily: fontFamily,
    fontSize: 41,
    height: 1.05,
    letterSpacing: -1.7,
    fontWeight: FontWeight.w700,
  );
  static const metric = TextStyle(
    fontFamily: fontFamily,
    fontSize: 44,
    height: 1,
    letterSpacing: -2,
    fontWeight: FontWeight.w700,
  );
  static const prominentButton = TextStyle(
    fontFamily: fontFamily,
    fontSize: 23,
    height: 1.3,
    letterSpacing: -.7,
    fontWeight: FontWeight.w700,
  );
  static const compactTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    height: 1.35,
    fontWeight: FontWeight.w700,
  );
  static const compactBody = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 1.4,
  );
  static const heading = TextStyle(
    fontFamily: fontFamily,
    fontSize: 35,
    height: 1.16,
    letterSpacing: -1.5,
    fontWeight: FontWeight.w700,
  );
  static const section = TextStyle(
    fontFamily: fontFamily,
    fontSize: 23,
    height: 1.3,
    letterSpacing: -.8,
    fontWeight: FontWeight.w700,
  );
  static const title = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    height: 1.35,
    letterSpacing: -.35,
    fontWeight: FontWeight.w700,
  );
  static const body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 1.6,
    fontWeight: FontWeight.w400,
  );
  static const label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w600,
  );
  static const button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    height: 1.3,
    fontWeight: FontWeight.w700,
  );
  static const caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 1.6,
    fontWeight: FontWeight.w400,
  );
  static const wordmark = TextStyle(
    fontFamily: fontFamily,
    fontSize: 37,
    height: 1,
    letterSpacing: -2,
    fontWeight: FontWeight.w700,
  );
}
