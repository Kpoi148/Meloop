import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../components/meloop_ui.dart';
import '../practice_sessions/practice_session.dart';
import '../practice_sessions/practice_session_copy.dart';
import '../practice_sessions/practice_session_delete_dialog.dart';
import '../showcase/recordings_playback_preview.dart';
import '../showcase/recordings_preview_library.dart';
import 'recording_tokens.dart';
import 'recording_track_player.dart';
import 'recording_visuals.dart';
import 'recordings_export.dart';
import 'recordings_tokens.dart';
import 'recordings_visuals.dart';

class RecordingsPage extends ConsumerStatefulWidget {
  const RecordingsPage({
    super.key,
    required this.title,
    required this.recordings,
    required this.instrument,
    required this.onBack,
    required this.onHome,
    required this.onDelete,
    this.onRecordPractice,
  });

  final String title;
  final List<PracticeSessionRecording> recordings;
  final MeloopInstrument instrument;
  final VoidCallback onBack, onHome;
  final Future<void> Function(PracticeSessionRecording) onDelete;
  final Future<void> Function()? onRecordPractice;

  @override
  ConsumerState<RecordingsPage> createState() => _RecordingsPageState();
}

class _RecordingsPageState extends ConsumerState<RecordingsPage>
    with WidgetsBindingObserver {
  bool _busy = false;
  final _missingFiles = <String>{};
  late final RecordingsPlaybackPreview _playback;

  @override
  void initState() {
    super.initState();
    _playback = ref.read(recordingsPlaybackPreviewProvider.notifier);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(RecordingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentId = ref.read(recordingsPlaybackPreviewProvider).recordingId;
    if (currentId != null &&
        !widget.recordings.any(
          (item) => item.id == currentId && item.fileAvailable,
        )) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _playback.remove(currentId);
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _playback.pause();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _playback.closePreview();
    super.dispose();
  }

  void _leave(VoidCallback action) {
    _playback.pause();
    action();
  }

  Future<void> _delete(PracticeSessionRecording recording) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final deleted = await showPracticeSessionDeleteConfirm(
        context,
        recording: true,
        onDelete: () async {
          _playback.remove(recording.id);
          await widget.onDelete(recording);
          ref
              .read(recordingsPreviewRemovedProvider.notifier)
              .remove(recording.id);
        },
      );
      if (mounted && deleted) {
        MeloopNotifications.show(context, context.l10n.recordingDeleted);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _export(PracticeSessionRecording recording) async {
    if (_busy) return;
    setState(() => _busy = true);
    _playback.pause();
    try {
      final destination = await showRecordingExportOptions(context, recording);
      if (!mounted || destination == null) return;
      final export = ref.read(recordingsExportProvider);
      // The UI preview has no platform export adapter; dismiss without a
      // success notification. Cancel and success are never conflated.
      if (export == null) return;
      RecordingExportResult result;
      try {
        result = await export(recording, destination);
      } catch (_) {
        result = RecordingExportResult.failed;
      }
      if (!mounted || result == RecordingExportResult.cancelled) return;
      if (result == RecordingExportResult.missingFile) {
        _playback.remove(recording.id);
        setState(() => _missingFiles.add(recording.id));
      }
      MeloopNotifications.show(context, switch (result) {
        RecordingExportResult.success => context.l10n.recordingExported,
        RecordingExportResult.missingFile =>
          context.l10n.recordingMissingMessage,
        _ => context.l10n.recordingExportFailed,
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final playback = ref.watch(recordingsPlaybackPreviewProvider);
    final removed = ref.watch(recordingsPreviewRemovedProvider);
    final recordings = widget.recordings
        .where((item) => !removed.contains(item.id))
        .map(
          (item) => _missingFiles.contains(item.id)
              ? item.withFileAvailable(false)
              : item,
        )
        .toList();
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _playback.closePreview();
      },
      child: MeloopPage(
        padding: RecordingsTokens.pagePadding,
        topBarGap: RecordingsTokens.topBarGap,
        topBar: RecordingTopBar(
          title: widget.title,
          onBack: () => _leave(widget.onBack),
          onHome: () => _leave(widget.onHome),
        ),
        bottomNavigation: widget.onRecordPractice == null
            ? null
            : _RecordingsFooter(
                onRecordPractice: _busy
                    ? null
                    : () async {
                        _playback.pause();
                        await widget.onRecordPractice!();
                      },
              ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const RecordingsIntro(),
            if (recordings.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: RecordingsTokens.emptyTop),
                child: CustomPaint(
                  painter: const EmptyRecordingsBorder(),
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
                        const SizedBox(
                          height: RecordingsTokens.emptyMessageTop,
                        ),
                        Text(
                          strings.sessionRecordingsEmptyMessage,
                          textAlign: TextAlign.center,
                          style: RecordingTokens.emptyDescription,
                        ),
                        const SizedBox(
                          height: RecordingsTokens.emptyMessageBottom,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            for (final recording in recordings)
              _RecordingCard(
                key: ValueKey(recording.id),
                recording: recording,
                instrument: widget.instrument,
                playback: playback,
                onToggle: () => _playback.toggle(recording),
                onSeek: (value) => _playback.seek(recording, value),
                onMute: _playback.toggleMute,
                onExport:
                    _busy || !recording.fileAvailable || !recording.canExport
                    ? null
                    : () => _export(recording),
                onDelete: _busy || !recording.canDelete
                    ? null
                    : () => _delete(recording),
              ),
            if (widget.onRecordPractice == null)
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
      ),
    );
  }
}

class _RecordingsFooter extends StatelessWidget {
  const _RecordingsFooter({required this.onRecordPractice});

  final Future<void> Function()? onRecordPractice;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: TempoColors.paper,
    child: SafeArea(
      top: false,
      child: Align(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: TempoSize.contentMaxWidth,
          ),
          child: Padding(
            padding: RecordingsTokens.footerInset,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MeloopButton(
                  label: context.l10n.recordPracticeSession,
                  icon: MeloopIcons.mic,
                  iconGap: RecordingTokens.createIconGap,
                  style: MeloopButtonStyle.outline,
                  borderColor: RecordingTokens.outlineBorder,
                  onPressed: onRecordPractice,
                ),
                const SizedBox(height: RecordingsTokens.footerHintGap),
                Text(
                  context.l10n.sessionRecordingsDeleteHint,
                  textAlign: TextAlign.center,
                  style: RecordingTokens.footnote,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _RecordingCard extends StatelessWidget {
  const _RecordingCard({
    super.key,
    required this.recording,
    required this.instrument,
    required this.playback,
    required this.onToggle,
    required this.onSeek,
    required this.onMute,
    required this.onExport,
    required this.onDelete,
  });

  final PracticeSessionRecording recording;
  final MeloopInstrument instrument;
  final RecordingsPlaybackState playback;
  final VoidCallback onToggle, onMute;
  final ValueChanged<Duration> onSeek;
  final VoidCallback? onExport, onDelete;

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final status = !recording.fileAvailable
        ? strings.recordingMissingFile
        : recording.linkedToJournal
        ? strings.recordingLinked
        : strings.recordingUnlinked;
    return Container(
      margin: const EdgeInsets.only(bottom: RecordingsTokens.cardGap),
      padding: const EdgeInsets.all(RecordingsTokens.cardPadding),
      decoration: BoxDecoration(
        color: RecordingsTokens.cardFill,
        border: Border.all(color: TempoColors.line),
        borderRadius: BorderRadius.circular(RecordingsTokens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(TempoRadius.field),
                child: ColoredBox(
                  color: RecordingsTokens.instrumentFill,
                  child: MeloopArt.instrument(
                    instrument,
                    size: RecordingsTokens.instrumentSize,
                    filterQuality: FilterQuality.high,
                    backgroundColor: RecordingsTokens.instrumentFill,
                  ),
                ),
              ),
              const SizedBox(width: TempoSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(recording.title, style: RecordingsTokens.cardTitle),
                    const SizedBox(height: RecordingsTokens.metadataGap),
                    Text(
                      strings.recordingMetadata(
                        draftDuration(recording.duration.inSeconds),
                        status,
                      ),
                      style: RecordingsTokens.metadata,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: RecordingsTokens.playerGap),
          if (recording.fileAvailable)
            RecordingTrackPlayer(
              recording: recording,
              playback: playback,
              onToggle: onToggle,
              onSeek: onSeek,
              onMute: onMute,
            )
          else
            Text(
              strings.recordingMissingMessage,
              style: RecordingsTokens.metadata,
            ),
          const SizedBox(height: RecordingsTokens.actionsTop),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: RecordingsTokens.actionGap,
            children: [
              _action(
                strings.exportRecording,
                strings.exportRecording,
                MeloopIcons.download,
                onExport,
                underline: true,
              ),
              _action(
                strings.recordingDeleteAction,
                strings.deleteRecording,
                MeloopIcons.trash,
                onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _action(
    String label,
    String tooltip,
    MeloopIcons icon,
    VoidCallback? callback, {
    bool underline = false,
  }) => Tooltip(
    message: tooltip,
    child: TextButton(
      onPressed: callback,
      style: TextButton.styleFrom(
        minimumSize: const Size(0, RecordingsTokens.actionHeight),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: RecordingsTokens.action,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MeloopIcon(
            icon,
            size: RecordingsTokens.actionIconSize,
            color: callback == null ? TempoColors.muted : TempoColors.ink,
          ),
          const SizedBox(width: RecordingsTokens.actionIconGap),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                decoration: underline ? TextDecoration.underline : null,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
