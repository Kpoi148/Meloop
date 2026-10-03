import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/startup_controller.dart';

/// UI records supplied by the app; this feature never writes journal data.
class PracticeSession {
  const PracticeSession({
    required this.id,
    required this.profileId,
    required this.date,
    required this.title,
    required this.duration,
    this.practiced = '',
    this.difficulty = '',
    this.nextPractice = '',
    this.bpm,
    this.mood,
    this.focus,
    this.recordingCount = 0,
    this.recordings = const [],
  });

  final String id, profileId, title, practiced, difficulty, nextPractice;
  final DateTime date;
  final Duration duration;
  final int? bpm, mood, focus;
  final int recordingCount;
  final List<PracticeSessionRecording> recordings;

  PracticeSession withRecordings(List<PracticeSessionRecording> recordings) =>
      PracticeSession(
        id: id,
        profileId: profileId,
        date: date,
        title: title,
        duration: duration,
        practiced: practiced,
        difficulty: difficulty,
        nextPractice: nextPractice,
        bpm: bpm,
        mood: mood,
        focus: focus,
        recordingCount: recordings.length,
        recordings: List.unmodifiable(recordings),
      );
}

class PracticeSessionRecording {
  const PracticeSessionRecording({
    required this.id,
    required this.title,
    required this.duration,
    this.canPlay = true,
    this.canExport = true,
    this.canDelete = true,
  });

  final String id, title;
  final Duration duration;
  final bool canPlay, canExport, canDelete;
}

typedef PracticeSessionsLoader = Future<List<PracticeSession>> Function(
  PreviewInstrumentProfile profile,
);

final practiceSessionsClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

final practiceSessionsLoaderProvider = Provider<PracticeSessionsLoader>(
  (ref) =>
      (profile) async => const [],
);

final practiceSessionsProvider = FutureProvider.autoDispose
    .family<List<PracticeSession>, PreviewInstrumentProfile>(
      (ref, profile) => ref.watch(practiceSessionsLoaderProvider)(profile),
    );
