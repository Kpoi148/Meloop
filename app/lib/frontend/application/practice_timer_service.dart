import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/journal/practice_timer_service.dart';

/// Null retains the independent FE preview and read-only bootstrap harness.
final practiceTimerServiceProvider = Provider<PracticeTimerService?>(
  (ref) => null,
);

final practiceTimerCompleteProvider = Provider<Future<void> Function(String)>((
  ref,
) {
  final service = ref.read(practiceTimerServiceProvider);
  return (sessionId) async {
    if (service?.snapshot?.sessionId == sessionId) {
      await service!.complete(sessionId);
    }
  };
});
final practiceTimerSnapshotProvider = StreamProvider<PracticeTimerSnapshot?>((
  ref,
) async* {
  final service = ref.watch(practiceTimerServiceProvider);
  yield service?.snapshot;
  if (service != null) yield* service.changes;
});
