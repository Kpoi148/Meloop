import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../components/meloop_ui.dart';
import 'practice_session.dart';
import 'practice_session_actions.dart';
import 'practice_session_copy.dart';
import 'practice_session_delete_dialog.dart';

Future<void> showPracticeSessionRecordings(
  BuildContext context, {
  required PracticeSession session,
  required ValueChanged<PracticeSession> onChanged,
}) => showMeloopSheet<void>(
  context,
  title: context.l10n.practiceSessionRecordings,
  child: _Recordings(session: session, onChanged: onChanged),
);

class _Recordings extends ConsumerStatefulWidget {
  const _Recordings({required this.session, required this.onChanged});
  final PracticeSession session;
  final ValueChanged<PracticeSession> onChanged;
  @override
  ConsumerState<_Recordings> createState() => _RecordingsState();
}

class _RecordingsState extends ConsumerState<_Recordings> {
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: TempoSpace.md,
      children: [
        Text(
          strings.practiceRecordingCount(_session.recordingCount),
          style: TempoType.caption.copyWith(color: TempoColors.muted),
        ),
        if (_session.recordingCount == 0)
          MeloopStateView(
            state: MeloopViewState.empty,
            title: strings.noSessionRecordings,
            message: strings.noSessionRecordingsMessage,
          ),
        for (final recording in _session.recordings)
          MeloopCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(recording.title, style: TempoType.title),
                const SizedBox(height: TempoSpace.sm),
                Text(
                  draftDuration(recording.duration.inSeconds),
                  style: TempoType.caption.copyWith(color: TempoColors.muted),
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
                      onPressed: _busy || !recording.canExport || export == null
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
      ],
    );
  }
}
