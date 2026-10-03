import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../components/meloop_ui.dart';
import '../practice/practice_duration.dart';
import 'recording_tokens.dart';
import 'recording_ui_state.dart';
import 'recording_visuals.dart';

/// UC-10's recorder composition. All data and commands belong to its caller.
class RecordingPage extends StatelessWidget {
  const RecordingPage({
    super.key,
    required this.title,
    required this.profileName,
    required this.state,
    required this.sessionRunning,
    required this.onBack,
    required this.onHome,
    required this.onStart,
    required this.onStop,
    required this.onKeep,
    required this.onDiscard,
    required this.onTogglePlayback,
    required this.onSeek,
    required this.onViewPro,
  });

  final String title, profileName;
  final RecordingUiState state;
  final bool sessionRunning;
  final VoidCallback onBack,
      onHome,
      onStart,
      onStop,
      onKeep,
      onDiscard,
      onTogglePlayback,
      onViewPro;
  final ValueChanged<Duration> onSeek;

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final recording = state.phase == RecordingPhase.recording;
    final review = state.phase == RecordingPhase.review;
    final status = review
        ? strings.recordingPending
        : recording
        ? strings.recordingActive(state.quota.maximumDuration.inMinutes)
        : state.microphone == RecordingMicrophone.ready
        ? strings.recordingReady(state.quota.maximumDuration.inMinutes)
        : strings.recordingMicrophoneOff(state.quota.maximumDuration.inMinutes);
    final issue = switch (state.issue) {
      RecordingIssue.microphoneDenied => strings.recordingMicrophoneDenied,
      RecordingIssue.microphoneUnavailable =>
        strings.recordingMicrophoneUnavailable,
      RecordingIssue.storageFull => strings.recordingStorageFull,
      RecordingIssue.audioBusy => strings.recordingAudioBusy,
      RecordingIssue.startFailed => strings.recordingStartFailed,
      RecordingIssue.saveFailed => strings.recordingSaveFailed,
      RecordingIssue.interrupted => strings.recordingInterrupted,
      RecordingIssue.durationLimit => strings.recordingDurationLimit(
        state.quota.maximumDuration.inMinutes,
      ),
      RecordingIssue.fileLimit => strings.recordingFileLimit(
        state.quota.maximumFiles ?? state.quota.savedFiles,
      ),
      null => null,
    };
    return MeloopPage(
      topBar: RecordingTopBar(onBack: onBack, onHome: onHome),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: RecordingTokens.introInset,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty ? strings.recordingDefaultTitle : title,
                  style: TempoType.heading,
                ),
                const SizedBox(height: RecordingTokens.subtitleGap),
                Text(profileName, style: RecordingTokens.subtitle),
              ],
            ),
          ),
          const RecordingArtwork(),
          MeloopCard(
            color: RecordingTokens.cardFill,
            padding: const EdgeInsets.all(RecordingTokens.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RecordingWaveform(active: recording),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    formatPracticeDuration(state.elapsed),
                    key: const Key('recording-elapsed'),
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: RecordingTokens.readout,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    TempoSpace.xs,
                    RecordingTokens.quotaGap,
                    TempoSpace.xs,
                    RecordingTokens.statusBottomGap,
                  ),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      status,
                      key: const Key('recording-status'),
                      textAlign: TextAlign.center,
                      style: RecordingTokens.status,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: RecordingTokens.recordButtonMargin,
            ),
            child: Center(
              child: SizedBox.square(
                dimension: RecordingTokens.recordButtonSize,
                child: IconButton(
                  key: const Key('recording-toggle'),
                  tooltip: recording
                      ? strings.recordingStop
                      : strings.recordingStart,
                  onPressed: recording
                      ? onStop
                      : review
                      ? onStart
                      : !sessionRunning || state.quota.full
                      ? null
                      : onStart,
                  style: IconButton.styleFrom(
                    backgroundColor: TempoColors.teal,
                    disabledBackgroundColor: TempoColors.teal.withValues(
                      alpha: .5,
                    ),
                    foregroundColor: TempoColors.white,
                    disabledForegroundColor: TempoColors.white,
                    shape: const CircleBorder(),
                  ),
                  icon: MeloopIcon(
                    recording ? MeloopIcons.stop : MeloopIcons.mic,
                    size: RecordingTokens.recordIconSize,
                    color: TempoColors.white,
                  ),
                ),
              ),
            ),
          ),
          if (review)
            Padding(
              padding: EdgeInsets.zero,
              child: MeloopCard(
                color: RecordingTokens.cardFill,
                padding: const EdgeInsets.all(RecordingTokens.cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      strings.recordingReviewTitle,
                      style: RecordingTokens.reviewTitle,
                    ),
                    RecordingPlayback(
                      state: state,
                      onToggle: onTogglePlayback,
                      onSeek: onSeek,
                    ),
                    MeloopResponsiveRow(
                      children: [
                        MeloopButton(
                          label: strings.recordingDiscard,
                          icon: MeloopIcons.trash,
                          style: MeloopButtonStyle.outline,
                          borderColor: RecordingTokens.outlineBorder,
                          onPressed: onDiscard,
                        ),
                        MeloopButton(
                          label: strings.recordingKeep,
                          icon: MeloopIcons.check,
                          onPressed: onKeep,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          if (issue != null ||
              (!sessionRunning && !review) ||
              (state.quota.full && !review))
            Padding(
              padding: const EdgeInsets.only(top: TempoSpace.md),
              child: MeloopNotice(
                message:
                    issue ??
                    (state.quota.full
                        ? strings.recordingFileLimit(state.quota.maximumFiles!)
                        : strings.recordingPracticePaused),
                kind:
                    state.issue == RecordingIssue.durationLimit ||
                        state.issue == RecordingIssue.interrupted ||
                        state.issue == null
                    ? MeloopNoticeKind.info
                    : MeloopNoticeKind.error,
              ),
            ),
          Padding(
            padding: review || issue != null
                ? RecordingTokens.footnoteMargin
                : RecordingTokens.footnoteMargin.copyWith(top: 0),
            child: Text(
              strings.recordingFootnote,
              textAlign: TextAlign.center,
              style: RecordingTokens.footnote,
            ),
          ),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: TempoSpace.md,
            children: [
              Text(
                state.quota.isPro
                    ? strings.recordingProQuota(
                        state.quota.maximumDuration.inMinutes,
                      )
                    : strings.recordingFreeQuota(
                        state.quota.savedFiles,
                        state.quota.maximumFiles!,
                      ),
                style: RecordingTokens.footnote,
              ),
              if (!state.quota.isPro)
                TextButton(
                  onPressed: onViewPro,
                  style: TextButton.styleFrom(
                    textStyle: RecordingTokens.footnote,
                  ),
                  child: Text(strings.recordingViewPro),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
