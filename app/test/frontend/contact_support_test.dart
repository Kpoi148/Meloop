import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/app/meloop_app.dart';
import 'package:meloop/frontend/application/app_settings_controller.dart';
import 'package:meloop/frontend/application/contact_support_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meloop/frontend/application/startup_controller.dart';
import 'package:meloop/frontend/showcase/meloop_ui_showcase.dart';
import 'package:meloop/frontend/support/contact_support_page.dart';
import 'package:meloop/frontend/support/privacy_policy_page.dart';
import 'package:meloop/frontend/support/support_draft_preview_page.dart';
import 'package:meloop/l10n/app_localizations.dart';
import 'package:meloop/shared/settings/app_settings_store.dart';
import 'package:meloop/shared/support/contact_configuration.dart';
import 'package:meloop/shared/support/contact_platform.dart';

import '../support/contact_test_platform.dart';

Future<void> mountContact(
  WidgetTester tester,
  Widget page,
  TestContactPlatform platform, {
  String language = 'vi',
  ContactConfiguration configuration = testContactConfiguration,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MeloopApp(
      overrides: [
        appSettingsStoreProvider.overrideWithValue(
          InMemoryAppSettingsStore(languageCode: language),
        ),
        contactConfigurationProvider.overrideWithValue(configuration),
        contactPlatformProvider.overrideWithValue(platform),
      ],
      home: page,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> press(WidgetTester tester, String label) async {
  final target = find.text(label).last;
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> enterSupport(
  WidgetTester tester, {
  String body = 'Góp ý của tôi',
}) async {
  await tester.enterText(
    find.byType(TextFormField).at(0),
    'Hỗ trợ + & ? tiếng Việt',
  );
  await tester.enterText(find.byType(TextFormField).at(1), body);
}

void main() {
  for (final language in ['vi', 'en']) {
    final strings = lookupAppLocalizations(Locale(language));
    testWidgets('policy opens the exact configured $language URL', (
      tester,
    ) async {
      final platform = TestContactPlatform();
      await mountContact(
        tester,
        const PrivacyPolicyPage(),
        platform,
        language: language,
      );
      expect(find.text(strings.privacyLocalBody), findsOneWidget);
      expect(find.text(strings.privacyPermissionsBody), findsNothing);
      await press(tester, strings.privacyPermissionsTitle);
      expect(find.text(strings.privacyPermissionsBody), findsOneWidget);
      await press(tester, strings.privacyOpenPublished);
      expect(
        platform.policies.single.toString(),
        language == 'vi'
            ? testContactConfiguration.privacyUrlVi
            : testContactConfiguration.privacyUrlEn,
      );
    });

    testWidgets('draft in $language excludes diagnostics until opted in', (
      tester,
    ) async {
      final platform = TestContactPlatform();
      await mountContact(
        tester,
        const ContactSupportPage(),
        platform,
        language: language,
      );
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
      expect(platform.detailsReads, 0);
      await enterSupport(tester);
      await press(tester, strings.supportPreview);
      expect(platform.drafts, isEmpty);
      final page = tester.widget<SupportDraftPreviewPage>(
        find.byType(SupportDraftPreviewPage),
      );
      expect(page.draft.body, 'Góp ý của tôi');
      expect(platform.detailsReads, 0);
      await press(tester, strings.supportCompose);
      expect(platform.drafts.single.body, page.draft.body);
      expect(
        platform.drafts.single.recipient,
        testContactConfiguration.supportEmail,
      );
      await press(tester, strings.supportEditDraft);
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).at(1))
            .controller!
            .text,
        'Góp ý của tôi',
      );
      await tester.ensureVisible(find.byType(Checkbox));
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await press(tester, strings.supportPreview);
      final optedIn = tester
          .widget<SupportDraftPreviewPage>(find.byType(SupportDraftPreviewPage))
          .draft;
      expect(
        optedIn.body,
        'Góp ý của tôi\n\n${strings.supportDiagnosticsBlock('1.2.3', '15', 'Test device')}',
      );
      expect(platform.detailsReads, 1);
      await press(tester, strings.supportEditDraft);
      await tester.ensureVisible(find.byType(Checkbox));
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await press(tester, strings.supportPreview);
      expect(
        tester
            .widget<SupportDraftPreviewPage>(
              find.byType(SupportDraftPreviewPage),
            )
            .draft
            .body,
        'Góp ý của tôi',
      );
      expect(platform.detailsReads, 1);
    });
  }

  final strings = lookupAppLocalizations(const Locale('vi'));
  testWidgets('Settings routes return to the same selected profile and tab', (
    tester,
  ) async {
    final platform = TestContactPlatform();
    await mountContact(
      tester,
      const MeloopUiShowcase(developmentTools: false),
      platform,
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MeloopUiShowcase)),
    );
    container
        .read(meloopShellControllerProvider.notifier)
        .reload(StartupSnapshot.oneProfile);
    container.read(meloopShellControllerProvider.notifier).selectTab(3);
    await tester.pumpAndSettle();
    await press(tester, strings.settingsPrivacy);
    expect(find.byType(PrivacyPolicyPage), findsOneWidget);
    await tester.ensureVisible(find.byTooltip(strings.back));
    await tester.tap(find.byTooltip(strings.back));
    await tester.pumpAndSettle();
    expect(container.read(meloopShellControllerProvider).selectedTab, 3);
    await press(tester, strings.settingsContactSupport);
    expect(find.byType(ContactSupportPage), findsOneWidget);
    await tester.ensureVisible(find.byTooltip(strings.back));
    await tester.tap(find.byTooltip(strings.back));
    await tester.pumpAndSettle();
    expect(container.read(meloopShellControllerProvider).selectedTab, 3);
    expect(
      container.read(meloopShellControllerProvider).selectedProfileId,
      StartupSnapshot.oneProfile.selectedProfileId,
    );
  });
  for (final throws in [false, true]) {
    testWidgets(
      'failed policy launch ($throws) keeps information and copy fallback',
      (tester) async {
        final platform = TestContactPlatform()
          ..opensPolicy = false
          ..throwsOnOpen = throws;
        await mountContact(tester, const PrivacyPolicyPage(), platform);
        await press(tester, strings.privacyOpenPublished);
        expect(find.text(strings.privacyOpenFailed), findsOneWidget);
        expect(find.text(strings.privacyLocalBody), findsOneWidget);
        await press(tester, strings.privacyCopyLink);
        expect(platform.copies.single, testContactConfiguration.privacyUrlVi);
        platform.throwsOnOpen = false;
        platform.opensPolicy = true;
        await press(tester, strings.privacyOpenPublished);
        expect(find.text(strings.privacyOpenFailed), findsNothing);
      },
    );

    testWidgets(
      'no email app ($throws) keeps reviewed draft and copies exact text',
      (tester) async {
        final platform = TestContactPlatform()
          ..opensEmail = false
          ..throwsOnOpen = throws;
        await mountContact(tester, const ContactSupportPage(), platform);
        await enterSupport(tester, body: 'Nội dung\nxuống dòng + & ?');
        await press(tester, strings.supportPreview);
        await press(tester, strings.supportCompose);
        expect(find.text(strings.supportEmailUnavailable), findsOneWidget);
        await press(tester, strings.supportCopyAddress);
        await press(tester, strings.supportCopyDetails);
        expect(platform.copies, [
          testContactConfiguration.supportEmail,
          'Hỗ trợ + & ? tiếng Việt\n\nNội dung\nxuống dòng + & ?',
        ]);
        expect(platform.detailsReads, 0);
      },
    );
  }

  testWidgets(
    'missing PM configuration permits review/copy without fake addresses',
    (tester) async {
      final platform = TestContactPlatform();
      await mountContact(
        tester,
        const ContactSupportPage(),
        platform,
        configuration: const ContactConfiguration(),
      );
      expect(find.text(strings.supportNotPublished), findsOneWidget);
      await enterSupport(tester);
      await press(tester, strings.supportPreview);
      await press(tester, strings.supportCompose);
      expect(platform.drafts, isEmpty);
      expect(find.text(strings.supportCopyAddress), findsNothing);
      await press(tester, strings.supportCopyDetails);
      expect(platform.copies.single, contains('Góp ý của tôi'));
    },
  );

  testWidgets(
    'failed diagnostics keeps input and permits retry without details',
    (tester) async {
      final platform = TestContactPlatform()..failsDetails = true;
      await mountContact(tester, const ContactSupportPage(), platform);
      await enterSupport(tester);
      await tester.ensureVisible(find.byType(Checkbox));
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await press(tester, strings.supportPreview);
      expect(find.text(strings.supportPreviewFailed), findsOneWidget);
      expect(find.byType(SupportDraftPreviewPage), findsNothing);
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await press(tester, strings.supportPreview);
      expect(
        tester
            .widget<SupportDraftPreviewPage>(
              find.byType(SupportDraftPreviewPage),
            )
            .draft
            .body,
        'Góp ý của tôi',
      );
    },
  );

  testWidgets(
    'double preview collects once and does not navigate after disposal',
    (tester) async {
      final platform = TestContactPlatform()
        ..pendingDetails = Completer<SupportTechnicalDetails>();
      await mountContact(tester, const ContactSupportPage(), platform);
      await enterSupport(tester);
      await tester.ensureVisible(find.byType(Checkbox));
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      final preview = find.text(strings.supportPreview);
      await tester.ensureVisible(preview);
      await tester.tap(preview);
      await tester.tap(preview);
      await tester.pump();
      expect(platform.detailsReads, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      platform.pendingDetails!.complete(
        const SupportTechnicalDetails(
          appVersion: '1',
          androidVersion: '15',
          deviceModel: 'Test device',
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('clipboard failure displays error without losing the draft', (
    tester,
  ) async {
    final platform = TestContactPlatform()..failsCopy = true;
    await mountContact(tester, const ContactSupportPage(), platform);
    await enterSupport(tester);
    await press(tester, strings.supportPreview);
    await press(tester, strings.supportCopyDetails);
    expect(find.text(strings.supportCopyFailed), findsOneWidget);
    expect(find.text('Góp ý của tôi'), findsOneWidget);
  });

  test('Unicode limits and optional description follow SRS', () {
    final controller = ContactSupportController(
      configuration: testContactConfiguration,
      platform: TestContactPlatform(),
    );
    expect(controller.validateDescription('', strings), isNull);
    expect(controller.validateDescription('🎵' * 2000, strings), isNull);
    expect(controller.validateDescription('🎵' * 2001, strings), isNotNull);
    expect(
      controller.validateDescription('Đoạn 1\nĐoạn 2\t+', strings),
      isNull,
    );
    expect(controller.validateDescription('a\u0000b', strings), isNotNull);
    expect(controller.validateSubject('🎵' * 160, strings), isNull);
    expect(controller.validateSubject('🎵' * 161, strings), isNotNull);
    expect(controller.validateSubject('a\nb', strings), isNotNull);
  });

  test(
    'release configuration validates both languages and a single address',
    () {
      expect(testContactConfiguration.isReadyForRelease, isTrue);
      expect(const ContactConfiguration().isReadyForRelease, isFalse);
      for (final url in [
        'http://example.invalid',
        'javascript:alert(1)',
        'https://user:password@example.invalid',
        'https://example.invalid/a b',
      ]) {
        expect(
          ContactConfiguration(privacyUrlVi: url).privacyUri('vi'),
          isNull,
        );
      }
      for (final email in [
        'support',
        'a@b',
        'a@example.invalid\nb@example.invalid',
        'a@example.invalid,b@example.invalid',
        'a@example.invalid?subject=x',
      ]) {
        expect(ContactConfiguration(supportEmail: email).emailAddress, isNull);
      }
    },
  );
}
