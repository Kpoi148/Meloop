import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../components/meloop_ui.dart';
import '../theme/tokens/practice_tokens.dart';

/// Both timer illustrations resolve their instrument from the active profile.
class PracticeInstrumentArt extends StatelessWidget {
  const PracticeInstrumentArt({
    super.key,
    required this.instrument,
    required this.size,
  });

  final MeloopInstrument instrument;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cell = instrument == MeloopInstrument.other
        ? PracticeTempo.otherInstrumentCell
        : instrument.index;
    return ExcludeSemantics(
      child: ClipRect(
        child: SizedBox.square(
          dimension: size,
          child: OverflowBox(
            maxWidth: size * PracticeTempo.instrumentColumns,
            maxHeight: size * PracticeTempo.instrumentRows,
            alignment: Alignment(
              -1 +
                  2 *
                      (cell % PracticeTempo.instrumentColumns) /
                      (PracticeTempo.instrumentColumns - 1),
              cell < PracticeTempo.instrumentColumns ? -1 : 1,
            ),
            child: Image.asset(
              PracticeTempo.instrumentAsset,
              width: size * PracticeTempo.instrumentColumns,
              height: size * PracticeTempo.instrumentRows,
              fit: BoxFit.fill,
            ),
          ),
        ),
      ),
    );
  }
}

class PracticeProfileCover extends StatelessWidget {
  const PracticeProfileCover({
    super.key,
    required this.instrument,
    required this.size,
  });

  final MeloopInstrument instrument;
  final double size;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(TempoRadius.recent),
    child: SizedBox.square(
      dimension: size,
      child: ColoredBox(
        color: PracticeTempo.profileCoverBackground,
        child: Stack(
          children: [
            Positioned(
              left: PracticeTempo.profileArtLeft,
              top: PracticeTempo.profileArtTop,
              width: PracticeTempo.profileArtSize,
              height: PracticeTempo.profileArtSize,
              child: instrument == MeloopInstrument.guitar
                  ? Image.asset(
                      PracticeTempo.guitarCoverAsset,
                      fit: BoxFit.cover,
                      alignment: PracticeTempo.guitarCoverAlignment,
                      excludeFromSemantics: true,
                    )
                  : PracticeInstrumentArt(
                      instrument: instrument,
                      size: PracticeTempo.profileArtSize,
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}

class PracticeTimerArtwork extends StatelessWidget {
  const PracticeTimerArtwork({
    super.key,
    required this.instrument,
    required this.height,
  });

  final MeloopInstrument instrument;
  final double height;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth + TempoSpace.page * 2;
      final isFlute = instrument == MeloopInstrument.flute;
      final instrumentSize =
          height *
          (isFlute
              ? PracticeTempo.stageInstrumentScale
              : PracticeTempo.compactStageInstrumentScale);
      return SizedBox(
        height: height,
        child: OverflowBox(
          minWidth: width,
          maxWidth: width,
          minHeight: height,
          maxHeight: height,
          child: instrument == MeloopInstrument.guitar
              ? Image.asset(
                  PracticeTempo.guitarTimerAsset,
                  width: width,
                  height: height,
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                )
              : Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: isFlute
                          ? PracticeTempo.stageInstrumentLeft
                          : PracticeTempo.compactStageInstrumentLeft,
                      top:
                          height *
                          (isFlute
                              ? PracticeTempo.stageInstrumentTopFraction
                              : PracticeTempo
                                    .compactStageInstrumentTopFraction),
                      child: Transform.rotate(
                        angle: isFlute
                            ? -math.pi / PracticeTempo.fluteRotationDivisor
                            : 0,
                        child: PracticeInstrumentArt(
                          instrument: instrument,
                          size: instrumentSize,
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Image.asset(
                        PracticeTempo.timerFrameAsset,
                        fit: BoxFit.cover,
                        excludeFromSemantics: true,
                      ),
                    ),
                  ],
                ),
        ),
      );
    },
  );
}
