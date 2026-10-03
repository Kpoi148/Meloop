import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meloop/app/journal_practice_lifecycle.dart';
import 'package:meloop/app/meloop_app.dart';
import 'package:meloop/backend/journal/practice_timer.dart';
import 'package:meloop/frontend/application/practice_timer_service.dart';
import 'package:meloop/frontend/application/startup_controller.dart';
import 'package:meloop/frontend/components/meloop_ui.dart';
import 'package:meloop/frontend/practice/practice_tools_page.dart';
import 'package:meloop/frontend/practice_sessions/practice_session.dart'
    as practice;
import 'package:meloop/frontend/practice_sessions/practice_session_card.dart';
import 'package:meloop/frontend/practice_sessions/practice_session_detail_page.dart';
import 'package:meloop/frontend/practice_sessions/practice_session_recordings_page.dart';
import 'package:meloop/frontend/recording/recording_empty_page.dart';
import 'package:meloop/frontend/showcase/home_example.dart';
import 'package:meloop/frontend/showcase/meloop_ui_showcase.dart';
import 'package:meloop/frontend/showcase/recording_example.dart';
import 'package:meloop/frontend/showcase/recording_preview_controller.dart';
import 'package:meloop/frontend/showcase/setup_example.dart';
import 'package:meloop/frontend/recording/recording_ui_state.dart';
import 'package:meloop/frontend/showcase/timer_example.dart';
import 'package:meloop/shared/journal/journal_models.dart';

import '../test/backend/journal/practice_timer_test.dart'
    show TestAwake, TestMonotonicClock;
