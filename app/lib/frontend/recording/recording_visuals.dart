import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../components/meloop_ui.dart';
import '../practice/practice_duration.dart';
import 'recording_tokens.dart';
import 'recording_ui_state.dart';

class RecordingTopBar extends StatelessWidget {
  const RecordingTopBar({
    super.key,
    this.title,
    required this.onBack,
    required this.onHome,
  });
  final VoidCallback onBack, onHome;
  final String? title;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: RecordingTokens.topBarHeight),
    child: Row(
      children: [
        _action(context.l10n.back, MeloopIcons.back, onBack),
        Expanded(
          child: Text(
            title ?? context.l10n.recordingTitle,
            textAlign: TextAlign.center,
            style: RecordingTokens.topBarTitle,
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
          minimumSize: const Size.square(RecordingTokens.topBarButtonSize),
          fixedSize: const Size.square(RecordingTokens.topBarButtonSize),
          padding: EdgeInsets.zero,
        ),
        icon: MeloopIcon(icon, size: TempoSize.navigationIcon),
      );
}

class RecordingArtwork extends StatelessWidget {
  const RecordingArtwork({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox(
    height: RecordingTokens.heroHeight,
    child: ClipRect(
      child: OverflowBox(
        alignment: Alignment.topCenter,
        minWidth: RecordingTokens.artworkSize,
        maxWidth: RecordingTokens.artworkSize,
        minHeight: RecordingTokens.artworkSize,
        maxHeight: RecordingTokens.artworkSize,
        child: ClipRect(
          clipper: _RecorderSpriteClipper(),
          child: MeloopArt.tool(
            MeloopTool.recorder,
            size: RecordingTokens.artworkSize,
          ),
        ),
      ),
    ),
  );
}

/// Excludes adjacent sprite texels sampled at the right edge by Flutter.
class _RecorderSpriteClipper extends CustomClipper<Rect> {
  const _RecorderSpriteClipper();

  @override
  Rect getClip(Size size) => Rect.fromLTRB(
    RecordingTokens.artworkEdgeInset,
    0,
    size.width - RecordingTokens.artworkEdgeInset,
    size.height,
  );

  @override
  bool shouldReclip(_RecorderSpriteClipper oldClipper) => false;
}

class RecordingWaveform extends StatefulWidget {
  const RecordingWaveform({super.key, required this.active});
  final bool active;

  @override
  State<RecordingWaveform> createState() => _RecordingWaveformState();
}

class _RecordingWaveformState extends State<RecordingWaveform>
    with SingleTickerProviderStateMixin {
  late final _animation = AnimationController(
    vsync: this,
    duration: RecordingTokens.waveformCycle,
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _animation.repeat();
  }

  @override
  void didUpdateWidget(RecordingWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active == widget.active) return;
    if (widget.active) {
      _animation.repeat();
    } else {
      _animation.stop();
      _animation.value = 0;
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Padding(
      padding: const EdgeInsets.symmetric(
        vertical: RecordingTokens.waveformMargin,
      ),
      child: SizedBox(
        height: RecordingTokens.waveformHeight,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (_, _) => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: RecordingTokens.waveformBarGap,
              children: [
                for (
                  var index = 0;
                  index < RecordingTokens.waveformBars;
                  index++
                )
                  Container(
                    width: RecordingTokens.waveformBarWidth,
                    height:
                        RecordingTokens.waveformBaseHeight +
                        (math.sin(
                                  index * RecordingTokens.waveformPhase +
                                      (widget.active &&
                                              !MediaQuery.disableAnimationsOf(
                                                context,
                                              )
                                          ? _animation.value * math.pi * 2
                                          : 0),
                                ) +
                                1) *
                            RecordingTokens.waveformHeightRange,
                    decoration: BoxDecoration(
                      color: RecordingTokens.waveformColor,
                      borderRadius: BorderRadius.circular(
                        RecordingTokens.waveformBarRadius,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Native-audio styling from the HTML review; playback data is supplied by caller.
class RecordingPlayback extends StatefulWidget {
  const RecordingPlayback({
    super.key,
    required this.state,
    required this.onToggle,
    required this.onSeek,
  });
  final RecordingUiState state;
  final VoidCallback onToggle;
  final ValueChanged<Duration> onSeek;

  @override
  State<RecordingPlayback> createState() => _RecordingPlaybackState();
}

class _RecordingPlaybackState extends State<RecordingPlayback> {
  bool _muted = false;
  RecordingUiState get state => widget.state;

  String _audioTime(Duration value) =>
      '${value.inMinutes}:'
      '${(value.inSeconds % Duration.secondsPerMinute).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(
      vertical: RecordingTokens.playbackMargin,
    ),
    padding: const EdgeInsets.symmetric(horizontal: TempoSpace.xs),
    decoration: BoxDecoration(
      color: RecordingTokens.playbackFill,
      borderRadius: BorderRadius.circular(TempoRadius.pill),
    ),
    child: ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: RecordingTokens.playbackHeight,
      ),
      child: MediaQuery.textScalerOf(context).scale(16) > 20
          ? Column(
              children: [_controls(context, largeText: true), _slider(context)],
            )
          : _controls(context),
    ),
  );

  Widget _controls(BuildContext context, {bool largeText = false}) => Row(
    children: [
      IconButton(
        tooltip: state.playing
            ? context.l10n.recordingPausePlayback
            : context.l10n.listenRecording,
        onPressed: state.elapsed == Duration.zero ? null : widget.onToggle,
        style: IconButton.styleFrom(
          minimumSize: const Size.square(RecordingTokens.playbackPlaySize),
          fixedSize: const Size.square(RecordingTokens.playbackPlaySize),
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: MeloopIcon(
          state.playing ? MeloopIcons.pause : MeloopIcons.play,
          size: TempoSize.smallIcon,
          color: RecordingTokens.playbackInk,
        ),
      ),
      Flexible(
        flex: largeText ? 1 : 0,
        child: Text(
          '${_audioTime(state.playbackPosition)} / ${_audioTime(state.elapsed)}',
          style: TempoType.caption.copyWith(
            fontSize: 13,
            color: RecordingTokens.playbackInk,
          ),
        ),
      ),
      if (!largeText) Expanded(child: _slider(context)),
      IconButton(
        tooltip: _muted
            ? context.l10n.recordingUnmute
            : context.l10n.recordingMute,
        onPressed: () => setState(() => _muted = !_muted),
        style: _controlStyle,
        icon: Opacity(
          opacity: _muted ? .4 : 1,
          child: const MeloopIcon(
            MeloopIcons.volume,
            size: TempoSize.smallIcon,
            color: RecordingTokens.playbackInk,
          ),
        ),
      ),
      PopupMenuButton<void>(
        tooltip: context.l10n.recordingPlaybackOptions,
        constraints: const BoxConstraints(minWidth: TempoSize.touchTarget),
        padding: const EdgeInsets.all(TempoSpace.xs),
        icon: Transform.rotate(
          angle: math.pi / 2,
          child: const MeloopIcon(
            MeloopIcons.more,
            size: TempoSize.smallIcon,
            color: RecordingTokens.playbackInk,
          ),
        ),
        itemBuilder: (_) => [
          PopupMenuItem<void>(
            onTap: () => widget.onSeek(Duration.zero),
            child: Text(context.l10n.recordingRestartPlayback),
          ),
        ],
      ),
    ],
  );

  ButtonStyle get _controlStyle => IconButton.styleFrom(
    minimumSize: const Size.square(RecordingTokens.playbackControlSize),
    fixedSize: const Size.square(RecordingTokens.playbackControlSize),
    padding: EdgeInsets.zero,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );

  Widget _slider(BuildContext context) => SliderTheme(
    data: SliderTheme.of(context).copyWith(
      trackHeight: RecordingTokens.playbackTrackHeight,
      activeTrackColor: RecordingTokens.playbackInk,
      inactiveTrackColor: RecordingTokens.playbackInactiveTrack,
      thumbColor: RecordingTokens.playbackInk,
      thumbShape: RoundSliderThumbShape(
        enabledThumbRadius:
            state.playing || state.playbackPosition != Duration.zero
            ? RecordingTokens.playbackThumbRadius
            : 0,
      ),
      overlayShape: SliderComponentShape.noOverlay,
      padding: const EdgeInsets.symmetric(horizontal: TempoSpace.sm),
    ),
    child: Slider(
      value: state.playbackPosition.inMilliseconds.toDouble().clamp(
        0,
        state.elapsed.inMilliseconds.toDouble(),
      ),
      max: math.max(1, state.elapsed.inMilliseconds).toDouble(),
      semanticFormatterCallback: (value) =>
          formatPracticeDuration(Duration(milliseconds: value.round())),
      onChanged: state.elapsed == Duration.zero
          ? null
          : (value) => widget.onSeek(Duration(milliseconds: value.round())),
    ),
  );
}
