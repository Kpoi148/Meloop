import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/app/meloop_app.dart';
import 'package:meloop/frontend/application/app_settings_controller.dart';
import 'package:meloop/frontend/application/startup_controller.dart';
import 'package:meloop/frontend/components/meloop_ui.dart';
import 'package:meloop/frontend/showcase/meloop_ui_showcase.dart';
import 'package:meloop/shared/settings/app_settings_store.dart';

void main() {
  test('entry rule selects 0, 1, many and recovered-draft destinations', () {
    MeloopShellState read(StartupSnapshot snapshot) {
      final container = ProviderContainer(
        overrides: [startupSnapshotProvider.overrideWithValue(snapshot)],
      );
      addTearDown(container.dispose);
      return container.read(meloopShellControllerProvider);
    }

    expect(read(StartupSnapshot.empty).destination, StartupDestination.welcome);
    expect(
      read(StartupSnapshot.oneProfile).destination,
      StartupDestination.main,
    );
    expect(
      read(StartupSnapshot.manyProfiles).destination,
      StartupDestination.profilePicker,
    );
    final recovered = read(StartupSnapshot.recoveredDraft);
    expect(recovered.destination, StartupDestination.recoveredTimer);
    expect(recovered.draft!.accumulatedSeconds, 754);
    expect(recovered.draft!.isRunning, isFalse);
    expect(recovered.draft!.wasRecovered, isTrue);
  });

  test('changing tabs never creates a practice draft', () {
    final container = ProviderContainer(
      overrides: [
        startupSnapshotProvider.overrideWithValue(StartupSnapshot.oneProfile),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(meloopShellControllerProvider.notifier);

    for (final tab in [1, 2, 3, 0]) {
      controller.selectTab(tab);
      expect(container.read(meloopShellControllerProvider).draft, isNull);
    }
  });

  test('locale survives a new controller through the settings store', () async {
    final store = InMemoryAppSettingsStore(languageCode: 'vi');
    var container = ProviderContainer(
      overrides: [appSettingsStoreProvider.overrideWithValue(store)],
    );
    expect((await container.read(appLocaleProvider.future)).languageCode, 'vi');
    await container.read(appLocaleProvider.notifier).select(const Locale('en'));
    container.dispose();

    container = ProviderContainer(
      overrides: [appSettingsStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    expect((await container.read(appLocaleProvider.future)).languageCode, 'en');
  });

  testWidgets('entry screens and UC-20 work with memory-only showcase data', (
    tester,
  ) async {
    final store = InMemoryAppSettingsStore(languageCode: 'vi');
    await tester.pumpWidget(
      MeloopApp(
        overrides: [
          appSettingsStoreProvider.overrideWithValue(store),
          startupSnapshotProvider.overrideWithValue(StartupSnapshot.empty),
        ],
        home: const MeloopUiShowcase(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Tạo hồ sơ đầu tiên'), findsOneWidget);

    await tester.tap(find.text('VI'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('Create your first profile'), findsOneWidget);
    expect(find.text('A little music.\nEvery day.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      MeloopApp(
        key: UniqueKey(),
        overrides: [
          appSettingsStoreProvider.overrideWithValue(store),
          startupSnapshotProvider.overrideWithValue(
            StartupSnapshot.recoveredDraft,
          ),
        ],
        home: const MeloopUiShowcase(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Practice session restored'), findsNothing);
    expect(find.text('12:34'), findsOneWidget);
    expect(find.widgetWithText(MeloopButton, 'Resume'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile picker follows the prototype card structure', (
    tester,
  ) async {
    await tester.pumpWidget(
      MeloopApp(
        overrides: [
          startupSnapshotProvider.overrideWithValue(
            StartupSnapshot.manyProfiles,
          ),
        ],
        home: const MeloopUiShowcase(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hôm nay bạn chơi\nnhạc cụ nào?'), findsOneWidget);
    expect(find.text('Guitar của tôi'), findsOneWidget);
    expect(find.text('Piano buổi tối'), findsOneWidget);
    expect(find.text('Guitar · 5 buổi luyện đã lưu'), findsOneWidget);
    expect(find.text('Piano · Chưa có buổi luyện'), findsOneWidget);
    expect(find.text('Đang chọn'), findsOneWidget);
    expect(find.byTooltip('Quay lại'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('system back returns from profile picker to Home', (
    tester,
  ) async {
    await tester.pumpWidget(
      MeloopApp(
        overrides: [
          startupSnapshotProvider.overrideWithValue(StartupSnapshot.oneProfile),
        ],
        home: const MeloopUiShowcase(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Tổng quan'), findsOneWidget);

    await tester.tap(find.text('Guitar'));
    await tester.pumpAndSettle();
    expect(find.text('Hôm nay bạn chơi\nnhạc cụ nào?'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Tổng quan'), findsOneWidget);
    expect(find.text('Hôm nay bạn chơi\nnhạc cụ nào?'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings tab follows the prototype composition', (tester) async {
    await tester.pumpWidget(
      MeloopApp(
        overrides: [
          startupSnapshotProvider.overrideWithValue(StartupSnapshot.oneProfile),
        ],
        home: const MeloopUiShowcase(developmentTools: false),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cài đặt'));
    await tester.pumpAndSettle();

    expect(find.text('FREE'), findsOneWidget);
    expect(find.text('MELOOP · KHÔNG GIAN CỦA BẠN'), findsOneWidget);
    expect(find.text('Theo cách bạn.'), findsOneWidget);
    expect(find.text('Guitar của tôi'), findsOneWidget);
    expect(find.text('Quản lý hồ sơ nhạc cụ'), findsOneWidget);
    expect(find.text('Meloop Pro', findRichText: true), findsOneWidget);
    expect(find.text('Theo cách của bạn'), findsOneWidget);
    expect(find.text('Dữ liệu trên thiết bị'), findsOneWidget);
    expect(find.text('Thông tin & hỗ trợ'), findsOneWidget);
    expect(find.text('Khôi phục Pro'), findsOneWidget);
    expect(find.textContaining('Meloop · 0.1.0'), findsOneWidget);

    await tester.tap(find.text('Quản lý hồ sơ nhạc cụ'));
    await tester.pumpAndSettle();
    expect(find.text('Hồ sơ nhạc cụ'), findsOneWidget);
    expect(find.text('Mỗi nhạc cụ,\nmột hành trình.'), findsOneWidget);
    expect(find.text('Những âm thanh làm nên bạn.'), findsOneWidget);
    expect(find.text('Đang chọn'), findsOneWidget);
    expect(
      find.text(
        'Miễn phí có 3 hồ sơ. Lưu trữ giữ nguyên lịch sử và không giải phóng suất hồ sơ.',
      ),
      findsOneWidget,
    );
    expect(find.byType(MeloopBottomNavigation), findsNothing);

    await tester.tap(find.text('Thêm hồ sơ'));
    await tester.pumpAndSettle();
    expect(find.text('Bạn chơi nhạc cụ gì?'), findsOneWidget);
    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pumpAndSettle();
    expect(find.text('Mỗi nhạc cụ,\nmột hành trình.'), findsOneWidget);

    await tester.tap(find.byTooltip('Trang chủ'));
    await tester.pumpAndSettle();
    expect(find.text('Tổng quan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