import '../test/frontend/practice_timer_ui_test.dart' show UiTimerStore;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  var converted = false;
  setUp(() => converted = false);
  Future<void> capture(WidgetTester tester, String name) async {
    if (!converted) {
      await binding.convertFlutterSurfaceToImage();
      converted = true;
      await tester.pump();
    }
    await binding.takeScreenshot('uc10-$name');
  }

  testWidgets('Android Home and saved-session recording entry', (tester) async {
    await tester.pumpWidget(
      MeloopApp(
        overrides: [
          startupSnapshotProvider.overrideWithValue(StartupSnapshot.oneProfile),
          practice.practiceSessionsLoaderProvider.overrideWithValue(
            (profile) async => [
              practice.PracticeSession(
                id: 'saved-entry',
                profileId: profile.id,
                title: 'Luyện gam C',
                date: DateTime(2026, 10, 3),
                duration: const Duration(minutes: 35),
              ),
            ],
          ),
        ],
        home: const MeloopUiShowcase(developmentTools: false),
      ),
    );
    await tester.pumpAndSettle();
    final scope = ProviderScope.containerOf(
      tester.element(find.byType(HomeExample)),
    );
    Future<void> tap(Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    await tap(find.text('Công cụ luyện tập'));
    await tap(find.text('Ghi âm'));
    expect(find.byType(RecordingEmptyPage), findsOneWidget);
    expect(find.text('Giữ lại âm thanh\ncủa hôm nay.'), findsOneWidget);
    expect(find.text('Bắt đầu một buổi luyện trước.'), findsOneWidget);
    expect(scope.read(meloopShellControllerProvider).selectedDraft, isNull);
    await tap(find.text('Tạo buổi luyện'));
    expect(find.byType(SetupExample), findsOneWidget);
    await tap(find.byTooltip('Quay lại'));
    expect(find.byType(RecordingEmptyPage), findsOneWidget);
    expect(scope.read(meloopShellControllerProvider).selectedDraft, isNull);
    await capture(tester, 'empty');
    await tap(find.byTooltip('Quay lại'));
    expect(find.byType(PracticeToolsPage), findsOneWidget);
    await tap(find.text('Ghi âm'));
    await tap(find.byTooltip('Trang chủ'));
    expect(find.byType(HomeExample), findsOneWidget);
    expect(find.byType(PracticeToolsPage), findsNothing);
    await tap(
      find.descendant(
        of: find.byType(MeloopBottomNavigation),
        matching: find.text('Buổi luyện'),
      ),
    );
    await tap(find.widgetWithText(PracticeSessionCard, 'Luyện gam C'));
    expect(find.byType(PracticeSessionDetailPage), findsOneWidget);
    await tap(find.text('Bản ghi của buổi này'));
    expect(find.byType(PracticeSessionRecordingsPage), findsOneWidget);
    expect(find.text('Bản ghi của buổi luyện'), findsOneWidget);
    expect(find.text('Chưa có bản ghi âm.'), findsOneWidget);
    await capture(tester, 'session-recordings');
    await tap(find.text('Ghi âm buổi luyện'));
    expect(find.byType(RecordingEmptyPage), findsOneWidget);
    expect(scope.read(meloopShellControllerProvider).selectedDraft, isNull);
    await tap(find.byTooltip('Quay lại'));
    expect(find.byType(PracticeSessionRecordingsPage), findsOneWidget);
    await tap(find.byTooltip('Quay lại'));
    expect(
      tester
          .widget<PracticeSessionDetailPage>(
            find.byType(PracticeSessionDetailPage),
          )
          .session
          .id,
      'saved-entry',
    );
    await tap(find.text('Bản ghi của buổi này'));
    await tap(find.byTooltip('Trang chủ'));
    expect(find.byType(HomeExample), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'Android UC-10: recording, review and returning preserve practice',
    (tester) async {
      final store = UiTimerStore();
      final clock = TestMonotonicClock();
      final timer = PracticeTimer(
        store: store,
        clock: clock,
        screenAwake: TestAwake(),
        schedulePulses: false,
      );
      final session = store.draft.session;
      await timer.open(store.draft, newlyStarted: true);
      await tester.pumpWidget(
        MeloopApp(
          overrides: [
            practiceTimerServiceProvider.overrideWithValue(timer),
            recordingPreviewClockProvider.overrideWithValue(
              () => Duration(milliseconds: clock.elapsedMilliseconds),
            ),
            startupSnapshotProvider.overrideWithValue(
              StartupSnapshot(
                profiles: [
                  PreviewInstrumentProfile(
                    id: session.profileId,
                    name: 'Guitar của tôi',
                    instrument: MeloopInstrument.guitar,
                  ),
                ],
                selectedProfileId: session.profileId,
                draft: PreviewPracticeDraft(
                  sessionId: session.id,
                  profileId: session.profileId,
                  title: 'Luyện gam C',
                ),
              ),
            ),
          ],
          home: const JournalPracticeLifecycle(
            child: MeloopUiShowcase(developmentTools: false),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final scope = ProviderScope.containerOf(
        tester.element(find.byType(TimerExample)),
      );
      final controller = scope.read(
        recordingPreviewControllerProvider.notifier,
      );
      Future<void> tap(Finder finder) async {
        await tester.ensureVisible(finder);
        await tester.tap(finder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        final recording = controller.forSession(session.id);
        if (recording.phase != RecordingPhase.recording && !recording.playing) {
          await tester.pumpAndSettle();
        }
      }

      try {
        if (timer.snapshot!.state == PracticeState.paused) {
          await tap(find.widgetWithText(MeloopButton, 'Tiếp tục'));
        }
        expect(timer.snapshot!.state, PracticeState.running);
        await tap(find.widgetWithText(MeloopButton, 'Công cụ luyện tập'));
        await tap(find.text('Ghi âm'));
        expect(find.byType(RecordingExample), findsOneWidget);
        await capture(tester, 'ready');
        await tap(find.byTooltip('Bắt đầu ghi âm'));
        clock.advance(12000);
        controller.refresh();
        await timer.pulse();
        await tester.pump();
        expect(timer.snapshot!.state, PracticeState.running);
        expect(
          controller.forSession(session.id).phase,
          RecordingPhase.recording,
        );
        expect(
          controller.forSession(session.id).elapsed,
          const Duration(seconds: 12),
        );
        await capture(tester, 'active');
        await tap(find.byTooltip('Dừng ghi âm'));
        expect(controller.forSession(session.id).phase, RecordingPhase.review);
        expect(find.text('Nghe lại một chút.'), findsOneWidget);
        await tester.ensureVisible(find.text('Giữ bản ghi'));
        await tester.pump();
        await capture(tester, 'review');
        await tap(find.text('Giữ bản ghi'));
        expect(controller.forSession(session.id).keptTakes, 1);
        await tap(find.byTooltip('Quay lại'));
        await tap(find.byTooltip('Quay lại'));
        expect(find.byType(TimerExample), findsOneWidget);
        expect(find.text('00:12'), findsOneWidget);
        expect(timer.snapshot!.state, PracticeState.running);
        expect(timer.snapshot!.sessionId, session.id);
        expect(tester.takeException(), isNull);
        await capture(tester, 'practice-return');
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await timer.close();
      }
    },
  );
}
