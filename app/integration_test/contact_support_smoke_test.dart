import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meloop/app/meloop_app.dart';
import 'package:meloop/backend/support/android_contact_platform.dart';
import 'package:meloop/frontend/application/contact_support_controller.dart';
import 'package:meloop/frontend/support/contact_support_page.dart';
import 'package:meloop/frontend/support/support_draft_preview_page.dart';
import 'package:meloop/shared/support/contact_platform.dart';

import '../test/support/contact_test_platform.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Android: opt-in metadata, reviewed draft and platform handoff', (
    tester,
  ) async {
    const adapter = AndroidContactPlatform();
    await tester.pumpWidget(
      MeloopApp(
        overrides: [
          contactConfigurationProvider.overrideWithValue(
            testContactConfiguration,
          ),
          contactPlatformProvider.overrideWithValue(adapter),
        ],
        home: const ContactSupportPage(),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
    await tester.enterText(find.byType(TextFormField).at(0), 'Meloop QA + & ?');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Synthetic support request.\nNo journal data.',
    );
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Xem trước nội dung'));
    await tester.tap(find.text('Xem trước nội dung'));
    await tester.pumpAndSettle();
    final draft = tester
        .widget<SupportDraftPreviewPage>(find.byType(SupportDraftPreviewPage))
        .draft;
    expect(draft.body, contains('Phiên bản Android: 15'));
    expect(draft.body, contains('Mẫu thiết bị:'));
    await adapter.copyText(draft.body);
    final copied = await Clipboard.getData(Clipboard.kTextPlain);
    expect(copied!.text, draft.body);
    // Do not leave even synthetic support content on the emulator clipboard.
    await adapter.copyText('');
    await expectLater(
      adapter.openPrivacyPolicy(Uri.parse('http://example.invalid')),
      throwsA(isA<PlatformException>()),
    );
    // This opens a compose activity, never sends. The emulator has Gmail installed.
    expect(
      await adapter.openEmailDraft(
        SupportEmailDraft(
          recipient: draft.recipient,
          subject: draft.subject,
          body: draft.body,
        ),
      ),
      isTrue,
    );
  });
}
