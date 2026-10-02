import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../components/meloop_ui.dart';
import 'metronome_tokens.dart';
import 'metronome_ui_state.dart';

class MetronomeTempoControl extends StatelessWidget {
  const MetronomeTempoControl({
    super.key,
    required this.state,
    required this.onBpmChanged,
  });
  final MetronomeUiState state;
  final ValueChanged<int> onBpmChanged;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    children: [
      _stepButton(
        context.l10n.decreaseMetronomeBpm,
        MeloopIcons.minus,
        () => onBpmChanged(state.bpm - 1),
      ),
      Flexible(
        child: Column(
          children: [
            Semantics(
              label: context.l10n.tempoBpm,
              value: context.l10n.practiceBpm(state.bpm),
              child: ExcludeSemantics(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    state.bpm.toString(),
                    style: MetronomeTokens.bpmValue,
                  ),
                ),
              ),
            ),
            const SizedBox(height: MetronomeTokens.bpmUnitGap),
            Text(context.l10n.metronomeBpmUnit, style: MetronomeTokens.bpmUnit),
          ],
        ),
      ),
      _stepButton(
        context.l10n.increaseMetronomeBpm,
        MeloopIcons.plus,
        () => onBpmChanged(state.bpm + 1),
      ),
    ],
  );

  Widget _stepButton(String label, MeloopIcons icon, VoidCallback callback) =>
      IconButton(
        tooltip: label,
        onPressed: callback,
        style: IconButton.styleFrom(
          backgroundColor: TempoColors.teal,
          foregroundColor: TempoColors.white,
          fixedSize: const Size.square(MetronomeTokens.roundButtonSize),
          padding: EdgeInsets.zero,
          shape: const CircleBorder(),
        ),
        icon: MeloopIcon(
          icon,
          size: MetronomeTokens.roundIconSize,
          color: TempoColors.white,
        ),
      );
}

class MetronomeTempoSlider extends StatelessWidget {
  const MetronomeTempoSlider({
    super.key,
    required this.bpm,
    required this.onChanged,
  });
  final int bpm;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: MetronomeTokens.cardFill,
      border: Border.all(color: TempoColors.line),
      borderRadius: BorderRadius.circular(TempoRadius.card),
    ),
    child: Padding(
      padding: const EdgeInsets.all(MetronomeTokens.rangePadding + 1),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              top: MetronomeTokens.rangeMargin,
              bottom: MetronomeTokens.rangeLabelGap,
            ),
            child: Transform.translate(
              offset: const Offset(MetronomeTokens.rangeMargin, 0),
              child: SizedBox(
                height: MetronomeTokens.rangeHeight,
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: MetronomeTokens.rangeTrackHeight,
                    trackShape: const _TempoSliderTrack(),
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: MetronomeTokens.rangeThumbRadius,
                      elevation: 0,
                      pressedElevation: 0,
                    ),
                    overlayShape: SliderComponentShape.noOverlay,
                    activeTrackColor: TempoColors.teal,
                    inactiveTrackColor: MetronomeTokens.rangeInactive,
                    thumbColor: TempoColors.teal,
                  ),
                  child: Slider(
                    value: bpm.toDouble(),
                    min: MetronomeUiLimits.minimumBpm.toDouble(),
                    max: MetronomeUiLimits.maximumBpm.toDouble(),
                    padding: EdgeInsets.zero,
                    label: context.l10n.practiceBpm(bpm),
                    semanticFormatterCallback: (value) =>
                        context.l10n.practiceBpm(value.round()),
                    onChanged: (value) => onChanged(value.round()),
                  ),
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.practiceBpm(MetronomeUiLimits.minimumBpm),
                style: MetronomeTokens.rangeLabel,
              ),
              Text(
                context.l10n.practiceBpm(MetronomeUiLimits.maximumBpm),
                style: MetronomeTokens.rangeLabel,
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// Matches the native HTML range track without Material's wider end padding.
class _TempoSliderTrack extends SliderTrackShape {
  const _TempoSliderTrack();

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) => Rect.fromLTWH(
    offset.dx + MetronomeTokens.rangeThumbRadius,
    offset.dy + (parentBox.size.height - MetronomeTokens.rangeTrackHeight) / 2,
    parentBox.size.width - MetronomeTokens.rangeThumbRadius * 2,
    MetronomeTokens.rangeTrackHeight,
  );

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isEnabled = false,
    bool isDiscrete = false,
    required TextDirection textDirection,
  }) {
    final track = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
    );
    final fullTrack = Rect.fromLTRB(
      track.left - MetronomeTokens.rangeThumbRadius,
      track.top,
      track.right + MetronomeTokens.rangeThumbRadius,
      track.bottom,
    );
    final shape = RRect.fromRectAndRadius(
      fullTrack,
      const Radius.circular(MetronomeTokens.rangeTrackHeight / 2),
    );
    final canvas = context.canvas;
    canvas.drawRRect(shape, Paint()..color = MetronomeTokens.rangeInactive);
    canvas.drawRRect(
      shape,
      Paint()
        ..color = MetronomeTokens.rangeBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = MetronomeTokens.rangeBorderWidth,
    );
    canvas.save();
    canvas.clipRRect(shape);
    canvas.drawRect(
      Rect.fromLTRB(
        textDirection == TextDirection.ltr ? fullTrack.left : thumbCenter.dx,
        fullTrack.top,
        textDirection == TextDirection.ltr ? thumbCenter.dx : fullTrack.right,
        fullTrack.bottom,
      ),
      Paint()..color = TempoColors.teal,
    );
    canvas.restore();
  }
}
