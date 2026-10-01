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
  });

  final String id, profileId, title, practiced, difficulty, nextPractice;
  final DateTime date;
  final Duration duration;
  final int? bpm, mood, focus;
  final int recordingCount;
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

final practiceSessionsProvider =
    FutureProvider.family<List<PracticeSession>, PreviewInstrumentProfile>(
      (ref, profile) => ref.watch(practiceSessionsLoaderProvider)(profile),
    );
