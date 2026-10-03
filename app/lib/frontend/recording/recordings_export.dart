import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../components/meloop_ui.dart';
import '../practice_sessions/practice_session.dart';

enum RecordingExportDestination { share, saveFile }

enum RecordingExportResult { success, cancelled, failed, missingFile }

typedef RecordingExport = Future<RecordingExportResult> Function(
  PracticeSessionRecording recording,
  RecordingExportDestination destination,
);

/// Supply the Android share/file-picker adapter here when audio is implemented.
final recordingsExportProvider = Provider<RecordingExport?>((ref) => null);

Future<RecordingExportDestination?> showRecordingExportOptions(
  BuildContext context,
  PracticeSessionRecording recording,
) => showMeloopSheet<RecordingExportDestination>(
  context,
  title: context.l10n.exportRecording,
  child: Builder(
    builder: (sheetContext) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(recording.title, style: TempoType.title),
        const SizedBox(height: TempoSpace.md),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.share_outlined),
          title: Text(context.l10n.recordingShare),
          subtitle: Text(context.l10n.recordingShareDescription),
          onTap: () =>
              Navigator.of(sheetContext).pop(RecordingExportDestination.share),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const MeloopIcon(MeloopIcons.download),
          title: Text(context.l10n.recordingSaveFile),
          subtitle: Text(context.l10n.recordingSaveFileDescription),
          onTap: () =>
              Navigator.of(sheetContext)
                  .pop(RecordingExportDestination.saveFile),
        ),
        const SizedBox(height: TempoSpace.md),
        MeloopButton(
          label: context.l10n.cancel,
          style: MeloopButtonStyle.outline,
          onPressed: () => Navigator.of(sheetContext).pop(),
        ),
      ],
    ),
  ),
);
