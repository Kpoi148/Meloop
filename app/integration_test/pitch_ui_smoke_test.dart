import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meloop/app/meloop_app.dart';
import 'package:meloop/frontend/application/app_settings_controller.dart';
import 'package:meloop/frontend/application/startup_controller.dart';
import 'package:meloop/frontend/pitch/pitch_gauge.dart';
import 'package:meloop/frontend/pitch/pitch_route.dart';
import 'package:meloop/frontend/practice/practice_tools_page.dart';
import 'package:meloop/frontend/showcase/home_example.dart';
import 'package:meloop/frontend/showcase/meloop_ui_showcase.dart';
import 'package:meloop/frontend/showcase/pitch_preview_service.dart';
import 'package:meloop/shared/pitch/pitch_service.dart';
import 'package:meloop/shared/settings/app_settings_store.dart';

class _PitchQaService extends PitchPreviewService {
  _PitchQaService() : super(settingsAvailable: true);
  int settingsOpened = 0;
  @override
  Future<bool> openAppSettings() async {
    settingsOpened++;
    return super.openAppSettings();
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Android UC-09 states, settings callback, stop and Back', (
    tester,
  ) async {
    final service = _PitchQaService();
    await tester.pumpWidget(
      MeloopApp(
        overrides: [
          appSettingsStoreProvider.overrideWithValue(
            InMemoryAppSettingsStore(languageCode: 'vi'),
          ),
          startupSnapshotProvider.overrideWithValue(StartupSnapshot.oneProfile),
          pitchServiceProvider.overrideWithValue(service),
        ],
        home: const MeloopUiShowcase(developmentTools: false),
      ),
    );
    await tester.pumpAndSettle();
    Future<void> tap(Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    await tap(find.text('Công cụ luyện tập'));
    await tap(find.text('Kiểm tra cao độ'));
    expect(find.byType(PitchRoute), findsOneWidget);
    expect(find.text('Chưa có tín hiệu'), findsOneWidget);
    await binding.convertFlutterSurfaceToImage();
    await tester.pump();
    await binding.takeScreenshot('uc09-idle');
    await tap(find.text('Bật micro'));
    expect(find.text('Đang lắng nghe…'), findsOneWidget);
    service.present(
      PitchPhase.detected,
      reading: const PitchReading(
        note: 'A4',
        frequencyHz: 440,
        cents: 0,
        direction: PitchDirection.inTune,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('A4'), findsOneWidget);
    expect(find.text('Đúng cao độ. Giữ nốt thật đều.'), findsOneWidget);
    await binding.takeScreenshot('uc09-detected');
    service.present(PitchPhase.weakSignal);
    await tester.pumpAndSettle();
    expect(find.text('Chưa đủ tín hiệu'), findsOneWidget);
    expect(find.text('A4'), findsNothing);
    expect(tester.widget<PitchGauge>(find.byType(PitchGauge)).cents, isNull);
    await binding.takeScreenshot('uc09-weak');
    service.present(PitchPhase.permissionBlocked);
    await tester.pumpAndSettle();
    await tap(find.text('Mở cài đặt'));
    expect(service.settingsOpened, 1);
    await binding.takeScreenshot('uc09-permission');
    await tap(find.byTooltip('Quay lại'));
    expect(find.byType(PracticeToolsPage), findsOneWidget);
    expect(service.snapshot.phase, PitchPhase.idle);
    await tap(find.text('Kiểm tra cao độ'));
    expect(find.text('Chưa có tín hiệu'), findsOneWidget);
    await tap(find.text('Bật micro'));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(PracticeToolsPage), findsOneWidget);
    expect(service.snapshot.phase, PitchPhase.idle);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(HomeExample), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await service.close();
  });
}
