import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meloop/frontend/pitch/pitch_gauge.dart';
import 'package:meloop/frontend/showcase/pitch_preview_launcher.dart';
import 'package:meloop/frontend/showcase/pitch_preview_scenario.dart';
import 'package:meloop/main_pitch_preview.dart' as preview;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Android manual preview can show each UC-09 acceptance state', (
    tester,
  ) async {
    preview.main();
    await tester.pumpAndSettle();
    Future<void> tap(Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    Future<void> select(String label) async {
      await tap(find.byType(DropdownButtonFormField<PitchPreviewScenario>));
      await tap(find.text(label).last);
      expect(find.text('Chưa có tín hiệu'), findsOneWidget);
      await tap(find.text('Bật micro'));
    }

    await tap(find.text('Mở màn cao độ'));
    await binding.convertFlutterSurfaceToImage();
    await tester.pump();
    await tap(find.text('Bật micro'));
    expect(find.text('Đang lắng nghe…'), findsOneWidget);
    await binding.takeScreenshot('uc09-preview-listening');
    await select('Đã nhận nốt, đúng cao độ');
    expect(find.text('A4'), findsOneWidget);
    expect(find.text('440,0 Hz · +0 cent'), findsOneWidget);
    await binding.takeScreenshot('uc09-preview-detected');
    await select('Chưa đủ tín hiệu');
    expect(find.text('A4'), findsNothing);
    expect(
      find.textContaining('Tín hiệu yếu hoặc chưa ổn định.'),
      findsOneWidget,
    );
    expect(tester.widget<PitchGauge>(find.byType(PitchGauge)).cents, isNull);
    await binding.takeScreenshot('uc09-preview-weak');
    await select('Quyền micro bị từ chối');
    expect(find.text('Mở cài đặt'), findsOneWidget);
    await binding.takeScreenshot('uc09-preview-denied');
    await tap(find.byTooltip('Quay lại'));
    expect(find.byType(PitchPreviewLauncher), findsOneWidget);
    await tap(find.text('Mở màn cao độ'));
    expect(find.text('Chưa có tín hiệu'), findsOneWidget);
    expect(find.text('A4'), findsNothing);
    await tap(find.byTooltip('Trang chủ'));
    expect(find.byType(PitchPreviewLauncher), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
