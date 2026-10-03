import 'package:flutter/material.dart';

import '../theme/tokens/tempo_tokens.dart';

/// Recorder rules from the final style.css + fidelity.css cascade.
abstract final class RecordingTokens {
  static const topBarHeight = 38.0;
  static const topBarButtonSize = 37.0;
  static const introInset = EdgeInsets.fromLTRB(4, 0, 4, 22);
  static const introMaxWidth = 365.0;
  static const createIconGap = 10.0;
  static const subtitleGap = 9.0;
  static const heroHeight = 270.0;
  static const artworkSize = 275.0;
  static const artworkEdgeInset = 1.0;
  static const cardPadding = 19.0;
  static const cardFill = Color(0x55FFFFFF);
  static const waveformHeight = 65.0;
  static const waveformMargin = 20.0;
  static const waveformBars = 34;
  static const waveformBarWidth = 4.0;
  static const waveformBarGap = 4.0;
  static const waveformBarRadius = 3.0;
  static const waveformBaseHeight = 10.0;
  static const waveformHeightRange = 20.0;
  static const waveformPhase = 1.8;
  static const waveformColor = Color(0xFF7DA8A4);
  static const waveformCycle = Duration(milliseconds: 1400);
  static const recordButtonSize = 79.0;
  static const recordIconSize = 28.0;
  static const recordButtonMargin = 22.0;
  static const footnoteMargin = EdgeInsets.symmetric(
    horizontal: 4,
    vertical: 13,
  );
  static const playbackHeight = 54.0;
  static const playbackMargin = 15.0;
  static const playbackFill = Color(0xFFF1F3F4);
  static const playbackInk = Color(0xFF202124);
  static const playbackInactiveTrack = Color(0xFF5F5F5F);
  static const playbackThumbRadius = 4.0;
  static const quotaGap = 6.0;
  static const statusBottomGap = 13.0;
  static const playbackTrackHeight = 3.0;
  static const playbackControlSize = 32.0;
  static const playbackPlaySize = 40.0;
  static const outlineBorder = Color(0xFFB6C3BB);

  static final topBarTitle = TempoType.label.copyWith(
    fontSize: 17,
    height: 1.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );
  static final subtitle = TempoType.body.copyWith(
    fontSize: 15,
    color: TempoColors.muted,
  );
  static final readout = TempoType.metric.copyWith(
    fontSize: 57,
    height: 72 / 57,
    letterSpacing: -3,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
  static final footnote = TempoType.caption.copyWith(
    height: 1.7,
    letterSpacing: 0,
    color: TempoColors.muted,
  );
  static final status = footnote.copyWith(fontSize: 14);
  static final reviewTitle = TempoType.title.copyWith(height: 1.35);
  static final emptyDescription = TempoType.body.copyWith(
    fontSize: 14,
    letterSpacing: 0,
    color: TempoColors.muted,
  );
}
