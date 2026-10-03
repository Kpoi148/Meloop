import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/app/meloop_app.dart';
import 'package:meloop/app/profile_preview_app.dart';
import 'package:meloop/frontend/application/instrument_profile_service.dart';
import 'package:meloop/frontend/application/startup_controller.dart';
import 'package:meloop/frontend/components/meloop_ui.dart';
import 'package:meloop/frontend/showcase/practice_session_examples.dart';
import 'package:meloop/frontend/profiles/instrument_profiles_feature.dart';
import 'package:meloop/frontend/showcase/component_catalog.dart';
import 'package:meloop/frontend/showcase/meloop_ui_showcase.dart';
import 'package:meloop/frontend/showcase/showcase_controller.dart';
import 'package:meloop/frontend/showcase/welcome_example.dart';
import 'package:meloop/shared/settings/app_settings_store.dart';

import 'support/profile_preview_test_storage.dart';

void main() {
  MeloopApp previewApp(MemoryProfilePreviewStorage storage) {
    final preview = createProfilePreviewApp(
      storage: storage,
      settingsStore: InMemoryAppSettingsStore(languageCode: 'vi'),
    );
    // Profile creation tests use an empty journal, not the component sample loader.
    return MeloopApp(
      overrides: [
        ...preview.overrides,
        practiceSessionsPreviewLoaderProvider.overrideWithValue(
          (_) async => const [],
        ),
      ],
      home: preview.home,
    );
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  InstrumentProfileService serviceFrom(WidgetTester tester) =>
      ProviderScope.containerOf(
        tester.element(find.byType(InstrumentProfilesFeature)),
      ).read(instrumentProfileServiceProvider);

  Future<void> createGuitar(WidgetTester tester) async {
    await tapVisible(tester, find.text('Tạo hồ sơ đầu tiên'));
    await tapVisible(tester, find.byKey(const Key('profile-type-guitar')));
    await tapVisible(tester, find.byKey(const Key('save-profile')));
  }

  Future<void> openSettings(WidgetTester tester) => tapVisible(
    tester,
    find.descendant(
      of: find.byType(MeloopBottomNavigation),
      matching: find.text('Cài đặt'),
    ),
  );

  Future<void> reopen(
    WidgetTester tester,
    MemoryProfilePreviewStorage storage,
  ) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(previewApp(storage));
    await tester.pumpAndSettle();
  }

  testWidgets('default app resets all profiles only after confirmation', (
    tester,
  ) async {
    final storage = MemoryProfilePreviewStorage();
    await tester.pumpWidget(previewApp(storage));
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeExample), findsOneWidget);
    final originalService = serviceFrom(tester);
    await createGuitar(tester);
    await openSettings(tester);
    await tapVisible(tester, find.text('Quản lý hồ sơ nhạc cụ'));
    await tapVisible(tester, find.text('Thêm hồ sơ'));
    await tapVisible(tester, find.byKey(const Key('profile-type-piano')));
    await tapVisible(tester, find.byKey(const Key('save-profile')));
    expect((await originalService.load()).profiles, hasLength(2));

    await openSettings(tester);
    await tapVisible(tester, find.byKey(const Key('reset-preview-data')));
    await tapVisible(tester, find.text('Giữ dữ liệu'));
    expect((await originalService.load()).profiles, hasLength(2));
    expect(find.text('Piano của tôi'), findsOneWidget);

    await tapVisible(tester, find.byKey(const Key('reset-preview-data')));
    await tapVisible(tester, find.text('Xóa và bắt đầu lại'));
    expect(find.byType(WelcomeExample), findsOneWidget);
    final newService = serviceFrom(tester);
    final directory = await newService.load();
    expect(directory.profiles, isEmpty);
    expect(directory.selectedProfileId, isNull);

    await reopen(tester, storage);
    expect(find.byType(WelcomeExample), findsOneWidget);

    // The old name is available again and no other profile survives the reset.
    await createGuitar(tester);
    await tapVisible(tester, find.byKey(const Key('choose-profile')));
    expect(
      (await serviceFrom(tester).load()).profiles.single.name,
      'Guitar của tôi',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('showcase settings reset opens the interactive welcome flow', (
    tester,
  ) async {
    await tester.pumpWidget(const MeloopApp(home: MeloopUiShowcase()));
    await tester.pumpAndSettle();
    await tapVisible(
      tester,
      find.descendant(
        of: find.byType(MeloopBottomNavigation),
        matching: find.text('Cài đặt'),
      ),
    );
    await tapVisible(tester, find.byKey(const Key('reset-preview-data')));
    await tapVisible(tester, find.text('Xóa và bắt đầu lại'));
    expect(find.byType(WelcomeExample), findsOneWidget);
    expect(find.byType(MeloopBottomNavigation), findsNothing);
    expect(
      Navigator.of(tester.element(find.byType(WelcomeExample))).canPop(),
      isFalse,
    );
    expect((await serviceFrom(tester).load()).profiles, isEmpty);
    await createGuitar(tester);
    expect(find.byKey(const Key('choose-profile')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'showcase welcome CTA creates a profile instead of opening catalog',
    (tester) async {
      await tester.pumpWidget(const MeloopApp(home: MeloopUiShowcase()));
      await tester.pumpAndSettle();
      await tapVisible(
        tester,
        find.descendant(
          of: find.byType(MeloopBottomNavigation),
          matching: find.text('Cài đặt'),
        ),
      );
      await tapVisible(tester, find.text('Xem màn chào Tempo'));
      expect(find.byType(WelcomeExample), findsOneWidget);
      final service = serviceFrom(tester);
      await createGuitar(tester);
      expect(find.byType(ComponentCatalog), findsNothing);
      expect(find.byKey(const Key('choose-profile')), findsOneWidget);
      expect((await service.load()).profiles.single.name, 'Guitar của tôi');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Home chip switches profiles and cold reopen keeps the last selection',
    (tester) async {
      final storage = MemoryProfilePreviewStorage();
      await tester.pumpWidget(previewApp(storage));
      await tester.pumpAndSettle();
      await createGuitar(tester);
      await openSettings(tester);
      expect(find.byKey(const Key('reset-preview-data')), findsOneWidget);
      await tapVisible(tester, find.text('Quản lý hồ sơ nhạc cụ'));
      await tapVisible(tester, find.text('Thêm hồ sơ'));
      await tapVisible(tester, find.byKey(const Key('profile-type-piano')));
      await tapVisible(tester, find.byKey(const Key('save-profile')));
      await tapVisible(tester, find.byKey(const Key('choose-profile')));
      await tapVisible(
        tester,
        find.byKey(const Key('select-profile-preview-1')),
      );
      expect(find.text('Guitar của tôi'), findsOneWidget);
      expect(find.text('Luyện gam C'), findsNothing);
      final homeState = ProviderScope.containerOf(
        tester.element(find.byType(MeloopUiShowcase)),
      ).read(showcaseControllerProvider);
      expect(homeState.saveCount, 0);

      final writesBeforeReopen = storage.writes;
      await reopen(tester, storage);
      expect(find.byType(WelcomeExample), findsNothing);
      expect(find.text('Guitar của tôi'), findsOneWidget);
      expect(storage.writes, writesBeforeReopen);
      await tapVisible(tester, find.byKey(const Key('choose-profile')));
      expect((await serviceFrom(tester).load()).profiles, hasLength(2));
      await tapVisible(
        tester,
        find.byKey(const Key('select-profile-preview-2')),
      );
      await reopen(tester, storage);
      expect(find.text('Piano của tôi'), findsOneWidget);
      expect(find.text('Guitar của tôi'), findsNothing);
      expect(find.text('Luyện gam C'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('failed reset keeps profiles and offers a retry', (tester) async {
    final storage = MemoryProfilePreviewStorage();
    await tester.pumpWidget(previewApp(storage));
    await tester.pumpAndSettle();
    await createGuitar(tester);
    await openSettings(tester);
    storage.failWrite = true;
    await tapVisible(tester, find.byKey(const Key('reset-preview-data')));
    await tapVisible(tester, find.text('Xóa và bắt đầu lại'));
    expect(find.textContaining('Hồ sơ của bạn vẫn được giữ'), findsOneWidget);
    expect(find.byType(WelcomeExample), findsNothing);
    storage.failWrite = false;
    await tapVisible(tester, find.text('Xóa và bắt đầu lại'));
    expect(find.byType(WelcomeExample), findsOneWidget);
    await reopen(tester, storage);
    expect(find.byType(WelcomeExample), findsOneWidget);
    expect((await serviceFrom(tester).load()).profiles, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an unfinished practice prevents leaving the persisted profile', (
    tester,
  ) async {
    final storage = MemoryProfilePreviewStorage();
    await tester.pumpWidget(previewApp(storage));
    await tester.pumpAndSettle();
    await createGuitar(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MeloopUiShowcase)),
    );
    final controller = container.read(meloopShellControllerProvider.notifier);
    controller.startDraft('Luyện hợp âm');
    controller.showMain();
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(const Key('choose-profile')));
    expect(find.byType(InstrumentProfilesFeature), findsNothing);
    expect(
      find.text('Hoàn tất hoặc hủy buổi luyện hiện tại trước khi đổi nhạc cụ.'),
      findsOneWidget,
    );
    expect(
      container.read(meloopShellControllerProvider).draft!.profileId,
      container.read(meloopShellControllerProvider).selectedProfileId,
    );
    expect(container.read(showcaseControllerProvider).saveCount, 0);
    controller.completeDraft();
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(const Key('choose-profile')));
    expect(find.byType(InstrumentProfilesFeature), findsOneWidget);
    expect((await serviceFrom(tester).load()).profiles, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'persisted profiles reopen with the language selected in settings',
    (tester) async {
      final storage = MemoryProfilePreviewStorage();
      final settings = InMemoryAppSettingsStore(languageCode: 'vi');
      MeloopApp app() =>
          createProfilePreviewApp(storage: storage, settingsStore: settings);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await createGuitar(tester);
      await openSettings(tester);
      await tapVisible(tester, find.text('Ngôn ngữ'));
      await tapVisible(tester, find.text('English'));
      expect(await settings.readLanguageCode(), 'en');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Guitar của tôi'), findsOneWidget);
      expect(find.text('Luyện gam C'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
