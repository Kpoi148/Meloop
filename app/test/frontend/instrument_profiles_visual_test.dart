import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/app/meloop_app.dart';
import 'package:meloop/frontend/application/instrument_profile_service.dart';
import 'package:meloop/frontend/components/meloop_ui.dart';
import 'package:meloop/frontend/profiles/instrument_profiles_feature.dart';
import 'package:meloop/frontend/profiles/profile_form.dart';
import 'package:meloop/frontend/showcase/profile_preview_service.dart';
import 'package:meloop/frontend/showcase/instrument_profile_preview.dart';
import 'package:meloop/frontend/showcase/meloop_ui_showcase.dart';
import 'package:meloop/frontend/showcase/showcase_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader(TempoType.fontFamily);
    for (final weight in [400, 500, 600, 700]) {
      loader.addFont(
        rootBundle.load('assets/fonts/be-vietnam-pro-$weight.ttf'),
      );
    }
    await loader.load();
  });

  testWidgets('render instrument profile screens for visual review', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;

    final service = ProfilePreviewService();
    for (final (name, type) in [
      ('Guitar của tôi', InstrumentType.guitar),
      ('Piano buổi tối', InstrumentType.piano),
      ('Sáo của tôi', InstrumentType.flute),
    ]) {
      await service.create(
        requestId: name,
        name: name,
        instrumentType: type,
        customType: '',
      );
    }

    final samples = <(String, double, Widget)>[
      (
        'profile-picker',
        1200,
        InstrumentProfilesFeature(
          entryPage: ProfileEntryPage.picker,
          onOpenHome: (_) {},
          onViewPro: () {},
        ),
      ),
      (
        'profile-manager',
        1050,
        InstrumentProfilesFeature(
          entryPage: ProfileEntryPage.manager,
          onOpenHome: (_) {},
          onViewPro: () {},
        ),
      ),
      (
        'profile-form',
        1350,
        ProfileForm(
          onBack: () {},
          onCreate: (_, _, _, _) async {},
          onRename: (_, _) async {},
        ),
      ),
      ('profile-home', 844, InstrumentProfilePreview(service: service)),
      ('profile-settings', 844, InstrumentProfilePreview(service: service)),
    ];

    for (final (name, height, page) in samples) {
      tester.view.physicalSize = Size(390, height);
      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        MeloopApp(
          key: UniqueKey(),
          overrides: [
            instrumentProfileServiceProvider.overrideWithValue(service),
          ],
          home: RepaintBoundary(key: boundaryKey, child: page),
        ),
      );
      await tester.runAsync(() async {
        final context = boundaryKey.currentContext!;
        for (final asset in [
          'instruments-v2.png',
          'illustrations.png',
          'tools-v2.png',
        ]) {
          await precacheImage(
            AssetImage('assets/illustrations/$asset'),
            context,
          );
        }
      });
      await tester.pumpAndSettle();
      if (name == 'profile-settings') {
        ProviderScope.containerOf(tester.element(find.byType(MeloopUiShowcase)))
            .read(showcaseControllerProvider.notifier)
            .selectTab(3);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('reset-preview-data')), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final boundary =
            boundaryKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final rendered = await boundary.toImage();
        final bytes = await rendered.toByteData(format: ui.ImageByteFormat.png);
        final dir = Directory('build/ui-review')..createSync(recursive: true);
        File('${dir.path}/$name-390.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
        rendered.dispose();
      });
    }
  });
}
