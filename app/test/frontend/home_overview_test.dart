import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/app/meloop_app.dart';
import 'package:meloop/frontend/application/startup_controller.dart';
import 'package:meloop/frontend/components/meloop_ui.dart';
import 'package:meloop/frontend/home/practice_overview_provider.dart';
import 'package:meloop/frontend/home/practice_progress_page.dart';
import 'package:meloop/frontend/practice/practice_tools_page.dart';
import 'package:meloop/frontend/practice_sessions/practice_session.dart';
import 'package:meloop/frontend/showcase/meloop_ui_showcase.dart';
import 'package:meloop/shared/journal/weekly_practice_goal.dart';

import '../support/home_fixture.dart';

void main() {
  final today = DateTime(2026, 10, 3);
  const flute = PreviewInstrumentProfile(
    id: 'home-test-flute',
    name: 'Sáo buổi tối',
    instrument: MeloopInstrument.flute,
  );
  final saved = homeTestOverview.value.summary.latest!;
  Widget app(PracticeSessionsLoader loader, {WeeklyPracticeGoalLoader? goal}) =>
      MeloopApp(
        overrides: [
          startupSnapshotProvider.overrideWithValue(
            StartupSnapshot(
              profiles: const [homeTestProfile, flute],
              selectedProfileId: homeTestProfile.id,
              hasChosenProfile: true,
            ),
          ),
          practiceSessionsClockProvider.overrideWithValue(() => today),
          practiceSessionsLoaderProvider.overrideWithValue(loader),
          if (goal != null)
            weeklyPracticeGoalLoaderProvider.overrideWithValue(goal),
        ],
        home: const MeloopUiShowcase(developmentTools: false),
      );
  String metric(WidgetTester tester, String key) =>
      tester.widget<Text>(find.byKey(Key(key))).data!;
  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Home and Progress share profile data and recent summary has no actions',
    (tester) async {
      await tester.pumpWidget(
        app(
          (_) async => [
            saved,
            PracticeSession(
              id: 'flute-saved',
              profileId: flute.id,
              date: today,
              title: 'Luyện hơi Sáo',
              duration: const Duration(seconds: 30),
            ),
          ],
          goal: (id) async => WeeklyPracticeGoal(
            enabled: id == homeTestProfile.id,
            targetDays: 4,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(metric(tester, 'overview-minutes'), '35');
      expect(metric(tester, 'overview-count'), '1');
      expect(metric(tester, 'overview-streak'), '1');
      final recent = find.byKey(const Key('home-recent-session'));
      expect(
        find.descendant(of: recent, matching: find.text(saved.title)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: recent, matching: find.byType(InkWell)),
        findsNothing,
      );
      expect(
        find.descendant(of: recent, matching: find.byType(TextButton)),
        findsNothing,
      );
      expect(
        find.descendant(of: recent, matching: find.byType(MeloopButton)),
        findsNothing,
      );
      expect(find.textContaining('Tiếp tục'), findsNothing);
      await tap(tester, find.text('Chi tiết ›'));
      expect(find.byType(PracticeProgressPage), findsOneWidget);
      expect(metric(tester, 'overview-minutes'), '35');
      expect(find.text('1/4 ngày'), findsOneWidget);
      expect(find.text('Chưa có đánh giá'), findsNWidgets(2));
      final scope = ProviderScope.containerOf(
        tester.element(find.byType(MeloopUiShowcase)),
      );
      scope
          .read(meloopShellControllerProvider.notifier)
          .selectProfile(flute.id);
      await tester.pumpAndSettle();
      expect(metric(tester, 'overview-minutes'), '0');
      expect(metric(tester, 'overview-count'), '1');
      expect(metric(tester, 'overview-streak'), '0');
      expect(find.text('Đang tắt'), findsOneWidget);
      expect(find.text('Luyện hơi Sáo'), findsOneWidget);
      expect(find.text(saved.title), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'loading and failed reads are distinct from empty; retry reloads data',
    (tester) async {
      final pending = Completer<List<PracticeSession>>();
      var attempts = 0;
      await tester.pumpWidget(
        app((_) {
          attempts++;
          return attempts == 1 ? pending.future : Future.value([saved]);
        }),
      );
      await tester.pump();
      expect(find.text('Đang đọc dữ liệu luyện tập…'), findsOneWidget);
      expect(find.byKey(const Key('overview-count')), findsNothing);
      expect(find.text('Chưa có buổi luyện'), findsNothing);
      pending.completeError(StateError('injected read failure'));
      await tester.pumpAndSettle();
      expect(
        find.text('Không thể đọc dữ liệu luyện tập. Hãy thử lại.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('overview-count')), findsNothing);
      await tap(tester, find.text('Thử lại'));
      expect(metric(tester, 'overview-count'), '1');
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'empty journal stays zero and tools do not create a practice session',
    (tester) async {
      await tester.pumpWidget(app((_) async => []));
      await tester.pumpAndSettle();
      expect(metric(tester, 'overview-minutes'), '0');
      expect(find.text('Chưa có buổi luyện'), findsOneWidget);
      expect(find.text('Luyện gam C'), findsNothing);
      expect(find.text('Đang tắt'), findsOneWidget);
      await tap(tester, find.text('Công cụ luyện tập'));
      expect(find.byType(PracticeToolsPage), findsOneWidget);
      expect(
        tester
            .widget<PracticeToolsPage>(find.byType(PracticeToolsPage))
            .sessionId,
        isNull,
      );
      await tap(tester, find.text('Ghi âm'));
      expect(find.textContaining('chưa khả dụng'), findsOneWidget);
      final scope = ProviderScope.containerOf(
        tester.element(find.byType(PracticeToolsPage)),
      );
      expect(scope.read(meloopShellControllerProvider).selectedDraft, isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('selecting an instrument again reads its latest committed data', (
    tester,
  ) async {
    var guitarRecords = [saved];
    var loads = 0;
    await tester.pumpWidget(
      app((profile) async {
        if (profile.id == homeTestProfile.id) {
          loads++;
          return guitarRecords;
        }
        return [];
      }),
    );
    await tester.pumpAndSettle();
    final scope = ProviderScope.containerOf(
      tester.element(find.byType(MeloopUiShowcase)),
    );
    scope.read(meloopShellControllerProvider.notifier).selectProfile(flute.id);
    await tester.pumpAndSettle();
    guitarRecords = [];
    scope
        .read(meloopShellControllerProvider.notifier)
        .selectProfile(homeTestProfile.id);
    await tester.pumpAndSettle();
    expect(loads, 2);
    expect(metric(tester, 'overview-count'), '0');
    expect(find.text(saved.title), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('chart remains bounded for several full-day sessions', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        (_) async => [
          for (var i = 0; i < 4; i++)
            PracticeSession(
              id: 'long-$i',
              profileId: homeTestProfile.id,
              date: today,
              title: 'Long test session',
              duration: const Duration(hours: 24),
            ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    final bar = tester.widget<Container>(
      find.byKey(ValueKey('practice-bar-${today.toIso8601String()}')),
    );
    expect(bar.constraints!.maxHeight, 64);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
