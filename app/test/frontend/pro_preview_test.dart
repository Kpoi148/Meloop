import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/app/profile_preview_app.dart';
import 'package:meloop/frontend/application/instrument_profile_service.dart';
import 'package:meloop/frontend/application/startup_controller.dart';
import 'package:meloop/frontend/components/meloop_ui.dart';
import 'package:meloop/frontend/showcase/meloop_ui_showcase.dart';
import 'package:meloop/frontend/showcase/pro_preview_page.dart';
import 'package:meloop/frontend/showcase/profile_preview_service.dart';
import 'package:meloop/frontend/showcase/welcome_example.dart';
import 'package:meloop/shared/settings/app_settings_store.dart';

import 'support/profile_preview_test_storage.dart';

void main() {
  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> openApp(
    WidgetTester tester,
    MemoryProfilePreviewStorage storage,
  ) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      createProfilePreviewApp(
        storage: storage,
        settingsStore: InMemoryAppSettingsStore(languageCode: 'vi'),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> seedThree(MemoryProfilePreviewStorage storage) async {
    final service = ProfilePreviewService(storage: storage);
    for (final type in InstrumentType.values.take(3)) {
      await service.create(
        requestId: type.name,
        name: type.name,
        instrumentType: type,
        customType: '',
      );
    }
  }

  Future<void> settings(WidgetTester tester) => tap(
    tester,
    find.descendant(
      of: find.byType(MeloopBottomNavigation),
      matching: find.text('Cài đặt'),
    ),
  );

  Future<ProfileDirectory> saved(MemoryProfilePreviewStorage storage) =>
      ProfilePreviewService(storage: storage).load();

  testWidgets('Pro from settings survives reopen and reset returns to Free', (
    tester,
  ) async {
    final storage = MemoryProfilePreviewStorage();
    await seedThree(storage);
    await openApp(tester, storage);
    await settings(tester);
    await tap(tester, find.byKey(const Key('explore-pro')));
    expect(find.byType(ProPreviewPage), findsOneWidget);
    expect(find.text('49.000đ'), findsOneWidget);
    expect(find.text('Thêm không gian\ncho đam mê.'), findsOneWidget);
    await tap(tester, find.byKey(const Key('try-pro')));
    await tap(tester, find.text('Hủy'));
    expect((await saved(storage)).isPro, isFalse);
    await tap(tester, find.byKey(const Key('try-pro')));
    await tap(tester, find.text('Bật xem thử'));
    expect(find.text('Đang xem thử Meloop Pro'), findsOneWidget);
    expect((await saved(storage)).isPro, isTrue);
    await tap(tester, find.byTooltip('Quay lại'));
    expect(find.text('PRO · XEM THỬ'), findsOneWidget);

    await tap(tester, find.text('Quản lý hồ sơ nhạc cụ'));
    await tap(tester, find.text('Thêm hồ sơ'));
    await tap(tester, find.byKey(const Key('profile-type-violin')));
    await tap(tester, find.byKey(const Key('save-profile')));
    expect((await saved(storage)).profiles, hasLength(4));
    await openApp(tester, storage);
    await settings(tester);
    expect(find.text('PRO · XEM THỬ'), findsOneWidget);

    await tap(tester, find.byKey(const Key('reset-preview-data')));
    expect(find.textContaining('quyền xem thử Pro'), findsOneWidget);
    await tap(tester, find.text('Giữ dữ liệu'));
    expect((await saved(storage)).isPro, isTrue);
    await tap(tester, find.byKey(const Key('reset-preview-data')));
    await tap(tester, find.text('Xóa và bắt đầu lại'));
    expect(find.byType(WelcomeExample), findsOneWidget);
    await openApp(tester, storage);
    expect(find.byType(WelcomeExample), findsOneWidget);
    expect((await saved(storage)).isPro, isFalse);
    expect((await saved(storage)).profiles, isEmpty);
    await tap(tester, find.text('Tạo hồ sơ đầu tiên'));
    await tap(tester, find.byKey(const Key('profile-type-guitar')));
    await tap(tester, find.byKey(const Key('save-profile')));
    await settings(tester);
    expect(find.text('FREE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Free limit opens Pro and refreshes profiles after activation', (
    tester,
  ) async {
    final storage = MemoryProfilePreviewStorage();
    await seedThree(storage);
    await openApp(tester, storage);
    await settings(tester);
    await tap(tester, find.text('Quản lý hồ sơ nhạc cụ'));
    await tap(tester, find.text('Thêm hồ sơ'));
    expect(find.text('Đã đủ 3 hồ sơ'), findsOneWidget);
    await tap(tester, find.text('Xem Meloop Pro'));
    await tap(tester, find.byKey(const Key('try-pro')));
    await tap(tester, find.text('Bật xem thử'));
    await tap(tester, find.byTooltip('Quay lại'));
    await tap(tester, find.text('Thêm hồ sơ'));
    expect(find.text('Đã đủ 3 hồ sơ'), findsNothing);
    await tap(tester, find.byKey(const Key('profile-type-flute')));
    await tap(tester, find.byKey(const Key('save-profile')));
    expect((await saved(storage)).profiles, hasLength(4));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'failed activation keeps Free and retries without losing profiles',
    (tester) async {
      final storage = MemoryProfilePreviewStorage();
      await seedThree(storage);
      await openApp(tester, storage);
      await settings(tester);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(MeloopUiShowcase)),
      );
      final shell = container.read(meloopShellControllerProvider.notifier);
      await shell.startDraft('Luyện nhịp');
      shell.selectTab(3);
      await tester.pumpAndSettle();
      await tap(tester, find.byKey(const Key('explore-pro')));
      await tap(tester, find.byKey(const Key('restore-pro')));
      expect(find.textContaining('chưa kết nối Google Play'), findsOneWidget);
      await tap(tester, find.text('Đóng'));
      expect((await saved(storage)).isPro, isFalse);
      storage.failWrite = true;
      await tap(tester, find.byKey(const Key('try-pro')));
      await tap(tester, find.text('Bật xem thử'));
      expect(find.textContaining('Chưa thể bật Pro.'), findsOneWidget);
      expect((await saved(storage)).isPro, isFalse);
      expect((await saved(storage)).profiles, hasLength(3));
      storage.failWrite = false;
      await tap(tester, find.text('Bật xem thử'));
      await tap(tester, find.byTooltip('Quay lại'));
      expect(
        container.read(meloopShellControllerProvider).draft!.title,
        'Luyện nhịp',
      );
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'Pro activation and reset roll back safely on storage failure',
    () async {
      final storage = MemoryProfilePreviewStorage();
      await seedThree(storage);
      final service = ProfilePreviewService(storage: storage);
      Future<ProfileDirectory> fourth() => service.create(
        requestId: 'fourth',
        name: 'Violin',
        instrumentType: InstrumentType.violin,
        customType: '',
      );
      await expectLater(
        fourth(),
        throwsA(
          isA<ProfileServiceException>().having(
            (error) => error.code,
            'code',
            ProfileServiceError.freeLimit,
          ),
        ),
      );
      storage.failWrite = true;
      await expectLater(
        service.enableProPreview(),
        throwsA(isA<ProfileServiceException>()),
      );
      expect((await service.load()).isPro, isFalse);
      storage.failWrite = false;
      await service.enableProPreview();
      await fourth();
      storage.failWrite = true;
      await expectLater(
        service.reset(),
        throwsA(isA<ProfileServiceException>()),
      );
      expect((await service.load()).isPro, isTrue);
      expect((await saved(storage)).profiles, hasLength(4));
      storage.failWrite = false;
      await service.reset();
      expect((await saved(storage)).isPro, isFalse);
      expect((await saved(storage)).profiles, isEmpty);
    },
  );
}
