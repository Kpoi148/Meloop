import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/app/meloop_app.dart';
import 'package:meloop/frontend/components/meloop_ui.dart';
import 'package:meloop/frontend/showcase/home_example.dart';
import 'package:meloop/frontend/showcase/session_form_example.dart';
import 'package:meloop/frontend/showcase/setup_example.dart';
import 'package:meloop/frontend/showcase/welcome_example.dart';

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
            onCreate: () {},
            onHistory: () {},
            onCatalog: () {},
          ),
        ),
        'welcome': const WelcomeExample(),
        'setup': SetupExample(onSave: (_) async {}),
        'form': SessionFormExample(onSave: (_) async {}),
      };
      for (final sample in samples.entries) {
        final height = sample.key == 'form' ? 1900.0 : 844.0;
        tester.view.physicalSize = Size(390, height);
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
          File('${dir.path}/${sample.key}-390.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
          rendered.dispose();
        });
      }
    },
  );
}
