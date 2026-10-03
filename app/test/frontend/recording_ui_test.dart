import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/app/meloop_app.dart';
import 'package:meloop/backend/journal/practice_timer.dart';
import 'package:meloop/frontend/application/practice_timer_service.dart';
import 'package:meloop/frontend/application/startup_controller.dart';
import 'package:meloop/frontend/components/meloop_ui.dart';
import 'package:meloop/frontend/practice/practice_tools_page.dart';
import 'package:meloop/frontend/practice_sessions/practice_session.dart'
    as practice;
import 'package:meloop/frontend/practice_sessions/practice_session_recordings_page.dart';
import 'package:meloop/frontend/recording/recording_empty_page.dart';
import 'package:meloop/frontend/recording/recording_page.dart';
import 'package:meloop/frontend/recording/recording_ui_state.dart';
import 'package:meloop/frontend/showcase/meloop_ui_showcase.dart';
import 'package:meloop/frontend/showcase/home_example.dart';
import 'package:meloop/frontend/showcase/recording_example.dart';
import 'package:meloop/frontend/showcase/recording_preview_controller.dart';
import 'package:meloop/frontend/showcase/setup_example.dart';
import 'package:meloop/frontend/showcase/timer_example.dart';
import 'package:meloop/shared/journal/journal_models.dart';

import '../backend/journal/practice_timer_test.dart'
    show TestMonotonicClock, TestAwake;
import 'practice_timer_ui_test.dart' show UiTimerStore;

