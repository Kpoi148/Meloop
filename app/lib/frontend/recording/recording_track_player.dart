import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../components/meloop_ui.dart';
import '../practice/practice_duration.dart';
import '../practice_sessions/practice_session.dart';
import '../showcase/recordings_playback_preview.dart';
import 'recording_tokens.dart';
import 'recordings_tokens.dart';

/// Compact controls matching the prototype's native audio element.
class RecordingTrackPlayer extends StatelessWidget {
  const RecordingTrackPlayer({
    super.key,
    required this.recording,
    required this.playback,
    required this.onToggle,
    required this.onSeek,
    required this.onMute,
  });

  final PracticeSessionRecording recording;
  final RecordingsPlaybackState playback;
  final VoidCallback onToggle, onMute;
  final ValueChanged<Duration> onSeek;

  bool get _selected => playback.recordingId == recording.id;
  Duration get _position => _selected ? playback.position : Duration.zero;
  bool get _playing => _selected && playback.playing;
  bool get _enabled =>
      recording.fileAvailable &&
      recording.canPlay &&
      recording.duration > Duration.zero;

  String _time(Duration duration) =>
      '${duration.inMinutes}:'
      '${(duration.inSeconds % Duration.secondsPerMinute).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final largeText =
        MediaQuery.textScalerOf(context).scale(16) >
        RecordingsTokens.compactTextThreshold;
    final controls = Row(
      children: [
        IconButton(
          tooltip: _playing
              ? context.l10n.recordingPausePlayback
              : context.l10n.listenRecording,
          onPressed: _enabled ? onToggle : null,
          style: _controlStyle,
          icon: MeloopIcon(
            _playing ? MeloopIcons.pause : MeloopIcons.play,
            size: RecordingsTokens.actionIconSize,
            color: RecordingTokens.playbackInk,
          ),
        ),
        Flexible(
          flex: largeText ? 1 : 0,
          child: Text(
            '${_time(_position)} / ${_time(recording.duration)}',
            style: RecordingsTokens.playerTime,
          ),
        ),
        if (!largeText) Expanded(child: _slider(context)),
        IconButton(
          tooltip: playback.muted
              ? context.l10n.recordingUnmute
              : context.l10n.recordingMute,
          onPressed: _enabled ? onMute : null,
          style: IconButton.styleFrom(
            minimumSize: const Size(
              RecordingsTokens.playerVolumeSize,
              RecordingsTokens.playerHeight,
            ),
            fixedSize: const Size(
              RecordingsTokens.playerVolumeSize,
              RecordingsTokens.playerHeight,
            ),
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          icon: Icon(
            playback.muted ? Icons.volume_off : Icons.volume_up,
            size: TempoSize.smallIcon,
            color: RecordingTokens.playbackInk,
          ),
        ),
        SizedBox.square(
          dimension: RecordingsTokens.playerControlSize,
          child: PopupMenuButton<void>(
            tooltip: context.l10n.recordingPlaybackOptions,
            enabled: _enabled,
            padding: EdgeInsets.zero,
            icon: const Icon(
              Icons.more_vert,
              size: RecordingsTokens.actionIconSize,
              color: RecordingTokens.playbackInk,
            ),
            itemBuilder: (_) => [
              PopupMenuItem<void>(
                onTap: () => onSeek(Duration.zero),
                child: Text(context.l10n.recordingRestartPlayback),
              ),
            ],
          ),
        ),
      ],
    );
    return Container(
      constraints: const BoxConstraints(
        minHeight: RecordingsTokens.playerHeight,
      ),
      decoration: BoxDecoration(
        color: RecordingTokens.playbackFill,
        borderRadius: BorderRadius.circular(TempoRadius.pill),
      ),
      padding: RecordingsTokens.playerPadding,
      child: largeText
          ? Column(children: [controls, _slider(context)])
          : controls,
    );
  }

  ButtonStyle get _controlStyle => IconButton.styleFrom(
    minimumSize: const Size(
      RecordingsTokens.playerControlSize,
      RecordingsTokens.playerHeight,
    ),
    fixedSize: const Size(
      RecordingsTokens.playerControlSize,
      RecordingsTokens.playerHeight,
    ),
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
        enabledThumbRadius: _playing || _position != Duration.zero
            ? RecordingTokens.playbackThumbRadius
            : 0,
      ),
      overlayShape: SliderComponentShape.noOverlay,
      padding: const EdgeInsets.symmetric(
        horizontal: RecordingsTokens.playerTrackMargin,
      ),
    ),
    child: Slider(
      value: _position.inMilliseconds.toDouble().clamp(
        0,
        recording.duration.inMilliseconds.toDouble(),
      ),
      max: math.max(1, recording.duration.inMilliseconds).toDouble(),
      semanticFormatterCallback: (value) =>
          formatPracticeDuration(Duration(milliseconds: value.round())),
      onChanged: _enabled
          ? (value) => onSeek(Duration(milliseconds: value.round()))
          : null,
    ),
  );
}
