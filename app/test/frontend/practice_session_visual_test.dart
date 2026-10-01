import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/app/meloop_app.dart';
import 'package:meloop/frontend/application/startup_controller.dart';
import 'package:meloop/frontend/practice/practice_tools_page.dart';
import 'package:meloop/frontend/components/meloop_ui.dart';
import 'package:meloop/frontend/showcase/meloop_ui_showcase.dart';
import 'package:meloop/frontend/showcase/practice_preview_service.dart';
import 'package:meloop/shared/practice/practice_session_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final fonts = FontLoader(TempoType.fontFamily);
    for (final weight in [400, 500, 600, 700]) {
      fonts.addFont(rootBundle.load('assets/fonts/be-vietnam-pro-$weight.ttf'));
    }
    await fonts.load();
  });

  testWidgets('render UC-04 timer and fixed Sessions action with real assets', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final service = PracticePreviewService(
      onSave: (_) async {},
      initialDraft: PracticeSessionDraft(
        id: 'visual-draft',
        profileId: 'guitar-preview',
        title: 'Luyện gam C',
        startedAt: DateTime(2026, 10, 1),
        elapsed: const Duration(seconds: 754),
      ),
    );
    await service.resume();
    await service.pause();
    final boundaryKey = GlobalKey();
    await tester.pumpWidget(
      MeloopApp(
        practiceSessionService: service,
        overrides: [
          startupSnapshotProvider.overrideWithValue(
            StartupSnapshot.recoveredDraft,
          ),
        ],
        home: RepaintBoundary(
          key: boundaryKey,
          child: const MeloopUiShowcase(developmentTools: false),
        ),
      ),
    );
    await tester.runAsync(() async {
      for (final asset in [
        'fidelity-timer.png',
        'fidelity-setup.png',
        'instruments-v2.png',
        'illustrations.png',
      ]) {
        await precacheImage(
          AssetImage('assets/illustrations/$asset'),
          boundaryKey.currentContext!,
        );
      }
    });
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    Future<void> capture(String name) => tester.runAsync(() async {
      final boundary =
          boundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final output = Directory('build/ui-review')..createSync(recursive: true);
      File('${output.path}/$name-390.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
      image.dispose();
    });
    await capture('practice-timer');
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MeloopUiShowcase)),
    );
    container.read(meloopShellControllerProvider.notifier).selectTab(1);
    await tester.pumpAndSettle();
    await capture('practice-history');
    await tester.pumpWidget(
      MeloopApp(
        key: UniqueKey(),
        practiceSessionService: service,
        home: RepaintBoundary(
          key: boundaryKey,
          child: PracticeToolsPage(sessionId: service.current.draft!.id),
        ),
      ),
    );
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/illustrations/tools-v2.png'),
        boundaryKey.currentContext!,
      );
    });
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await capture('practice-tools');
    await tester.pumpWidget(const SizedBox.shrink());
    service.dispose();
  });

  testWidgets(
    'render matching profile and stage artwork for every instrument',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final instrument in MeloopInstrument.values) {
        for (final width in [390.0, 460.0]) {
          tester.view.physicalSize = Size(width, 917);
          final profile = PreviewInstrumentProfile(
            id: 'visual-${instrument.name}',
            instrument: instrument,
            name: switch (instrument) {
              MeloopInstrument.guitar => 'Guitar của tôi',
              MeloopInstrument.piano => 'Piano của tôi',
              MeloopInstrument.ukulele => 'Ukulele của tôi',
              MeloopInstrument.violin => 'Violin của tôi',
              MeloopInstrument.flute => 'Sáo của tôi',
              MeloopInstrument.drums => 'Trống của tôi',
              MeloopInstrument.other => 'Nhạc cụ của tôi',
            },
          );
          final service = PracticePreviewService(
            onSave: (_) async {},
            initialDraft: PracticeSessionDraft(
              id: 'visual-draft',
              profileId: profile.id,
              title: 'Luyện gam C',
              startedAt: DateTime(2026, 10, 1),
              elapsed: const Duration(seconds: 5),
            ),
          );
          await service.resume();
          final boundaryKey = GlobalKey();
          await tester.pumpWidget(
            MeloopApp(
              key: UniqueKey(),
              practiceSessionService: service,
              overrides: [
                startupSnapshotProvider.overrideWithValue(
                  StartupSnapshot(
                    profiles: [profile],
                    selectedProfileId: profile.id,
                    draft: PreviewPracticeDraft(profileId: profile.id),
                  ),
                ),
              ],
              home: RepaintBoundary(
                key: boundaryKey,
                child: const MeloopUiShowcase(developmentTools: false),
              ),
            ),
          );
          await tester.runAsync(() async {
            for (final asset in [
              'fidelity-timer.png',
              'fidelity-setup.png',
              'practice-timer-frame.png',
              'practice-instruments.png',
            ]) {
              await precacheImage(
                AssetImage('assets/illustrations/$asset'),
                boundaryKey.currentContext!,
              );
            }
          });
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
            final dir = Directory('build/ui-review')
              ..createSync(recursive: true);
            File('${dir.path}/practice-${instrument.name}-${width.toInt()}.png')
                .writeAsBytesSync(bytes!.buffer.asUint8List());
            rendered.dispose();
          });
          await tester.pumpWidget(const SizedBox.shrink());
          service.dispose();
          await tester.pumpAndSettle();
        }
      }
    },
  );
}
