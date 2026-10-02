import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/session_form_values.dart';
import 'practice_session.dart';

typedef PracticeSessionUpdate = Future<PracticeSession> Function(
  PracticeSession session,
  SessionFormValues values,
);
typedef PracticeSessionDelete = Future<void> Function(PracticeSession session);
typedef PracticeRecordingDelete = Future<PracticeSession> Function(
  PracticeSession session,
  PracticeSessionRecording recording,
);
typedef PracticeRecordingAction = Future<void> Function(
  PracticeSessionRecording recording,
);

// The app supplies these actions; no journal or audio storage is accessed here.
final practiceSessionUpdateProvider = Provider<PracticeSessionUpdate>(
  (ref) =>
      (_, _) async => throw StateError(
        'Session update dependency has not been configured.',
      ),
);
final practiceSessionDeleteProvider = Provider<PracticeSessionDelete>(
  (ref) =>
      (_) async => throw StateError(
        'Session delete dependency has not been configured.',
      ),
);
final practiceRecordingDeleteProvider = Provider<PracticeRecordingDelete>(
  (ref) =>
      (_, _) async => throw StateError(
        'Recording delete dependency has not been configured.',
      ),
);
final practiceRecordingPlayProvider = Provider<PracticeRecordingAction?>(
  (ref) => null,
);
final practiceRecordingExportProvider = Provider<PracticeRecordingAction?>(
  (ref) => null,
);
