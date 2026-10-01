import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/practice/practice_session_service.dart';
import '../components/layout/meloop_art.dart';

export '../../shared/practice/practice_session_service.dart';

/// App composition supplies the local backend or an explicit preview adapter.
final practiceSessionServiceProvider = Provider<PracticeSessionService?>(
  (ref) => null,
);

typedef PracticeToolOpen = Future<void> Function(
  BuildContext context,
  String sessionId,
  MeloopTool tool,
);

/// Tool features receive the current session identity; they cannot start timers.
final practiceToolOpenProvider = Provider<PracticeToolOpen?>((ref) => null);
