import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/app/meloop_app.dart';
import 'package:meloop/frontend/application/app_settings_controller.dart';
import 'package:meloop/frontend/application/contact_support_controller.dart';
import 'package:meloop/frontend/components/meloop_ui.dart';
import 'package:meloop/frontend/support/contact_support_page.dart';
import 'package:meloop/frontend/support/privacy_policy_page.dart';
import 'package:meloop/frontend/support/support_draft_preview_page.dart';
import 'package:meloop/shared/settings/app_settings_store.dart';
import 'package:meloop/shared/support/contact_configuration.dart';
import 'package:meloop/shared/support/contact_platform.dart';

import '../support/contact_test_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader(TempoType.fontFamily);
    for (final weight in [400, 500, 600, 700]) {
      font.addFont(rootBundle.load('assets/fonts/be-vietnam-pro-$weight.ttf'));
    }
    await font.load();
  });
  final samples = <String, Widget>{
    'privacy': const PrivacyPolicyPage(),
    'support': const ContactSupportPage(),
    'support-draft': const SupportDraftPreviewPage(
      draft: SupportEmailDraft(
        recipient: 'support@example.invalid',
        subject: 'Góp ý về Meloop',
        body: 'Nội dung do người dùng nhập.',
      ),
    ),
  };

  testWidgets('Tempo visuals with original assets and Be Vietnam Pro', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final sample in samples.entries) {
      tester.view.physicalSize = const Size(390, 1400);
      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        MeloopApp(
          key: UniqueKey(),
          overrides: [
            contactConfigurationProvider.overrideWithValue(
              const ContactConfiguration(),
            ),
            contactPlatformProvider.overrideWithValue(TestContactPlatform()),
          ],
          home: RepaintBoundary(key: boundaryKey, child: sample.value),
        ),
      );
      await tester.runAsync(
        () => precacheImage(
          const AssetImage('assets/illustrations/illustrations.png'),
          boundaryKey.currentContext!,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final boundary =
            boundaryKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final rendered = await boundary.toImage();
        final bytes = await rendered.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/ui-review/${sample.key}-390.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        rendered.dispose();
      });
    }
  });

  testWidgets(
    'contact pages fit small screens, large text and keyboard in vi/en',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final locale in ['vi', 'en']) {
        for (final width in [320.0, 390.0, 460.0]) {
          for (final scale in [1.0, 3.0]) {
            for (final sample in samples.values) {
              tester.view.physicalSize = Size(width, 640);
              await tester.pumpWidget(
                MeloopApp(
                  key: UniqueKey(),
                  overrides: [
                    appSettingsStoreProvider.overrideWithValue(
                      InMemoryAppSettingsStore(languageCode: locale),
                    ),
                    contactConfigurationProvider.overrideWithValue(
                      testContactConfiguration,
                    ),
                    contactPlatformProvider.overrideWithValue(
                      TestContactPlatform(),
                    ),
                  ],
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: TextScaler.linear(scale),
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      viewInsets: const EdgeInsets.only(bottom: 280),
                    ),
                    child: child!,
                  ),
                  home: sample,
                ),
              );
              await tester.pumpAndSettle();
              expect(
                tester.takeException(),
                isNull,
                reason: '$locale/$width/$scale/${sample.runtimeType}',
              );
              final scroll = tester.state<ScrollableState>(
                find.byType(Scrollable).first,
              );
              scroll.position.jumpTo(scroll.position.maxScrollExtent);
              await tester.pumpAndSettle();
              expect(
                tester.takeException(),
                isNull,
                reason: 'scrolled $locale/$width/$scale/${sample.runtimeType}',
              );
            }
          }
        }
      }
    },
  );
}
