import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../application/startup_controller.dart';
import '../components/meloop_ui.dart';
import '../recording/recordings_page.dart';
import 'practice_session.dart';
import 'practice_session_actions.dart';

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
    ),
  ),
);

/// Saved-session recordings have no capture action, even if a draft is active.
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
  // Retained for existing callers; a completed session cannot record again.
  final Future<void> Function()? onRecordPractice;

  @override
  ConsumerState<PracticeSessionRecordingsPage> createState() =>
      _RecordingsState();
}

class _RecordingsState extends ConsumerState<PracticeSessionRecordingsPage> {
  late PracticeSession _session = widget.session;

  @override
  Widget build(BuildContext context) {
    final shell = ref.watch(meloopShellControllerProvider);
    final profiles = shell.profiles.where(
      (profile) => profile.id == _session.profileId,
    );
    final instrument =
        profiles.firstOrNull?.instrument ?? MeloopInstrument.other;
    return RecordingsPage(
      title: context.l10n.sessionRecordingsTitle,
      recordings: _session.recordings,
      instrument: instrument,
      onBack: () => Navigator.of(context).pop(),
      onHome: widget.onHome,
      onDelete: (recording) async {
        final updated = await ref.read(practiceRecordingDeleteProvider)(
          _session,
          recording,
        );
        if (!mounted) return;
        setState(() => _session = updated);
        widget.onChanged(updated);
      },
    );
  }
}