void main() {
  setUpAll(() async {
    final fonts = FontLoader(TempoType.fontFamily);
    for (final weight in [400, 500, 600, 700]) {
      fonts.addFont(rootBundle.load('assets/fonts/be-vietnam-pro-$weight.ttf'));
    }
    await fonts.load();
  });

  test(
    'duration cap retains the take, quota blocks the next take across sessions',
    () {
      var now = Duration.zero;
      final container = ProviderContainer(
        overrides: [
          recordingPreviewClockProvider.overrideWithValue(() => now),
          recordingPreviewInputsProvider.overrideWithValue(
            RecordingPreviewInputs(
              quota: RecordingPreviewInputs.freeQuota.withSavedFiles(9),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(
        recordingPreviewControllerProvider.notifier,
      );
      controller.start('current-session', sessionRunning: true);
      now = const Duration(minutes: 5, seconds: 2);
      controller.refresh();
      final stopped = controller.forSession('current-session');
      expect(stopped.phase, RecordingPhase.review);
      expect(stopped.elapsed, const Duration(minutes: 5));
      expect(stopped.issue, RecordingIssue.durationLimit);
      expect(controller.keep('current-session'), isTrue);
      expect(controller.keep('current-session'), isFalse);
      expect(controller.forSession('current-session').quota.savedFiles, 10);
      controller.start('another-session', sessionRunning: true);
      expect(
        controller.forSession('another-session').phase,
        RecordingPhase.ready,
      );
      expect(
        controller.forSession('another-session').issue,
        RecordingIssue.fileLimit,
      );
    },
  );

  for (final scenario in [
    (
      const RecordingPreviewInputs(microphone: RecordingMicrophone.denied),
      RecordingIssue.microphoneDenied,
    ),
    (
      const RecordingPreviewInputs(microphone: RecordingMicrophone.unavailable),
      RecordingIssue.microphoneUnavailable,
    ),
    (
      const RecordingPreviewInputs(storageAvailable: false),
      RecordingIssue.storageFull,
    ),
    (const RecordingPreviewInputs(audioBusy: true), RecordingIssue.audioBusy),
    (
      const RecordingPreviewInputs(startAvailable: false),
      RecordingIssue.startFailed,
    ),
  ]) {
    test(
      'start failure ${scenario.$2} retains the session and does not start a clock',
      () {
        final container = ProviderContainer(
          overrides: [
            recordingPreviewInputsProvider.overrideWithValue(scenario.$1),
          ],
        );
        addTearDown(container.dispose);
        final controller = container.read(
          recordingPreviewControllerProvider.notifier,
        );
        controller.start('session', sessionRunning: true);
        expect(controller.forSession('session').phase, RecordingPhase.ready);
        expect(controller.forSession('session').elapsed, Duration.zero);
        expect(controller.forSession('session').issue, scenario.$2);
        expect(controller.forSession('session').quota.savedFiles, 0);
      },
    );
  }

  test('failed keep retains review and playback; retry only adds one take', () {
    var now = Duration.zero;
    final container = ProviderContainer(
      overrides: [
        recordingPreviewClockProvider.overrideWithValue(() => now),
        recordingPreviewInputsProvider.overrideWithValue(
          const RecordingPreviewInputs(saveAvailable: false),
        ),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(
      recordingPreviewControllerProvider.notifier,
    );
    controller.start('session', sessionRunning: true);
    now = const Duration(seconds: 12);
    controller.stop('session');
    expect(controller.keep('session'), isFalse);
    expect(controller.forSession('session').phase, RecordingPhase.review);
    expect(
      controller.forSession('session').elapsed,
      const Duration(seconds: 12),
    );
    expect(controller.forSession('session').issue, RecordingIssue.saveFailed);
    controller.togglePlayback('session');
    now += const Duration(seconds: 3);
    controller.refresh();
    expect(
      controller.forSession('session').playbackPosition,
      const Duration(seconds: 3),
    );
    controller.stop('session');
    container.updateOverrides([
      recordingPreviewClockProvider.overrideWithValue(() => now),
      recordingPreviewInputsProvider.overrideWithValue(
        const RecordingPreviewInputs(),
      ),
    ]);
    expect(controller.keep('session'), isTrue);
    expect(controller.forSession('session').keptTakes, 1);
    expect(controller.forSession('session').phase, RecordingPhase.ready);
  });

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
  }

  testWidgets('Home recorder entry creates a practice only after Start', (
    tester,
  ) async {
    var starts = 0;
    await tester.pumpWidget(
      MeloopApp(
        home: MeloopUiShowcase(
          developmentTools: false,
          onStartDraft: (requestId, profileId, title) async {
            starts++;
            return PreviewPracticeDraft(
              sessionId: requestId,
              profileId: profileId,
              title: title,
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    final scope = ProviderScope.containerOf(
      tester.element(find.byType(HomeExample)),
    );
    Future<void> openEntry() async {
      await tap(tester, find.text('Công cụ luyện tập'));
      await tap(tester, find.text('Ghi âm'));
      await tester.pumpAndSettle();
      expect(find.byType(RecordingEmptyPage), findsOneWidget);
      expect(find.text('Giữ lại âm thanh\ncủa hôm nay.'), findsOneWidget);
      expect(find.text('Bắt đầu một buổi luyện trước.'), findsOneWidget);
      expect(
        find.text('Bản ghi sẽ đi cùng nhật ký buổi luyện đang diễn ra.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('recording-toggle')), findsNothing);
      expect(scope.read(meloopShellControllerProvider).selectedDraft, isNull);
      expect(starts, 0);
    }

    await openEntry();
    await tap(tester, find.byTooltip('Trang chủ'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeExample), findsOneWidget);
    await openEntry();
    await tap(tester, find.text('Tạo buổi luyện'));
    await tester.pumpAndSettle();
    expect(find.byType(SetupExample), findsOneWidget);
    expect(starts, 0);
    await tap(tester, find.byTooltip('Quay lại'));
    await tester.pumpAndSettle();
    expect(find.byType(RecordingEmptyPage), findsOneWidget);
    expect(scope.read(meloopShellControllerProvider).selectedDraft, isNull);
    await tap(tester, find.text('Tạo buổi luyện'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Luyện gam C');
    await tap(tester, find.text('Bắt đầu luyện'));
    await tester.pumpAndSettle();
    expect(starts, 1);
    expect(find.byType(TimerExample), findsOneWidget);
    expect(find.byType(RecordingEmptyPage), findsNothing);
    expect(find.byType(PracticeToolsPage), findsNothing);
    expect(
      scope.read(meloopShellControllerProvider).selectedDraft!.title,
      'Luyện gam C',
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'record, return, pause and background retain the same practice clock',
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
                  title: session.title,
                ),
              ),
            ),
          ],
          home: const MeloopUiShowcase(developmentTools: false),
        ),
      );
      await tester.pumpAndSettle();
      final scope = ProviderScope.containerOf(
        tester.element(find.byType(TimerExample)),
      );
      final controller = scope.read(
        recordingPreviewControllerProvider.notifier,
      );
      try {
        await tap(
          tester,
          find.widgetWithText(MeloopButton, 'Công cụ luyện tập'),
        );
        await tap(tester, find.text('Ghi âm'));
        expect(find.byType(RecordingExample), findsOneWidget);
        await tap(tester, find.byTooltip('Bắt đầu ghi âm'));
        clock.advance(12000);
        controller.refresh();
        await timer.pulse();
        await tester.pump();
        expect(
          controller.forSession(session.id).phase,
          RecordingPhase.recording,
        );
        expect(find.text('00:12'), findsOneWidget);
        expect(timer.snapshot!.state, PracticeState.running);
        await tap(tester, find.byTooltip('Quay lại'));
        expect(controller.forSession(session.id).phase, RecordingPhase.review);
        await tap(tester, find.text('Ghi âm'));
        expect(find.text('Nghe lại một chút.'), findsOneWidget);
        expect(
          controller.forSession(session.id).elapsed,
          const Duration(seconds: 12),
        );
        await tap(tester, find.text('Bỏ bản ghi'));
        await tap(tester, find.text('Hủy'));
        expect(find.text('Nghe lại một chút.'), findsOneWidget);
        await tap(tester, find.text('Bỏ bản ghi'));
        await tap(tester, find.widgetWithText(MeloopButton, 'Bỏ bản ghi').last);
        expect(controller.forSession(session.id).phase, RecordingPhase.ready);
        await tap(tester, find.byTooltip('Bắt đầu ghi âm'));
        clock.advance(2000);
        await timer.pause();
        await tester.pump();
        expect(controller.forSession(session.id).phase, RecordingPhase.review);
        expect(timer.snapshot!.state, PracticeState.paused);
        await timer.resume();
        await tester.pump();
        expect(controller.forSession(session.id).phase, RecordingPhase.review);
        await tap(tester, find.text('Giữ bản ghi'));
        await tap(tester, find.byTooltip('Bắt đầu ghi âm'));
        clock.advance(1000);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pump();
        expect(controller.forSession(session.id).phase, RecordingPhase.review);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();
        expect(controller.forSession(session.id).phase, RecordingPhase.review);
        await tap(tester, find.byTooltip('Trang chủ'));
        await tester.pumpAndSettle();
        expect(timer.snapshot!.state, PracticeState.paused);
        expect(timer.snapshot!.sessionId, session.id);
        await tap(tester, find.text('Công cụ luyện tập'));
        await tester.pumpAndSettle();
        await tap(tester, find.text('Ghi âm'));
        await tester.pumpAndSettle();
        expect(find.byType(RecordingExample), findsOneWidget);
        expect(find.byType(RecordingEmptyPage), findsNothing);
        expect(timer.snapshot!.state, PracticeState.paused);
        expect(timer.snapshot!.sessionId, session.id);
        expect(controller.forSession(session.id).phase, RecordingPhase.review);
        await tap(tester, find.byTooltip('Trang chủ'));
        await tester.pumpAndSettle();
        expect(find.byType(HomeExample), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await timer.close();
      }
    },
  );

  for (final sample in [(390.0, 1.0), (320.0, 2.0), (460.0, 1.0)]) {
    testWidgets('Tempo session recordings ${sample.$1}px ${sample.$2}x', (
      tester,
    ) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(sample.$1, 1100 * sample.$2);
      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        MeloopApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(sample.$2)),
            child: child!,
          ),
          home: RepaintBoundary(
            key: boundaryKey,
            child: PracticeSessionRecordingsPage(
              session: practice.PracticeSession(
                id: 'saved-session',
                profileId: 'guitar',
                title: 'Luyện gam C',
                date: DateTime(2026, 10, 3),
                duration: const Duration(minutes: 35),
              ),
              onChanged: (_) {},
              onHome: () {},
              onRecordPractice: () async {},
            ),
          ),
        ),
      );
      await tester.runAsync(
        () => precacheImage(
          const AssetImage('assets/illustrations/tools-v2.png'),
          boundaryKey.currentContext!,
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Ghi âm buổi luyện'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .jumpTo(0);
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final boundary =
            boundaryKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final snapshot = await boundary.toImage();
        final bytes = await snapshot.toByteData(format: ui.ImageByteFormat.png);
        final directory = Directory('build/uc10-review')
          ..createSync(recursive: true);
        File(
          '${directory.path}/flutter-${sample.$1.toInt()}-${sample.$2}x-session-recordings.png',
        ).writeAsBytesSync(bytes!.buffer.asUint8List());
        snapshot.dispose();
      });
      await tester.pumpWidget(const SizedBox.shrink());
    });
    testWidgets('Tempo recorder entry ${sample.$1}px ${sample.$2}x', (
      tester,
    ) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(sample.$1, 1100 * sample.$2);
      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        MeloopApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(sample.$2)),
            child: child!,
          ),
          home: RepaintBoundary(
            key: boundaryKey,
            child: RecordingEmptyPage(
              onBack: () {},
              onHome: () {},
              onCreatePractice: () async {},
            ),
          ),
        ),
      );
      await tester.runAsync(
        () => precacheImage(
          const AssetImage('assets/illustrations/tools-v2.png'),
          boundaryKey.currentContext!,
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Tạo buổi luyện'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .jumpTo(0);
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final boundary =
            boundaryKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final snapshot = await boundary.toImage();
        final bytes = await snapshot.toByteData(format: ui.ImageByteFormat.png);
        final directory = Directory('build/uc10-review')
          ..createSync(recursive: true);
        File(
          '${directory.path}/flutter-${sample.$1.toInt()}-${sample.$2}x-empty.png',
        ).writeAsBytesSync(bytes!.buffer.asUint8List());
        snapshot.dispose();
      });
      await tester.pumpWidget(const SizedBox.shrink());
    });
    for (final phase in RecordingPhase.values) {
      testWidgets('Tempo recorder ${sample.$1}px ${sample.$2}x $phase', (
        tester,
      ) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(
          sample.$1,
          sample.$2 == 1 ? 1100 : 1700,
        );
        final boundaryKey = GlobalKey();
        await tester.pumpWidget(
          MeloopApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(sample.$2)),
              child: child!,
            ),
            home: RepaintBoundary(
              key: boundaryKey,
              child: RecordingPage(
                title: 'Luyện gam C',
                profileName: 'Guitar của tôi',
                state: RecordingUiState(
                  quota: RecordingPreviewInputs.freeQuota,
                  phase: phase,
                  elapsed: phase == RecordingPhase.ready
                      ? Duration.zero
                      : const Duration(seconds: 12),
                ),
                sessionRunning: true,
                onBack: () {},
                onHome: () {},
                onStart: () {},
                onStop: () {},
                onKeep: () {},
                onDiscard: () {},
                onTogglePlayback: () {},
                onSeek: (_) {},
                onViewPro: () {},
              ),
            ),
          ),
        );
        await tester.runAsync(
          () => precacheImage(
            const AssetImage('assets/illustrations/tools-v2.png'),
            boundaryKey.currentContext!,
          ),
        );
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull);
        if (phase == RecordingPhase.review) {
          await tester.ensureVisible(find.text('Giữ bản ghi'));
          await tester.pump();
          expect(tester.takeException(), isNull);
          // Return to the top for consistent screenshots of the composition.
          tester
              .state<ScrollableState>(find.byType(Scrollable).first)
              .position
              .jumpTo(0);
          await tester.pump(const Duration(seconds: 1));
        }
        await tester.runAsync(() async {
          final boundary =
              boundaryKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final rendered = await boundary.toImage();
          final bytes = await rendered.toByteData(
            format: ui.ImageByteFormat.png,
          );
          final directory = Directory('build/uc10-review')
            ..createSync(recursive: true);
          File(
            '${directory.path}/flutter-${sample.$1.toInt()}-${sample.$2.toInt()}x-${phase.name}.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
          rendered.dispose();
        });
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
}
