import 'package:flutter/services.dart';

import '../../shared/support/contact_platform.dart';

class AndroidContactPlatform implements ContactPlatform {
  const AndroidContactPlatform();

  static const channel = MethodChannel('meloop/contact_support');

  @override
  Future<bool> openPrivacyPolicy(Uri uri) async =>
      await channel.invokeMethod<bool>('openPrivacyPolicy', uri.toString()) ??
      false;

  @override
  Future<SupportTechnicalDetails> readTechnicalDetails() async {
    final values = await channel.invokeMapMethod<String, String>(
      'readTechnicalDetails',
    );
    if (values == null ||
        [
          'appVersion',
          'androidVersion',
          'deviceModel',
        ].any((key) => values[key]?.isNotEmpty != true)) {
      throw StateError('Technical details unavailable.');
    }
    return SupportTechnicalDetails(
      appVersion: values['appVersion']!,
      androidVersion: values['androidVersion']!,
      deviceModel: values['deviceModel']!,
    );
  }

  @override
  Future<bool> openEmailDraft(SupportEmailDraft draft) async {
    if (draft.recipient == null) return false;
    return await channel.invokeMethod<bool>('openEmailDraft', {
          'recipient': draft.recipient,
          'subject': draft.subject,
          'body': draft.body,
        }) ??
        false;
  }

  @override
  Future<void> copyText(String text) =>
      Clipboard.setData(ClipboardData(text: text));
}
