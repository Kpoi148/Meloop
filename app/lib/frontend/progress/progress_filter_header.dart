import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../components/meloop_ui.dart';
import 'progress_filter_tokens.dart';
import 'progress_tokens.dart';

/// The illustration uses the original Tempo artwork and stays above the fields.
class ProgressFilterHeader extends StatelessWidget {
  const ProgressFilterHeader({super.key, required this.title, this.subtitle});
  final String title;
  final String? subtitle;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final largeText =
          MediaQuery.textScalerOf(context).scale(16) / 16 >
          ProgressTokens.largeTextThreshold;
      final textWidth = largeText
          ? constraints.maxWidth
          : constraints.maxWidth * ProgressFilterTokens.headerTextFraction;
      final artworkSize = math.min(
        ProgressFilterTokens.artworkSize,
        constraints.maxWidth * ProgressFilterTokens.artworkWidthFraction,
      );
      final words = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(
              right: largeText ? TempoSize.touchTarget : 0,
            ),
            child: Container(
              padding: ProgressFilterTokens.badgePadding,
              decoration: BoxDecoration(
                color: TempoColors.yellow,
                borderRadius: BorderRadius.circular(TempoRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const MeloopIcon(MeloopIcons.star, size: TempoSize.smallIcon),
                  const SizedBox(width: TempoSpace.xs),
                  Flexible(
                    child: Text(
                      context.l10n.proTitle,
                      style: ProgressFilterTokens.badge,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: TempoSpace.md),
          Text(title, style: ProgressFilterTokens.title),
          if (subtitle != null) ...[
            const SizedBox(height: TempoSpace.sm),
            Text(subtitle!, style: ProgressFilterTokens.subtitle),
          ],
        ],
      );
      return Stack(
        children: [
          if (!largeText)
            Positioned(
              right: ProgressFilterTokens.artworkRight,
              top: ProgressFilterTokens.artworkTop,
              child: MeloopArt.scene(MeloopScene.guitar, size: artworkSize),
            ),
          if (!largeText)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      TempoColors.paper,
                      TempoColors.paper.withValues(alpha: .92),
                      TempoColors.paper.withValues(alpha: 0),
                    ],
                    stops: ProgressFilterTokens.headerGradientStops,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(
              top: TempoSpace.sm,
              bottom: TempoSpace.page,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: subtitle == null
                    ? ProgressFilterTokens.compactHeaderHeight
                    : ProgressFilterTokens.headerHeight,
              ),
              child: SizedBox(
                width: textWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (largeText)
                      const Align(
                        alignment: Alignment.centerRight,
                        child: MeloopArt.scene(
                          MeloopScene.guitar,
                          size: ProgressFilterTokens.artworkSize,
                        ),
                      ),
                    words,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              key: const Key('progress-filter-close'),
              tooltip: context.l10n.cancel,
              onPressed: () => Navigator.of(context).pop(),
              style: IconButton.styleFrom(
                backgroundColor: TempoColors.paper.withValues(alpha: .85),
              ),
              icon: const MeloopIcon(
                MeloopIcons.close,
                size: TempoSize.smallIcon,
              ),
            ),
          ),
        ],
      );
    },
  );
}
