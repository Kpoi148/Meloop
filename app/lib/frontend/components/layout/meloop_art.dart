import 'package:flutter/material.dart';

import '../../theme/tokens/tempo_tokens.dart';

enum MeloopInstrument { guitar, piano, ukulele, violin, flute, drums, other }

enum MeloopTool { metro, tuner, recorder, recordings }

enum MeloopScene { guitar, journal, progress, data, privacy, pro, envelope }

/// Crops the original Tempo sprite in layout; assets are copied unchanged.
class MeloopArt extends StatelessWidget {
  const MeloopArt.instrument(
    MeloopInstrument this.instrument, {
    super.key,
    this.size = 118,
    this.backgroundColor,
    this.filterQuality = FilterQuality.medium,
  }) : tool = null,
       scene = null,
       columns = 4,
       asset = 'instruments-v2.png';
  const MeloopArt.tool(
    MeloopTool this.tool, {
    super.key,
    this.size = 118,
    this.filterQuality = FilterQuality.medium,
  }) : instrument = null,
       backgroundColor = null,
       scene = null,
       columns = 2,
       asset = 'tools-v2.png';
  final MeloopInstrument? instrument;
  final MeloopTool? tool;
  const MeloopArt.scene(
    this.scene, {
    super.key,
    this.size = 118,
    this.backgroundColor,
    this.filterQuality = FilterQuality.medium,
  }) : instrument = null,
       tool = null,
       columns = 3,
       asset = 'illustrations.png';
  final MeloopScene? scene;
  int get index =>
      instrument?.index ??
      tool?.index ??
      switch (scene!) {
        MeloopScene.privacy => 2,
        MeloopScene.envelope => 3,
        final scene => scene.index,
      };
  final int columns;
  final String asset;
  final double size;
  final FilterQuality filterQuality;

  /// Matches Tempo's darken blend when the sprite sits on a colored surface.
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: ClipRect(
      child: SizedBox.square(
        dimension: size,
        child: OverflowBox(
          maxWidth: size * columns,
          maxHeight: size * 2,
          alignment: Alignment(
            -1 + 2 * (index % columns) / (columns - 1),
            index < columns ? -1 : 1,
          ),
          child: Image.asset(
            'assets/illustrations/$asset',
            width: size * columns,
            height: size * 2,
            fit: BoxFit.fill,
            filterQuality: filterQuality,
            color: backgroundColor,
            colorBlendMode: backgroundColor == null ? null : BlendMode.darken,
          ),
        ),
      ),
    ),
  );
}

/// Decorative full-bleed image; text and controls stay inside page safe areas.
class MeloopIllustration extends StatelessWidget {
  const MeloopIllustration({
    super.key,
    required this.asset,
    required this.height,
  });
  final String asset;
  final double height;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SizedBox(
      height: height,
      child: OverflowBox(
        minWidth: constraints.maxWidth + TempoSpace.page * 2,
        maxWidth: constraints.maxWidth + TempoSpace.page * 2,
        minHeight: height,
        maxHeight: height,
        child: Image.asset(
          'assets/illustrations/$asset',
          fit: BoxFit.cover,
          excludeFromSemantics: true,
        ),
      ),
    ),
  );
}
