import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/journal/practice_timer_service.dart';

/// Null retains the independent FE preview and read-only bootstrap harness.
final practiceTimerServiceProvider = Provider<PracticeTimerService?>(
  (ref) => null,
);
final practiceTimerSnapshotProvider = StreamProvider<PracticeTimerSnapshot?>((
  ref,
) async* {
  final service = ref.watch(practiceTimerServiceProvider);
  yield service?.snapshot;
  if (service != null) yield* service.changes;
});
