import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/app/meloop_app.dart';
import 'package:meloop/backend/journal/practice_timer.dart';
import 'package:meloop/frontend/application/practice_timer_service.dart';
import 'package:meloop/frontend/application/startup_controller.dart';
import 'package:meloop/frontend/components/meloop_ui.dart';
import 'package:meloop/frontend/pitch/pitch_gauge.dart';
import 'package:meloop/frontend/pitch/pitch_page.dart';
import 'package:meloop/frontend/pitch/pitch_route.dart';
import 'package:meloop/frontend/practice/practice_tools_page.dart';
import 'package:meloop/frontend/showcase/home_example.dart';
import 'package:meloop/frontend/showcase/meloop_ui_showcase.dart';
import 'package:meloop/frontend/showcase/pitch_preview_service.dart';
import 'package:meloop/frontend/showcase/timer_example.dart';
import 'package:meloop/shared/journal/journal_models.dart';
import 'package:meloop/shared/pitch/pitch_service.dart';

import '../backend/journal/practice_timer_test.dart'
    show TestMonotonicClock, TestAwake;
import 'pitch_controller_test.dart' show ControlledPitchService;
import 'practice_timer_ui_test.dart' show UiTimerStore;

void main() {
  setUpAll(() async {
    final fonts = FontLoader(TempoType.fontFamily);
    for (final weight in [400, 500, 600, 700]) {
      fonts.addFont(rootBundle.load('assets/fonts/be-vietnam-pro-$weight.ttf'));
    }
    await fonts.load();
  });

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> open(WidgetTester tester, PitchService? service) async {
    await tester.pumpWidget(
      MeloopApp(
        overrides: [pitchServiceProvider.overrideWithValue(service)],
        home: const MeloopUiShowcase(developmentTools: false),
      ),
    );
    await tester.pumpAndSettle();
    await tap(tester, find.text('Công cụ luyện tập'));
    await tap(tester, find.text('Kiểm tra cao độ'));
    expect(find.byType(PitchRoute), findsOneWidget);
  }

  testWidgets(
    'listening, received note, weak signal and stopped are distinct',
    (tester) async {
      final service = PitchPreviewService();
      await open(tester, service);
      expect(find.text('Chưa có tín hiệu'), findsOneWidget);
      await tap(tester, find.text('Bật micro'));
      expect(find.text('Đang lắng nghe…'), findsOneWidget);
      for (final sample in [
        (PitchDirection.low, -12.0, 'Hơi thấp · nâng cao độ một chút.'),
        (PitchDirection.inTune, 0.0, 'Đúng cao độ. Giữ nốt thật đều.'),
        (PitchDirection.high, 19.0, 'Hơi cao · hạ cao độ một chút.'),
      ]) {
        service.present(
          PitchPhase.detected,
          reading: PitchReading(
            note: 'A4',
            frequencyHz: 440.1,
            cents: sample.$2,
            direction: sample.$1,
          ),
        );
        await tester.pump();
        expect(find.text('A4'), findsOneWidget);
        expect(find.text(sample.$3), findsOneWidget);
        expect(find.textContaining('440,1 Hz'), findsOneWidget);
        expect(
          tester.widget<PitchGauge>(find.byType(PitchGauge)).cents,
          sample.$2,
        );
      }
      service.present(PitchPhase.weakSignal);
      await tester.pump();
      expect(find.text('Chưa đủ tín hiệu'), findsOneWidget);
      expect(find.text('A4'), findsNothing);
      expect(tester.widget<PitchGauge>(find.byType(PitchGauge)).cents, isNull);
      await tap(tester, find.text('Tắt micro'));
      expect(find.text('Chưa có tín hiệu'), findsOneWidget);
      expect(find.text('Bật micro'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await service.close();
    },
  );

  for (final phase in [
    PitchPhase.permissionDenied,
    PitchPhase.permissionBlocked,
  ]) {
    testWidgets(
      '$phase offers settings and a return to journal without permission',
      (tester) async {
        final service = PitchPreviewService(startPhase: phase);
        await open(tester, service);
        await tap(tester, find.text('Bật micro'));
        expect(find.textContaining('lưu nhật ký'), findsWidgets);
        expect(find.textContaining('Cài đặt Android'), findsOneWidget);
        await tap(tester, find.text('Mở cài đặt'));
        expect(
          find.textContaining('Chưa mở được cài đặt tự động.'),
          findsOneWidget,
        );
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(PracticeToolsPage), findsOneWidget);
        expect(service.snapshot.phase, PitchPhase.idle);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(HomeExample), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
        await service.close();
      },
    );
  }

  testWidgets('settings command reaches the injected service', (tester) async {
    final service = ControlledPitchService();
    await open(tester, service);
    await tap(tester, find.text('Bật micro'));
    service.present(PitchPhase.permissionBlocked);
    await tester.pump();
    await tap(tester, find.text('Mở cài đặt'));
    expect(service.settingsOpened, 1);
    expect(find.textContaining('Chưa mở được cài đặt tự động.'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await service.close();
  });

  testWidgets(
    'background releases microphone; resume and reopen need an explicit start',
    (tester) async {
      final service = ControlledPitchService();
      await open(tester, service);
      await tap(tester, find.text('Bật micro'));
      service.present(
        PitchPhase.detected,
        reading: const PitchReading(
          note: 'G3',
          frequencyHz: 196,
          cents: 0,
          direction: PitchDirection.inTune,
        ),
      );
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(
        service.stops,
        0,
      ); // An Android permission dialog must not cancel start.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pumpAndSettle();
      expect(service.snapshot.phase, PitchPhase.idle);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      // Paused apps do not render frames. Verify the cleared UI on resumption.
      expect(find.text('G3'), findsNothing);
      expect(service.starts, 1);
      await tap(tester, find.byTooltip('Quay lại'));
      await tap(tester, find.text('Kiểm tra cao độ'));
      expect(find.text('Chưa có tín hiệu'), findsOneWidget);
      expect(service.starts, 1);
      await tap(tester, find.byTooltip('Trang chủ'));
      expect(find.byType(HomeExample), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await service.close();
    },
  );

  testWidgets('no adapter reports unavailable and still permits Back', (
    tester,
  ) async {
    await open(tester, null);
    await tap(tester, find.text('Bật micro'));
    expect(
      find.textContaining('Kiểm tra cao độ chưa khả dụng'),
      findsOneWidget,
    );
    await tap(tester, find.byTooltip('Quay lại'));
    expect(find.byType(PracticeToolsPage), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'Back retains the same running practice, Home pauses without losing time',
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
      final service = ControlledPitchService();
      await timer.open(store.draft, newlyStarted: true);
      await tester.pumpWidget(
        MeloopApp(
          overrides: [
            pitchServiceProvider.overrideWithValue(service),
            practiceTimerServiceProvider.overrideWithValue(timer),
            startupSnapshotProvider.overrideWithValue(
              StartupSnapshot(
                profiles: [
                  PreviewInstrumentProfile(
                    id: session.profileId,
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
      await tap(tester, find.widgetWithText(MeloopButton, 'Công cụ luyện tập'));
      await tap(tester, find.text('Kiểm tra cao độ'));
      await tap(tester, find.text('Bật micro'));
      clock.advance(3500);
      await timer.pulse();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(PracticeToolsPage), findsOneWidget);
      expect(timer.snapshot!.state, PracticeState.running);
      expect(timer.snapshot!.sessionId, session.id);
      expect(service.snapshot.phase, PitchPhase.idle);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(TimerExample), findsOneWidget);
      expect(find.text('00:03'), findsOneWidget);
      expect(timer.snapshot!.elapsedMilliseconds, 3500);
      await tap(tester, find.widgetWithText(MeloopButton, 'Công cụ luyện tập'));
      await tap(tester, find.text('Kiểm tra cao độ'));
      await tap(tester, find.text('Bật micro'));
      await tap(tester, find.byTooltip('Trang chủ'));
      expect(find.byType(HomeExample), findsOneWidget);
      expect(timer.snapshot!.state, PracticeState.paused);
      expect(timer.snapshot!.sessionId, session.id);
      expect(timer.snapshot!.elapsedMilliseconds, 3500);
      expect(service.snapshot.phase, PitchPhase.idle);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await timer.close();
      await service.close();
    },
  );

  for (final sample in [
    (390.0, 1.0, PitchPhase.idle),
    (460.0, 1.0, PitchPhase.detected),
    (320.0, 2.0, PitchPhase.permissionBlocked),
  ]) {
    testWidgets('Tempo visual review ${sample.$1}px ${sample.$2}x ${sample.$3}', (
      tester,
    ) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(sample.$1, sample.$2 == 1 ? 1000 : 1400);
      final key = GlobalKey();
      await tester.pumpWidget(
        MeloopApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(sample.$2)),
            child: child!,
          ),
          home: RepaintBoundary(
            key: key,
            child: PitchPage(
              snapshot: PitchSnapshot(
                phase: sample.$3,
                sample: const PitchReading(
                  note: 'A4',
                  frequencyHz: 442.1,
                  cents: 8,
                  direction: PitchDirection.high,
                ),
              ),
              onBack: () {},
              onHome: () {},
              onToggle: () {},
              onOpenSettings: () async {},
            ),
          ),
        ),
      );
      await tester.runAsync(
        () => precacheImage(
          const AssetImage('assets/illustrations/tools-v2.png'),
          key.currentContext!,
        ),
      );
      await tester.pumpAndSettle();
      if (sample.$2 > 1) {
        await tester.ensureVisible(find.text('Mở cài đặt'));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final directory = Directory('build/uc09-review')
          ..createSync(recursive: true);
        File(
          '${directory.path}/flutter-${sample.$1.toInt()}-${sample.$2.toInt()}x.png',
        ).writeAsBytesSync(bytes!.buffer.asUint8List());
        image.dispose();
      });
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
