import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../components/meloop_ui.dart';
import '../recording/recording_tokens.dart';
import '../recording/recordings_tokens.dart';
import '../recording/recording_visuals.dart';
import 'practice_session.dart';
import 'practice_session_actions.dart';
import 'practice_session_copy.dart';
import 'practice_session_delete_dialog.dart';

Future<void> showPracticeSessionRecordings(
  BuildContext context, {
  required PracticeSession session,
  required ValueChanged<PracticeSession> onChanged,
  VoidCallback? onHome,
  Future<void> Function(BuildContext)? onOpenRecording,
}) => Navigator.of(context).push<void>(
  MaterialPageRoute(
    builder: (recordingsContext) => PracticeSessionRecordingsPage(
      session: session,
      onChanged: onChanged,
      onHome:
          onHome ??
          () =>
              Navigator.of(recordingsContext)
                  .popUntil((route) => route.isFirst),
      onRecordPractice: onOpenRecording == null
          ? null
          : () => onOpenRecording(recordingsContext),
    ),
  ),
);

class PracticeSessionRecordingsPage extends ConsumerStatefulWidget {
  const PracticeSessionRecordingsPage({
    super.key,
    required this.session,
    required this.onChanged,
    required this.onHome,
    this.onRecordPractice,
  });
  final PracticeSession session;
  final ValueChanged<PracticeSession> onChanged;
  final VoidCallback onHome;
  final Future<void> Function()? onRecordPractice;
  @override
  ConsumerState<PracticeSessionRecordingsPage> createState() =>
      _RecordingsState();
}

class _RecordingsState extends ConsumerState<PracticeSessionRecordingsPage> {
  late PracticeSession _session = widget.session;
  bool _busy = false;
  Future<void> _delete(PracticeSessionRecording recording) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await showPracticeSessionDeleteConfirm(
        context,
        recording: true,
        onDelete: () async {
          final updated = await ref.read(practiceRecordingDeleteProvider)(
            _session,
            recording,
          );
          if (!mounted) return;
          setState(() => _session = updated);
          widget.onChanged(updated);
        },
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _audioAction(
    PracticeRecordingAction action,
    PracticeSessionRecording recording,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action(recording);
    } catch (_) {
      if (mounted) {
        MeloopNotifications.show(context, context.l10n.recordingActionFailed);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final play = ref.watch(practiceRecordingPlayProvider);
    final export = ref.watch(practiceRecordingExportProvider);
    return MeloopPage(
      topBar: RecordingTopBar(
        title: strings.sessionRecordingsTitle,
        onBack: () => Navigator.of(context).pop(),
        onHome: widget.onHome,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _RecordingsIntro(),
          if (_session.recordingCount == 0)
            CustomPaint(
              painter: const _EmptyRecordingsBorder(),
              child: Padding(
                padding: RecordingsTokens.emptyPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      strings.noSessionRecordings,
                      textAlign: TextAlign.center,
                      style: TempoType.title,
                    ),
                    const SizedBox(height: RecordingsTokens.emptyMessageTop),
                    Text(
                      strings.sessionRecordingsEmptyMessage,
                      textAlign: TextAlign.center,
                      style: RecordingTokens.emptyDescription,
                    ),
                    const SizedBox(height: RecordingsTokens.emptyMessageBottom),
                  ],
                ),
              ),
            ),
          for (final recording in _session.recordings)
            Padding(
              padding: const EdgeInsets.only(bottom: TempoSpace.md),
              child: MeloopCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(recording.title, style: TempoType.title),
                    const SizedBox(height: TempoSpace.sm),
                    Text(
                      draftDuration(recording.duration.inSeconds),
                      style: TempoType.caption.copyWith(
                        color: TempoColors.muted,
                      ),
                    ),
                    const SizedBox(height: TempoSpace.md),
                    Wrap(
                      spacing: TempoSpace.sm,
                      children: [
                        IconButton(
                          tooltip: strings.listenRecording,
                          onPressed: _busy || !recording.canPlay || play == null
                              ? null
                              : () => _audioAction(play, recording),
                          icon: const MeloopIcon(MeloopIcons.play),
                        ),
                        IconButton(
                          tooltip: strings.exportRecording,
                          onPressed:
                              _busy || !recording.canExport || export == null
                              ? null
                              : () => _audioAction(export, recording),
                          icon: const MeloopIcon(MeloopIcons.download),
                        ),
                        IconButton(
                          tooltip: strings.deleteRecording,
                          onPressed: _busy || !recording.canDelete
                              ? null
                              : () => _delete(recording),
                          icon: const MeloopIcon(MeloopIcons.trash),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          MeloopButton(
            label: strings.recordPracticeSession,
            icon: MeloopIcons.mic,
            iconGap: RecordingTokens.createIconGap,
            style: MeloopButtonStyle.outline,
            borderColor: RecordingTokens.outlineBorder,
            onPressed: _busy ? null : widget.onRecordPractice,
          ),
          Padding(
            padding: RecordingTokens.footnoteMargin,
            child: Text(
              strings.sessionRecordingsDeleteHint,
              textAlign: TextAlign.center,
              style: RecordingTokens.footnote,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordingsIntro extends StatelessWidget {
  const _RecordingsIntro();

  @override
  Widget build(BuildContext context) => Padding(
    padding: RecordingTokens.introInset,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final largeText = MediaQuery.textScalerOf(context).scale(16) > 20;
        final art = Opacity(
          opacity: RecordingsTokens.artworkOpacity,
          child: const MeloopArt.tool(
            MeloopTool.recordings,
            size: RecordingsTokens.artworkSize,
          ),
        );
        final copy = Padding(
          padding: const EdgeInsets.only(top: RecordingsTokens.introTopPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: largeText
                    ? constraints.maxWidth
                    : constraints.maxWidth *
                          RecordingsTokens.headingWidthFactor,
                child: Text(
                  context.l10n.sessionRecordingsHeading,
                  style: RecordingsTokens.heading,
                ),
              ),
              const SizedBox(height: RecordingTokens.subtitleGap),
              SizedBox(
                width: largeText
                    ? constraints.maxWidth
                    : constraints.maxWidth *
                          RecordingsTokens.subtitleWidthFactor,
                child: Text(
                  context.l10n.sessionRecordingsSubtitle,
                  style: RecordingTokens.subtitle,
                ),
              ),
            ],
          ),
        );
        if (largeText) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              copy,
              Align(alignment: Alignment.centerRight, child: art),
            ],
          );
        }
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              right: RecordingsTokens.artworkRight,
              top: RecordingsTokens.artworkTop,
              child: art,
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: RecordingsTokens.introHeight,
              ),
              child: copy,
            ),
          ],
        );
      },
    ),
  );
}

class _EmptyRecordingsBorder extends CustomPainter {
  const _EmptyRecordingsBorder();

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
  bool shouldRepaint(_EmptyRecordingsBorder oldDelegate) => false;
}
