import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/frontend/components/meloop_ui.dart';
import 'package:meloop/frontend/showcase/progress_examples.dart';

void main() {
  setUpAll(() async {
    final font = FontLoader(TempoType.fontFamily);
    for (final weight in [400, 500, 600, 700]) {
      font.addFont(rootBundle.load('assets/fonts/be-vietnam-pro-$weight.ttf'));
    }
    await font.load();
  });
  testWidgets(
    'Progress renders with original artwork and type at prototype widths',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final width in [320.0, 390.0, 460.0]) {
        tester.view.physicalSize = Size(width, 1100);
        final boundaryKey = GlobalKey();
        final app = createProgressPreviewApp(
          clock: () => DateTime(2026, 9, 23),
        );
        await tester.pumpWidget(RepaintBoundary(key: boundaryKey, child: app));
        await tester.runAsync(() async {
          for (final asset in ['illustrations.png', 'instruments-v2.png']) {
            await precacheImage(
              AssetImage('assets/illustrations/$asset'),
              boundaryKey.currentContext!,
            );
          }
        });
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$width');
        await tester.runAsync(() async {
          final boundary =
              boundaryKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final rendered = await boundary.toImage();
          final bytes = await rendered.toByteData(
            format: ui.ImageByteFormat.png,
          );
          final file = File(
            'build/ui-review/flutter-progress-${width.toInt()}.png',
          );
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          rendered.dispose();
        });
        tester.view.physicalSize = Size(width, 900);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('progress-filter')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'filter/$width');
        await tester.runAsync(() async {
          final boundary =
              boundaryKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final rendered = await boundary.toImage();
          final bytes = await rendered.toByteData(
            format: ui.ImageByteFormat.png,
          );
          final file = File(
            'build/ui-review/flutter-progress-filter-popup-${width.toInt()}.png',
          );
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          rendered.dispose();
        });
        await tester.tap(find.byKey(const Key('progress-preset-custom')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'custom/$width');
        await tester.runAsync(() async {
          final boundary =
              boundaryKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final rendered = await boundary.toImage();
          final bytes = await rendered.toByteData(
            format: ui.ImageByteFormat.png,
          );
          await File(
            'build/ui-review/flutter-progress-filter-popup-custom-${width.toInt()}.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          rendered.dispose();
        });
        await tester.pumpWidget(const SizedBox.shrink());
      }
    },
  );
}
