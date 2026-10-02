import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/app/meloop_app.dart';
import 'package:meloop/frontend/application/startup_controller.dart';
import 'package:meloop/frontend/metronome/metronome_page.dart';
import 'package:meloop/frontend/metronome/metronome_ui_state.dart';
import 'package:meloop/frontend/components/meloop_ui.dart';
import 'package:meloop/frontend/showcase/home_example.dart';
import 'package:meloop/frontend/showcase/meloop_ui_showcase.dart';
import 'package:meloop/frontend/showcase/metronome_example.dart';
import 'package:meloop/frontend/showcase/metronome_preview_controller.dart';
import 'package:meloop/frontend/showcase/timer_example.dart';

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

  ProviderContainer container(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(MetronomeExample)));

  Future<void> openFromHome(WidgetTester tester) async {
    await tester.pumpWidget(
      const MeloopApp(home: MeloopUiShowcase(developmentTools: false)),
    );
    await tester.pumpAndSettle();
    await tap(tester, find.text('Công cụ luyện tập'));
  }

  testWidgets('tempo controls stay in sync and reject out-of-range changes', (
    tester,
  ) async {
    await openFromHome(tester);
    final scope = container(tester);
    final controller = scope.read(metronomePreviewControllerProvider.notifier);
    await tap(tester, find.byTooltip('Tăng nhịp'));
    expect(find.text('81'), findsOneWidget);
    expect(tester.widget<Slider>(find.byType(Slider)).value, 81);

    controller.setBpm(MetronomeUiLimits.minimumBpm);
    await tester.pump();
    await tap(tester, find.byTooltip('Giảm nhịp'));
    expect(find.text('40'), findsOneWidget);
    expect(find.text('Tốc độ phải từ 40 đến 240 BPM.'), findsOneWidget);
    expect(tester.widget<Slider>(find.byType(Slider)).value, 40);

    controller.setBpm(MetronomeUiLimits.maximumBpm);
    await tester.pump();
    await tap(tester, find.byTooltip('Tăng nhịp'));
    expect(find.text('240'), findsOneWidget);
    expect(find.text('Tốc độ phải từ 40 đến 240 BPM.'), findsOneWidget);

    final slider = find.byType(Slider);
    await tester.drag(slider, const Offset(-80, 0));
    await tester.pumpAndSettle();
    final value = tester.widget<Slider>(slider).value.round();
    expect(value, inInclusiveRange(40, 239));
    expect(find.text('$value'), findsOneWidget);
    expect(find.text('Tốc độ phải từ 40 đến 240 BPM.'), findsNothing);

    await tap(tester, find.byType(DropdownButton<int>));
    await tester.scrollUntilVisible(
      find.text('12 phách'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tap(tester, find.text('12 phách').last);
    final state = scope.read(metronomePreviewControllerProvider);
    expect(state.beatsPerBar, 12);
    expect(find.byKey(const ValueKey('metronome-beat-11')), findsOneWidget);
    controller.setBeats(13);
    await tester.pump();
    expect(scope.read(metronomePreviewControllerProvider).beatsPerBar, 12);
    expect(find.text('Số phách mỗi ô nhịp phải từ 1 đến 12.'), findsOneWidget);
    controller.setBeats(0);
    await tester.pump();
    expect(scope.read(metronomePreviewControllerProvider).beatsPerBar, 12);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('start/stop, beat pulses and background use a single UI state', (
    tester,
  ) async {
    await openFromHome(tester);
    final scope = container(tester);
    await tap(tester, find.text('Bắt đầu'));
    expect(find.text('Dừng máy đếm nhịp'), findsOneWidget);
    expect(scope.read(metronomePreviewControllerProvider).playing, isTrue);
    final beat = scope.read(metronomePreviewControllerProvider).activeBeat;
    await tester.pump(const Duration(milliseconds: 750));
    expect(
      scope.read(metronomePreviewControllerProvider).activeBeat,
      (beat! + 1) % 4,
    );
    await tap(tester, find.text('Dừng máy đếm nhịp'));
    expect(scope.read(metronomePreviewControllerProvider).activeBeat, isNull);
    await tester.pump(const Duration(seconds: 2));
    expect(scope.read(metronomePreviewControllerProvider).playing, isFalse);
    await tap(tester, find.text('Bắt đầu'));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(scope.read(metronomePreviewControllerProvider).playing, isFalse);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('Bắt đầu'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('busy audio tool shows actionable feedback without starting', (
    tester,
  ) async {
    await tester.pumpWidget(
      MeloopApp(
        overrides: [metronomeAudioBusyProvider.overrideWithValue(true)],
        home: MetronomeExample(onHome: () {}),
      ),
    );
    await tester.pumpAndSettle();
    await tap(tester, find.text('Bắt đầu'));
    expect(
      container(tester).read(metronomePreviewControllerProvider).playing,
      isFalse,
    );
    expect(
      find.textContaining('Một công cụ âm thanh khác đang hoạt động.'),
      findsOneWidget,
    );
    expect(find.text('Bắt đầu'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('back returns to its caller and preserves the practice draft', (
    tester,
  ) async {
    await openFromHome(tester);
    final scope = container(tester);
    scope.read(metronomePreviewControllerProvider.notifier).setBpm(96);
    await tap(tester, find.byTooltip('Quay lại'));
    expect(find.byType(HomeExample), findsOneWidget);
    await tap(tester, find.text('Công cụ luyện tập'));
    expect(find.text('96'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(HomeExample), findsOneWidget);

    final shell = scope.read(meloopShellControllerProvider.notifier);
    shell.startDraft('Luyện gam C');
    await tester.pumpAndSettle();
    expect(find.byType(TimerExample), findsOneWidget);
    final draft = scope.read(meloopShellControllerProvider).draft!;
    await tap(tester, find.widgetWithText(MeloopButton, 'Công cụ luyện tập'));
    await tester.pump(const Duration(seconds: 2));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(TimerExample), findsOneWidget);
    final returned = scope.read(meloopShellControllerProvider).draft!;
    expect(returned.profileId, draft.profileId);
    expect(returned.title, draft.title);
    expect(returned.isRunning, isTrue);
    final readout = tester
        .widget<Text>(find.textContaining(RegExp(r'^00:\d{2}$')))
        .data!;
    expect(int.parse(readout.split(':').last), greaterThanOrEqualTo(2));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('recovered practice keeps its time without the recovery notice', (
    tester,
  ) async {
    await tester.pumpWidget(
      MeloopApp(
        overrides: [
          startupSnapshotProvider.overrideWithValue(
            StartupSnapshot.recoveredDraft,
          ),
        ],
        home: const MeloopUiShowcase(developmentTools: false),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('12:34'), findsOneWidget);
    expect(find.textContaining('Đã khôi phục buổi luyện'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final sample in [(390.0, 1.0, 4), (320.0, 2.0, 12), (460.0, 1.0, 12)]) {
    testWidgets(
      'Tempo visual review ${sample.$1}px ${sample.$2}x ${sample.$3} beats',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(sample.$1, sample.$2 == 1 ? 900 : 1300);
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
              child: MetronomePage(
                state: MetronomeUiState(
                  bpm: sample.$2 > 1
                      ? MetronomeUiLimits.maximumBpm
                      : MetronomeUiLimits.initialBpm,
                  beatsPerBar: sample.$3,
                ),
                onBack: () {},
                onHome: () {},
                onBpmChanged: (_) {},
                onBeatsChanged: (_) {},
                onToggle: () {},
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
        await tester.ensureVisible(find.text('Bắt đầu'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.runAsync(() async {
          final boundary =
              boundaryKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final rendered = await boundary.toImage();
          final bytes = await rendered.toByteData(
            format: ui.ImageByteFormat.png,
          );
          final directory = Directory('build/uc08-review')
            ..createSync(recursive: true);
          File(
            '${directory.path}/flutter-${sample.$1.toInt()}-${sample.$2.toInt()}x.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
          rendered.dispose();
        });
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
