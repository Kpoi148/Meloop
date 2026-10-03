import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../application/app_settings_controller.dart';
import '../application/startup_controller.dart';
import '../practice_sessions/practice_session.dart';
import 'practice_session_examples.dart';

/// Temporary UC-11–13 content and removals, isolated from journal/file storage.
abstract final class RecordingsPreviewLibrary {
  static const initialFileCount = 3;

  static List<PracticeSessionRecording> examples(
    AppLocalizations strings,
    PreviewInstrumentProfile profile,
    DateTime now,
  ) => [
    ...practiceSessionExamples(strings, profile, now).first.recordings,
    PracticeSessionRecording(
      id: '${profile.id}:melody-recording',
      title: strings.recordingMelodyTitle,
      duration: const Duration(seconds: 36),
      linkedToJournal: false,
    ),
  ];
}

final recordingsPreviewRemovedProvider =
    NotifierProvider<RecordingsPreviewRemoved, Set<String>>(
      RecordingsPreviewRemoved.new,
    );

class RecordingsPreviewRemoved extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void remove(String id) => state = Set.unmodifiable({...state, id});
}

final recordingsPreviewListProvider = Provider.autoDispose
    .family<List<PracticeSessionRecording>, PreviewInstrumentProfile>((
      ref,
      profile,
    ) {
      final locale = ref.watch(appLocaleProvider).value ?? const Locale('vi');
      final strings = lookupAppLocalizations(locale);
      final removed = ref.watch(recordingsPreviewRemovedProvider);
      final now = ref.watch(practiceSessionsClockProvider)();
      return List.unmodifiable(
        RecordingsPreviewLibrary.examples(
          strings,
          profile,
          now,
        ).where((recording) => !removed.contains(recording.id)),
      );
    });
