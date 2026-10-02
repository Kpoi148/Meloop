import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../components/meloop_ui.dart';
import 'metronome_tokens.dart';
import 'metronome_ui_state.dart';
import 'metronome_tempo_control.dart';

/// Tempo's metro composition. State and commands are supplied by its caller.
class MetronomePage extends StatelessWidget {
  const MetronomePage({
    super.key,
    required this.state,
    required this.onBpmChanged,
    required this.onBeatsChanged,
    required this.onToggle,
    required this.onBack,
    required this.onHome,
  });

  final MetronomeUiState state;
  final ValueChanged<int> onBpmChanged, onBeatsChanged;
  final VoidCallback onToggle, onBack, onHome;

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final pageInset =
        MediaQuery.sizeOf(context).width <= MetronomeTokens.smallPageBreakpoint
        ? MetronomeTokens.smallPageInset
        : TempoSpace.page;
    final error = switch (state.error) {
      MetronomeUiError.bpmRange => strings.metronomeBpmRangeError(
        MetronomeUiLimits.minimumBpm,
        MetronomeUiLimits.maximumBpm,
      ),
      MetronomeUiError.beatsRange => strings.metronomeBeatsRangeError(
        MetronomeUiLimits.minimumBeats,
        MetronomeUiLimits.maximumBeats,
      ),
      MetronomeUiError.audioBusy => strings.metronomeAudioBusy,
      null => null,
    };
    return MeloopPage(
      padding: EdgeInsets.fromLTRB(
        pageInset,
        TempoSpace.pageTop,
        pageInset,
        TempoSpace.pageBottom,
      ),
      topBar: _MetronomeTopBar(onBack: onBack, onHome: onHome),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(
            height: MetronomeTokens.heroHeight,
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.topCenter,
                minWidth: MetronomeTokens.artSize,
                maxWidth: MetronomeTokens.artSize,
                minHeight: MetronomeTokens.artSize,
                maxHeight: MetronomeTokens.artSize,
                child: MeloopArt.tool(
                  MeloopTool.metro,
                  size: MetronomeTokens.artSize,
                ),
              ),
            ),
          ),
          MetronomeTempoControl(state: state, onBpmChanged: onBpmChanged),
          const SizedBox(height: MetronomeTokens.bpmBottomGap),
          MetronomeTempoSlider(bpm: state.bpm, onChanged: onBpmChanged),
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: MetronomeTokens.beatMargin,
            ),
            child: Semantics(
              label: strings.beatsPerBar,
              value: state.activeBeat == null
                  ? strings.beats(state.beatsPerBar)
                  : strings.metronomeCurrentBeat(
                      state.activeBeat! + 1,
                      state.beatsPerBar,
                    ),
              child: ExcludeSemantics(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: MetronomeTokens.beatGap,
                  runSpacing: MetronomeTokens.beatGap,
                  children: [
                    for (var index = 0; index < state.beatsPerBar; index++)
                      Transform.scale(
                        scale: state.activeBeat == index
                            ? MetronomeTokens.activeBeatScale
                            : 1,
                        child: Container(
                          key: ValueKey('metronome-beat-$index'),
                          width: MetronomeTokens.beatSize,
                          height: MetronomeTokens.beatSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: state.activeBeat == index
                                ? TempoColors.yellow
                                : index == 0
                                ? Colors.transparent
                                : MetronomeTokens.beatFill,
                            border: index == 0
                                ? Border.all(
                                    width: MetronomeTokens.firstBeatStroke,
                                    color: state.activeBeat == index
                                        ? TempoColors.yellow
                                        : TempoColors.teal,
                                  )
                                : null,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Text(strings.beatsPerBar, style: MetronomeTokens.fieldLabel),
          const SizedBox(height: MetronomeTokens.fieldLabelGap),
          _BeatsSelect(value: state.beatsPerBar, onChanged: onBeatsChanged),
          const SizedBox(height: MetronomeTokens.fieldMargin),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: TempoSpace.md),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  error,
                  style: TempoType.caption.copyWith(color: TempoColors.error),
                ),
              ),
            ),
          MeloopButton(
            label: state.playing
                ? strings.stopMetronome
                : strings.startMetronome,
            icon: state.playing ? MeloopIcons.pause : MeloopIcons.play,
            iconGap: MetronomeTokens.actionIconGap,
            onPressed: onToggle,
          ),
          Padding(
            padding: MetronomeTokens.footnoteMargin,
            child: Text(
              strings.metronomeFootnote,
              textAlign: TextAlign.center,
              style: MetronomeTokens.footnote,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetronomeTopBar extends StatelessWidget {
  const _MetronomeTopBar({required this.onBack, required this.onHome});
  final VoidCallback onBack, onHome;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: MetronomeTokens.topBarHeight),
    child: Row(
      children: [
        _action(context.l10n.back, MeloopIcons.back, onBack),
        Expanded(
          child: Text(
            context.l10n.metronomeTitle,
            textAlign: TextAlign.center,
            style: MetronomeTokens.topBarTitle,
          ),
        ),
        _action(context.l10n.navHome, MeloopIcons.home, onHome),
      ],
    ),
  );

  Widget _action(String label, MeloopIcons icon, VoidCallback callback) =>
      IconButton(
        tooltip: label,
        onPressed: callback,
        style: IconButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: const Size.square(MetronomeTokens.topBarButtonSize),
          fixedSize: const Size.square(MetronomeTokens.topBarButtonSize),
          padding: EdgeInsets.zero,
        ),
        icon: MeloopIcon(icon, size: TempoSize.navigationIcon),
      );
}

class _BeatsSelect extends StatelessWidget {
  const _BeatsSelect({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.l10n.beatsPerBar,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: TempoColors.fieldFill,
        border: Border.all(color: TempoColors.fieldBorder),
        borderRadius: BorderRadius.circular(TempoRadius.field),
      ),
      child: Padding(
        padding: MetronomeTokens.fieldContentInset,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: MetronomeTokens.fieldHeight,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value,
              isExpanded: true,
              isDense: true,
              dropdownColor: TempoColors.paper,
              borderRadius: BorderRadius.circular(TempoRadius.field),
              style: MetronomeTokens.fieldValue.copyWith(
                color: TempoColors.ink,
              ),
              icon: const MeloopIcon(
                MeloopIcons.down,
                size: MetronomeTokens.selectIconSize,
                color: TempoColors.ink,
              ),
              items: [
                for (
                  var count = MetronomeUiLimits.minimumBeats;
                  count <= MetronomeUiLimits.maximumBeats;
                  count++
                )
                  DropdownMenuItem(
                    value: count,
                    child: Text(context.l10n.beats(count)),
                  ),
              ],
              onChanged: (next) {
                if (next != null) onChanged(next);
              },
            ),
          ),
        ),
      ),
    ),
  );
}
