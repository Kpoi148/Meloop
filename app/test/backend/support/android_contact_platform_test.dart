import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/backend/support/android_contact_platform.dart';
import 'package:meloop/shared/support/contact_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'platform sends only reviewed fields, with no attachment paths',
    () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(AndroidContactPlatform.channel, (
            call,
          ) async {
            calls.add(call);
            return true;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(AndroidContactPlatform.channel, null),
      );
      const adapter = AndroidContactPlatform();
      expect(
        await adapter.openEmailDraft(
          const SupportEmailDraft(recipient: null, subject: 'Test', body: ''),
        ),
        isFalse,
      );
      expect(calls, isEmpty);
      const draft = SupportEmailDraft(
        recipient: 'support@example.invalid',
        subject: 'Góp ý + & ?',
        body: 'Dòng 1\nDòng 2 + & ?',
      );
      expect(await adapter.openEmailDraft(draft), isTrue);
      expect(calls.single.method, 'openEmailDraft');
      expect(calls.single.arguments, {
        'recipient': draft.recipient,
        'subject': draft.subject,
        'body': draft.body,
      });
    },
  );
}
