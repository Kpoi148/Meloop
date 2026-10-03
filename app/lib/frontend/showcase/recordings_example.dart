import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../application/startup_controller.dart';
import '../recording/recordings_page.dart';
import 'recordings_preview_library.dart';

/// Profile-scoped library preview. The supplied profile comes from app state.
class RecordingsExample extends ConsumerWidget {
  const RecordingsExample({
    super.key,
    required this.profile,
    required this.onHome,
    this.onRecordPractice,
  });

  final PreviewInstrumentProfile profile;
  final VoidCallback onHome;
  final Future<void> Function()? onRecordPractice;

  @override
  Widget build(BuildContext context, WidgetRef ref) => RecordingsPage(
    title: context.l10n.recordingsTool,
    recordings: ref.watch(recordingsPreviewListProvider(profile)),
    instrument: profile.instrument,
    onBack: () => Navigator.of(context).pop(),
    onHome: onHome,
    onRecordPractice: onRecordPractice,
    onDelete: (recording) async => ref
        .read(recordingsPreviewRemovedProvider.notifier)
        .remove(recording.id),
  );
}
