/// Only these three non-content fields may enter an opted-in support draft.
class SupportTechnicalDetails {
  const SupportTechnicalDetails({
    required this.appVersion,
    required this.androidVersion,
    required this.deviceModel,
  });

  final String appVersion;
  final String androidVersion;
  final String deviceModel;
}

class SupportEmailDraft {
  const SupportEmailDraft({
    required this.recipient,
    required this.subject,
    required this.body,
  });

  final String? recipient;
  final String subject;
  final String body;
}

abstract interface class ContactPlatform {
  Future<bool> openPrivacyPolicy(Uri uri);
  Future<SupportTechnicalDetails> readTechnicalDetails();
  Future<bool> openEmailDraft(SupportEmailDraft draft);
  Future<void> copyText(String text);
}
