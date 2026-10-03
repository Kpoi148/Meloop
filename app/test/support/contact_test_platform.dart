import 'dart:async';

import 'package:meloop/shared/support/contact_configuration.dart';
import 'package:meloop/shared/support/contact_platform.dart';

const testContactConfiguration = ContactConfiguration(
  privacyUrlVi: 'https://example.invalid/privacy/vi?release=1',
  privacyUrlEn: 'https://example.invalid/privacy/en?release=1',
  supportEmail: 'support@example.invalid',
);

class TestContactPlatform implements ContactPlatform {
  bool opensPolicy = true;
  bool opensEmail = true;
  bool failsDetails = false;
  bool failsCopy = false;
  bool throwsOnOpen = false;
  int detailsReads = 0;
  final policies = <Uri>[];
  final drafts = <SupportEmailDraft>[];
  final copies = <String>[];
  Completer<SupportTechnicalDetails>? pendingDetails;

  @override
  Future<bool> openPrivacyPolicy(Uri uri) async {
    policies.add(uri);
    if (throwsOnOpen) throw StateError('Unavailable.');
    return opensPolicy;
  }

  @override
  Future<SupportTechnicalDetails> readTechnicalDetails() async {
    detailsReads++;
    if (failsDetails) throw StateError('Unavailable.');
    if (pendingDetails != null) return pendingDetails!.future;
    return const SupportTechnicalDetails(
      appVersion: '1.2.3',
      androidVersion: '15',
      deviceModel: 'Test device',
    );
  }

  @override
  Future<bool> openEmailDraft(SupportEmailDraft draft) async {
    drafts.add(draft);
    if (throwsOnOpen) throw StateError('Unavailable.');
    return opensEmail;
  }

  @override
  Future<void> copyText(String text) async {
    if (failsCopy) throw StateError('Unavailable.');
    copies.add(text);
  }
}
