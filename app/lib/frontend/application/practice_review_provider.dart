import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/journal/journal_models.dart';
import '../components/meloop_ui.dart';
import '../practice_sessions/practice_session.dart' as ui;
import 'session_form_values.dart';

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
final practiceToolOpenProvider = Provider<PracticeToolOpen?>((ref) => null);
typedef PracticeTitleUpdate = Future<String> Function(
  String sessionId,
  String title,
);
final practiceTitleUpdateProvider = Provider<PracticeTitleUpdate?>(
  (ref) => null,
);
