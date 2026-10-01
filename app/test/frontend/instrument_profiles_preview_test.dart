import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/frontend/application/instrument_profile_service.dart';
import 'package:meloop/frontend/components/meloop_ui.dart';
import 'package:meloop/frontend/profiles/instrument_profiles_feature.dart';
import 'package:meloop/frontend/showcase/welcome_example.dart';
import 'package:meloop/main.dart' as app;
import 'package:meloop/main_showcase.dart' as showcase;

void main() {
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

  testWidgets('default app resets all profiles only after confirmation', (
    tester,
  ) async {
    app.main();
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeExample), findsOneWidget);
    final originalService = serviceFrom(tester);
    await createGuitar(tester);
    await tapVisible(tester, find.text('Quản lý hồ sơ'));
    await tapVisible(tester, find.text('Thêm hồ sơ'));
    await tapVisible(tester, find.byKey(const Key('profile-type-piano')));
    await tapVisible(tester, find.byKey(const Key('save-profile')));
    expect((await originalService.load()).profiles, hasLength(2));

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

    // The old name is available again and no other profile survives the reset.
    await createGuitar(tester);
    expect((await newService.load()).profiles.single.name, 'Guitar của tôi');
    expect(tester.takeException(), isNull);
  });

  testWidgets('showcase settings reset opens the interactive welcome flow', (
    tester,
  ) async {
    showcase.main();
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
    expect(find.text('Quản lý hồ sơ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
