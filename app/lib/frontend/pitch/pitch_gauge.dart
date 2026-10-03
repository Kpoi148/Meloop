import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/tokens/tempo_tokens.dart';
import 'pitch_tokens.dart';

/// The prototype's scale. A needle exists only for a current valid reading.
class PitchGauge extends StatelessWidget {
  const PitchGauge({super.key, this.cents});
  final double? cents;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      height: PitchTokens.gaugeHeight,
      width: double.infinity,
      child: CustomPaint(painter: _GaugePainter(cents)),
    ),
  );
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter(this.cents);
  final double? cents;

  @override
  void paint(Canvas canvas, Size size) {
    final tick = Paint()
      ..color = PitchTokens.tickColor
      ..strokeWidth = PitchTokens.tickStroke;
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndCorners(
        Offset.zero & size,
        topLeft: Radius.elliptical(size.width / 2, size.height / 2),
        topRight: Radius.elliptical(size.width / 2, size.height / 2),
      ),
    );
    for (var index = 1; index <= PitchTokens.gaugeIntervals; index++) {
      final x = size.width * index / PitchTokens.gaugeIntervals;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), tick);
    }
    canvas.restore();
    final scale = Paint()
      ..color = TempoColors.teal
      ..strokeWidth = PitchTokens.gaugeStroke;
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      scale,
    );
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      scale,
    );
    final value = cents;
    if (value == null || !value.isFinite) return;
    final angle =
        value.clamp(-PitchTokens.gaugeRangeCents, PitchTokens.gaugeRangeCents) *
        math.pi /
        180;
    final length = size.height * PitchTokens.needleHeightFraction;
    final pivot = Offset(size.width / 2, size.height);
    canvas.drawLine(
      pivot,
      pivot + Offset(math.sin(angle) * length, -math.cos(angle) * length),
      Paint()
        ..color = TempoColors.yellow
        ..strokeWidth = PitchTokens.needleWidth,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter oldDelegate) => cents != oldDelegate.cents;
}
