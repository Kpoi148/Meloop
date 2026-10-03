import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/app/meloop_app.dart';
import 'package:meloop/frontend/pitch/pitch_gauge.dart';
import 'package:meloop/frontend/pitch/pitch_page.dart';
import 'package:meloop/frontend/components/meloop_ui.dart';
import 'package:meloop/frontend/showcase/pitch_preview_launcher.dart';
import 'package:meloop/frontend/showcase/pitch_preview_scenario.dart';

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

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(const MeloopApp(home: PitchPreviewLauncher()));
    await tester.pumpAndSettle();
    await tap(tester, find.text('Mở màn cao độ'));
  }

  Future<void> select(WidgetTester tester, String label) async {
    await tap(
      tester,
      find.byType(DropdownButtonFormField<PitchPreviewScenario>),
    );
    await tap(tester, find.text(label).last);
    expect(find.text('Chưa có tín hiệu'), findsOneWidget);
    expect(tester.widget<PitchGauge>(find.byType(PitchGauge)).cents, isNull);
    await tap(tester, find.text('Bật micro'));
  }

  testWidgets(
    'manual selector exposes all acceptance states on the actual pitch page',
    (tester) async {
      await open(tester);
      expect(find.byType(PitchPage), findsOneWidget);
      expect(find.textContaining('Dữ liệu mô phỏng'), findsOneWidget);
      await tap(tester, find.text('Bật micro'));
      expect(find.text('Đang lắng nghe…'), findsOneWidget);
      await select(tester, 'Đã nhận nốt, đúng cao độ');
      expect(find.text('A4'), findsOneWidget);
      expect(find.text('440,0 Hz · +0 cent'), findsOneWidget);
      expect(find.text('Đúng cao độ. Giữ nốt thật đều.'), findsOneWidget);
      await select(tester, 'Đã nhận nốt, hơi thấp');
      expect(find.text('Hơi thấp · nâng cao độ một chút.'), findsOneWidget);
      expect(
        tester.widget<PitchGauge>(find.byType(PitchGauge)).cents,
        lessThan(0),
      );
      await select(tester, 'Đã nhận nốt, hơi cao');
      expect(find.text('Hơi cao · hạ cao độ một chút.'), findsOneWidget);
      expect(
        tester.widget<PitchGauge>(find.byType(PitchGauge)).cents,
        greaterThan(0),
      );
      await select(tester, 'Chưa đủ tín hiệu');
      expect(find.text('A4'), findsNothing);
      expect(
        find.textContaining('Tín hiệu yếu hoặc chưa ổn định.'),
        findsOneWidget,
      );
      await select(tester, 'Quyền micro bị từ chối');
      expect(
        find.textContaining('Việc luyện tập và lưu nhật ký vẫn tiếp tục.'),
        findsOneWidget,
      );
      expect(find.text('Mở cài đặt'), findsOneWidget);
      await select(tester, 'Quyền micro bị chặn');
      expect(find.textContaining('Quyền micro đã bị chặn.'), findsOneWidget);
      await tap(tester, find.text('Mở cài đặt'));
      expect(
        find.textContaining('Chưa mở được cài đặt tự động.'),
        findsOneWidget,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(PitchPreviewLauncher), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'stopping and reopening the preview never retains a measurement',
    (tester) async {
      await open(tester);
      await select(tester, 'Đã nhận nốt, đúng cao độ');
      await tap(tester, find.text('Tắt micro'));
      expect(find.text('A4'), findsNothing);
      expect(find.text('Chưa có tín hiệu'), findsOneWidget);
      expect(tester.widget<PitchGauge>(find.byType(PitchGauge)).cents, isNull);
      await tap(tester, find.text('Bật micro'));
      expect(find.text('A4'), findsOneWidget);
      await tap(tester, find.byTooltip('Quay lại'));
      await tap(tester, find.text('Mở màn cao độ'));
      expect(find.text('A4'), findsNothing);
      expect(find.text('Chưa có tín hiệu'), findsOneWidget);
      await tap(tester, find.byTooltip('Trang chủ'));
      expect(find.byType(PitchPreviewLauncher), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final sample in [(390.0, 1.0), (320.0, 2.0)]) {
    testWidgets('preview controls fit ${sample.$1}px with ${sample.$2}x text', (
      tester,
    ) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(sample.$1, 1000);
      final key = GlobalKey();
      await tester.pumpWidget(
        MeloopApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(sample.$2)),
            child: RepaintBoundary(key: key, child: child!),
          ),
          home: const PitchPreviewLauncher(),
        ),
      );
      await tester.pumpAndSettle();
      await tap(tester, find.text('Mở màn cao độ'));
      await select(tester, 'Đã nhận nốt, đúng cao độ');
      expect(find.text('A4'), findsOneWidget);
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .jumpTo(0);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final directory = Directory('build/uc09-review')
          ..createSync(recursive: true);
        File(
          '${directory.path}/preview-${sample.$1.toInt()}-${sample.$2.toInt()}x.png',
        ).writeAsBytesSync(bytes!.buffer.asUint8List());
        image.dispose();
      });
      await tap(tester, find.text('Tắt micro'));
      expect(find.text('A4'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
