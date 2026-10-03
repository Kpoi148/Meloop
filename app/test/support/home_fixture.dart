import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meloop/frontend/application/startup_controller.dart';
import 'package:meloop/frontend/components/meloop_ui.dart';
import 'package:meloop/frontend/home/practice_overview_provider.dart';
import 'package:meloop/frontend/practice_sessions/practice_session.dart';
import 'package:meloop/frontend/practice_sessions/practice_session_summary.dart';
import 'package:meloop/shared/journal/weekly_practice_goal.dart';

const homeTestProfile = PreviewInstrumentProfile(
  id: 'home-test-guitar',
  name: 'Guitar của tôi',
  instrument: MeloopInstrument.guitar,
);
final homeTestOverview = AsyncData(
  PracticeOverview(
    summary: PracticeSessionSummary([
      PracticeSession(
        id: 'home-test-session',
        profileId: homeTestProfile.id,
        date: DateTime(2026, 10, 3),
        title: 'Luyện gam C',
        duration: const Duration(minutes: 35),
        practiced: 'Gam C trưởng, chuyển hợp âm C – G – Am – F.',
        bpm: 80,
      ),
    ], DateTime(2026, 10, 3)),
    goal: WeeklyPracticeGoal(enabled: true, targetDays: 4),
  ),
);
