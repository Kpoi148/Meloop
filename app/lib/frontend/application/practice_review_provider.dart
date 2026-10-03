import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/journal/journal_models.dart';
import '../components/meloop_ui.dart';
import '../practice_sessions/practice_session.dart' as ui;
import 'session_form_values.dart';
import 'instrument_profile_service.dart';
import 'practice_timer_service.dart';

typedef PracticeReviewLoad = Future<PracticeDraft> Function(String sessionId);
typedef PracticeReviewPersist = Future<void> Function(
  String sessionId,
  ReviewInput input,
);
final practiceReviewPersistProvider = Provider<PracticeReviewPersist>(
  (ref) =>
      (_, _) async =>
          throw StateError('Review persistence has not been configured.'),
);
typedef PracticeReviewSave = Future<ui.PracticeSession> Function(
  String sessionId,
  SessionFormValues values,
);
typedef PracticeToolOpen = Future<void> Function(
  BuildContext context,
  String sessionId,
  MeloopTool tool,
);

final practiceReviewLoadProvider = Provider<PracticeReviewLoad>(
  (ref) =>
      (_) async =>
          throw StateError('Review dependency has not been configured.'),
);
final practiceReviewSaveProvider = Provider<PracticeReviewSave>(
  (ref) =>
      (_, _) async =>
          throw StateError('Save dependency has not been configured.'),
);

/// Refreshes committed data even if the form has gone away. A retry after
/// timer completion skips the already completed timer and reloads projections.
final practiceReviewCompleteProvider =
    Provider<Future<Map<String, int>> Function(String)>((ref) {
      final completeTimer = ref.read(practiceTimerCompleteProvider);
      return (sessionId) async {
        final profiles = ref.read(instrumentProfileServiceProvider);
        if (ref.mounted) ref.invalidate(ui.practiceSessionsProvider);
        await completeTimer(sessionId);
        final directory = await profiles.load();
        return {
          for (final profile in directory.profiles)
            profile.id: profile.savedSessionCount,
        };
      };
    }, dependencies: [instrumentProfileServiceProvider]);
final practiceToolOpenProvider = Provider<PracticeToolOpen?>((ref) => null);
typedef PracticeTitleUpdate = Future<String> Function(
  String sessionId,
  String title,
);
final practiceTitleUpdateProvider = Provider<PracticeTitleUpdate?>(
  (ref) => null,
);
