import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../components/meloop_ui.dart';
import 'recording_tokens.dart';
import 'recordings_tokens.dart';

class RecordingsIntro extends StatelessWidget {
  const RecordingsIntro({super.key});

  @override
  Widget build(BuildContext context) {
    final largeText =
        MediaQuery.textScalerOf(context).scale(TempoType.body.fontSize!) >
        RecordingsTokens.compactTextThreshold;
    final heading = Text(
      context.l10n.sessionRecordingsHeading,
      style: RecordingsTokens.heading,
    );
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        heading,
        const SizedBox(height: RecordingTokens.subtitleGap),
        Text(
          context.l10n.sessionRecordingsSubtitle,
          style: RecordingTokens.subtitle,
        ),
      ],
    );
    return Padding(
      padding: RecordingsTokens.introInset,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = largeText
              ? RecordingsTokens.artworkSize
              : (constraints.maxWidth * RecordingsTokens.artworkWidthFactor)
                    .clamp(
                      RecordingsTokens.artworkMinSize,
                      RecordingsTokens.artworkSize,
                    );
          final art = Opacity(
            opacity: RecordingsTokens.artworkOpacity,
            child: MeloopArt.tool(
              MeloopTool.recordings,
              size: size,
              filterQuality: FilterQuality.high,
            ),
          );
          if (largeText) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(alignment: Alignment.centerRight, child: art),
                copy,
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: copy),
              const SizedBox(width: RecordingsTokens.headingArtworkGap),
              art,
            ],
          );
        },
      ),
    );
  }
}

class EmptyRecordingsBorder extends CustomPainter {
  const EmptyRecordingsBorder();

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(RecordingsTokens.borderWidth / 2),
          const Radius.circular(RecordingsTokens.emptyRadius),
        ),
      );
    final paint = Paint()
      ..color = RecordingsTokens.emptyBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = RecordingsTokens.borderWidth;
    for (final metric in outline.computeMetrics()) {
      for (
        var distance = 0.0;
        distance < metric.length;
        distance += RecordingsTokens.dashLength + RecordingsTokens.dashGap
      ) {
        canvas.drawPath(
          metric.extractPath(
            distance,
            (distance + RecordingsTokens.dashLength).clamp(0, metric.length),
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(EmptyRecordingsBorder oldDelegate) => false;
}
