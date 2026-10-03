import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/app/meloop_app.dart';
import 'package:meloop/frontend/application/startup_controller.dart';
import 'package:meloop/frontend/components/meloop_ui.dart';
import 'package:meloop/frontend/showcase/home_example.dart';
import 'package:meloop/frontend/showcase/instrument_profiles_example.dart';
import 'package:meloop/frontend/showcase/session_form_example.dart';
import 'package:meloop/frontend/showcase/settings_example.dart';
import 'package:meloop/frontend/showcase/setup_example.dart';
import 'package:meloop/frontend/showcase/welcome_example.dart';

import '../support/home_fixture.dart';

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
  testWidgets(
    'render examples with real Tempo fonts and assets for visual review',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.devicePixelRatio = 1;
      final samples = <String, Widget>{
        'home': MeloopPage(
          bottomNavigation: MeloopBottomNavigation(
            selectedIndex: 0,
            onSelected: (_) {},
          ),
          child: HomeExample(
            profile: homeTestProfile,
            overview: homeTestOverview,
            onCreate: () {},
            onProgress: () {},
            onRetry: () {},
            onTools: () {},
          ),
        ),
        'welcome': const WelcomeExample(),
        'setup': SetupExample(onSave: (_) async {}),
        'form': SessionFormExample(onSave: (_) async {}),
        'settings': MeloopPage(
          bottomNavigation: MeloopBottomNavigation(
            selectedIndex: 3,
            onSelected: (_) {},
          ),
          child: SettingsExample(
            profile: const PreviewInstrumentProfile(
              id: 'guitar-preview',
              instrument: MeloopInstrument.guitar,
            ),
            language: 'Tiếng Việt',
            onLanguage: () {},
          ),
        ),
        'profiles': InstrumentProfilesExample(
          profiles: const [
            PreviewInstrumentProfile(
              id: 'guitar-preview',
              name: 'Guitar của tôi',
              instrument: MeloopInstrument.guitar,
            ),
            PreviewInstrumentProfile(
              id: 'piano-preview',
              name: 'Piano buổi tối',
              instrument: MeloopInstrument.piano,
            ),
            PreviewInstrumentProfile(
              id: 'violin-preview',
              name: 'Violin của tôi',
              instrument: MeloopInstrument.violin,
            ),
          ],
          selectedProfileId: 'guitar-preview',
          archivedProfileIds: const {'violin-preview'},
          onBack: () {},
          onHome: () {},
          onAdd: () {},
        ),
      };
      for (final sample in samples.entries) {
        final width = switch (sample.key) {
          'settings' || 'profiles' => 460.0,
          _ => 390.0,
        };
        final height = switch (sample.key) {
          'form' => 1900.0,
          'settings' || 'profiles' => 1400.0,
          _ => 844.0,
        };
        tester.view.physicalSize = Size(width, height);
        final boundaryKey = GlobalKey();
        await tester.pumpWidget(
          MeloopApp(
            key: UniqueKey(),
            home: RepaintBoundary(key: boundaryKey, child: sample.value),
          ),
        );
        await tester.runAsync(() async {
          final context = boundaryKey.currentContext!;
          for (final asset in [
            'fidelity-welcome.png',
            'fidelity-setup.png',
            'instruments-v2.png',
            'illustrations.png',
          ]) {
            await precacheImage(
              AssetImage('assets/illustrations/$asset'),
              context,
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
          final dir = Directory('build/ui-review')..createSync(recursive: true);
          File('${dir.path}/${sample.key}-${width.toInt()}.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
          rendered.dispose();
        });
      }
    },
  );
}
