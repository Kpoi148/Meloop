import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../shared/support/contact_configuration.dart';
import '../../shared/support/contact_platform.dart';

final contactConfigurationProvider = Provider<ContactConfiguration>(
  (ref) => const ContactConfiguration(),
);

final contactPlatformProvider = Provider<ContactPlatform>(
  (ref) => throw StateError('Contact platform must be supplied by the app.'),
);

final contactSupportControllerProvider = Provider<ContactSupportController>(
  (ref) => ContactSupportController(
    configuration: ref.watch(contactConfigurationProvider),
    platform: ref.watch(contactPlatformProvider),
  ),
);

abstract final class SupportInputLimits {
  static const subjectCodePoints = 160;
  static const descriptionCodePoints = 2000;
  static final descriptionControls = RegExp(
    r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]',
  );
}

class ContactSupportController {
  const ContactSupportController({
    required this.configuration,
    required this.platform,
  });

  final ContactConfiguration configuration;
  final ContactPlatform platform;

  String? validateSubject(String value, AppLocalizations strings) =>
      value.trim().isEmpty ||
          value.runes.length > SupportInputLimits.subjectCodePoints ||
          SupportInputLimits.descriptionControls.hasMatch(value) ||
          value.contains(RegExp(r'[\r\n]'))
      ? strings.supportSubjectInvalid(SupportInputLimits.subjectCodePoints)
      : null;

  String? validateDescription(String value, AppLocalizations strings) =>
      value.runes.length > SupportInputLimits.descriptionCodePoints ||
          SupportInputLimits.descriptionControls.hasMatch(value)
      ? strings.supportDescriptionInvalid(
          SupportInputLimits.descriptionCodePoints,
        )
      : null;

  Future<SupportEmailDraft> prepareDraft({
    required String subject,
    required String description,
    required bool includeTechnicalDetails,
    required AppLocalizations strings,
  }) async {
    if (validateSubject(subject, strings) != null ||
        validateDescription(description, strings) != null) {
      throw ArgumentError('Invalid support input.');
    }
    var body = description;
    if (includeTechnicalDetails) {
      final details = await platform.readTechnicalDetails();
      final block = strings.supportDiagnosticsBlock(
        details.appVersion,
        details.androidVersion,
        details.deviceModel,
      );
      body = body.isEmpty ? block : '$body\n\n$block';
    }
    return SupportEmailDraft(
      recipient: configuration.emailAddress,
      subject: subject.trim(),
      body: body,
    );
  }
}
