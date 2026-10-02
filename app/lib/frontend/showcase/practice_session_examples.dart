import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../application/app_settings_controller.dart';
import '../application/startup_controller.dart';
import '../components/layout/meloop_art.dart';
import '../practice_sessions/practice_session.dart';
import '../application/session_form_values.dart';

/// Temporary, memory-only content for reviewing UC-06 before storage is wired.
final practiceSessionsPreviewLoaderProvider = Provider<PracticeSessionsLoader>((
  ref,
) {
  final locale = ref.watch(appLocaleProvider).value ?? const Locale('vi');
  final strings = lookupAppLocalizations(locale);
  final clock = ref.watch(practiceSessionsClockProvider);
  final changes = ref.watch(practiceSessionPreviewChangesProvider);
  return (profile) async => List.unmodifiable([
    for (final session in practiceSessionExamples(strings, profile, clock()))
      if (!changes.containsKey(session.id) || changes[session.id] != null)
        changes[session.id] ?? session,
  ]);
});

/// Only the showcase owns these transient edits; no journal data is written.
final practiceSessionPreviewChangesProvider =
    NotifierProvider<
      PracticeSessionPreviewChanges,
      Map<String, PracticeSession?>
    >(PracticeSessionPreviewChanges.new);

class PracticeSessionPreviewChanges
    extends Notifier<Map<String, PracticeSession?>> {
  @override
  Map<String, PracticeSession?> build() => const {};

  Future<PracticeSession> update(
    PracticeSession session,
    SessionFormValues values,
  ) async {
    final updated = PracticeSession(
      id: session.id,
      profileId: session.profileId,
      date: values.date,
      title: values.title,
      duration: Duration(seconds: values.durationSeconds),
      practiced: values.practiced,
      difficulty: values.difficulty,
      nextPractice: values.next,
      mood: values.mood,
      focus: values.focus,
      bpm: values.bpm,
      recordingCount: session.recordingCount,
      recordings: session.recordings,
    );
    state = {...state, session.id: updated};
    return updated;
  }

  Future<void> delete(PracticeSession session) async {
    state = {...state, session.id: null};
  }

  Future<PracticeSession> deleteRecording(
    PracticeSession session,
    PracticeSessionRecording recording,
  ) async {
    final updated = session.withRecordings(
      session.recordings.where((item) => item.id != recording.id).toList(),
    );
    state = {...state, session.id: updated};
    return updated;
  }
}

List<PracticeSession> practiceSessionExamples(
  AppLocalizations strings,
  PreviewInstrumentProfile profile,
  DateTime now,
) {
  final titles = [
    strings.sampleSessionTitle,
    strings.practiceSampleRhythm,
    strings.practiceSampleSong,
    strings.practiceSampleMinorScale,
    strings.practiceSampleTechnique,
    strings.practiceSampleReview,
    strings.practiceSampleSlowPractice,
  ];
  const samples = [
    (daysAgo: 0, minutes: 35, mood: 5, focus: 4, recordings: 2),
    (daysAgo: 0, minutes: 18, mood: 4, focus: 3, recordings: 0),
    (daysAgo: 1, minutes: 25, mood: 4, focus: 4, recordings: 1),
    (daysAgo: 3, minutes: 30, mood: 3, focus: 5, recordings: 0),
    (daysAgo: 6, minutes: 20, mood: 4, focus: 4, recordings: 1),
    (daysAgo: 15, minutes: 25, mood: 0, focus: 0, recordings: 0),
    (daysAgo: 40, minutes: 15, mood: 4, focus: 3, recordings: 0),
  ];
  return List.unmodifiable([
    for (var index = 0; index < samples.length; index++)
      PracticeSession(
        id: '${profile.id}:session-$index',
        profileId: profile.id,
        date: DateTime(
          now.year,
          now.month,
          now.day - samples[index].daysAgo,
          19 - index,
        ),
        title: titles[index],
        duration: Duration(minutes: samples[index].minutes),
        bpm: 80,
        practiced: index == 0
            ? profile.instrument == MeloopInstrument.guitar
                  ? strings.sampleSessionNotes
                  : strings.practiceSampleScaleNotes
            : strings.practiceSampleSteadyNotes,
        difficulty: index == 0
            ? profile.instrument == MeloopInstrument.guitar
                  ? strings.practiceSampleGuitarDifficulty
                  : strings.practiceSampleDifficulty
            : '',
        nextPractice: strings.sampleNextNotes,
        mood: samples[index].mood == 0 ? null : samples[index].mood,
        focus: samples[index].focus == 0 ? null : samples[index].focus,
        recordingCount: samples[index].recordings,
        recordings: [
          for (var take = 0; take < samples[index].recordings; take++)
            PracticeSessionRecording(
              id: '${profile.id}:session-$index:recording-$take',
              title: strings.practiceRecordingTake(titles[index], take + 1),
              duration: Duration(seconds: take == 0 ? 84 : 58),
            ),
        ],
      ),
  ]);
}
