import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meloop/app/meloop_app.dart';
import 'package:meloop/frontend/application/app_settings_controller.dart';
import 'package:meloop/frontend/application/startup_controller.dart';
import 'package:meloop/frontend/recording/recording_track_player.dart';
import 'package:meloop/frontend/recording/recordings_page.dart';
import 'package:meloop/frontend/showcase/meloop_ui_showcase.dart';
import 'package:meloop/frontend/showcase/recording_preview_controller.dart';
import 'package:meloop/frontend/showcase/recordings_playback_preview.dart';
import 'package:meloop/shared/settings/app_settings_store.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Android UC-11–13 library, playback controls, export cancel and delete',
    (tester) async {
      await tester.pumpWidget(
        MeloopApp(
          overrides: [
            appSettingsStoreProvider.overrideWithValue(
              InMemoryAppSettingsStore(languageCode: 'vi'),
            ),
            startupSnapshotProvider.overrideWithValue(
              StartupSnapshot.oneProfile,
            ),
          ],
          home: const MeloopUiShowcase(developmentTools: false),
        ),
      );
      await tester.pumpAndSettle();
      final scope = ProviderScope.containerOf(
        tester.element(find.byType(MeloopUiShowcase)),
      );
      Future<void> tap(Finder finder) async {
        await tester.ensureVisible(finder);
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      await tap(find.text('Công cụ luyện tập'));
      await tap(find.text('Bản ghi âm'));
      expect(find.byType(RecordingsPage), findsOneWidget);
      expect(find.byType(RecordingTrackPlayer), findsNWidgets(3));
      await binding.convertFlutterSurfaceToImage();
      await tester.pump();
      await binding.takeScreenshot('uc11-13-library');
      await tap(find.byTooltip('Nghe lại').first);
      expect(scope.read(recordingsPlaybackPreviewProvider).playing, isTrue);
      final seek = tester.widget<Slider>(find.byType(Slider).first);
      seek.onChanged!(30000);
      await tester.pump();
      expect(
        scope.read(recordingsPlaybackPreviewProvider).position.inSeconds,
        greaterThanOrEqualTo(30),
      );
      await tap(find.byTooltip('Tạm dừng nghe lại'));
      expect(scope.read(recordingsPlaybackPreviewProvider).playing, isFalse);
      await tap(find.text('Xuất bản ghi').first);
      expect(find.text('Chia sẻ bản ghi'), findsOneWidget);
      expect(find.text('Lưu vào tệp'), findsOneWidget);
      await binding.takeScreenshot('uc11-13-export');
      await tap(find.text('Hủy'));
      expect(find.text('Đã xuất bản ghi âm.'), findsNothing);
      await tap(find.byTooltip('Xóa bản ghi').first);
      await binding.takeScreenshot('uc11-13-delete');
      await tap(find.text('Hủy'));
      expect(find.byType(RecordingTrackPlayer), findsNWidgets(3));
      await tap(find.byTooltip('Nghe lại').first);
      await tap(find.byTooltip('Xóa bản ghi').first);
      await tap(find.text('Xóa bản ghi'));
      expect(scope.read(recordingsPlaybackPreviewProvider).recordingId, isNull);
      expect(scope.read(recordingPreviewInputsProvider).quota.savedFiles, 2);
      expect(find.byType(RecordingTrackPlayer), findsNWidgets(2));
      for (var index = 0; index < 2; index++) {
        await tap(find.byTooltip('Xóa bản ghi').first);
        await tap(find.text('Xóa bản ghi'));
      }
      expect(find.text('Chưa có bản ghi âm.'), findsOneWidget);
      expect(scope.read(recordingPreviewInputsProvider).quota.savedFiles, 0);
      await binding.takeScreenshot('uc11-13-empty');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
