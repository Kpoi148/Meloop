import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import '../backend/support/android_contact_platform.dart';
import '../frontend/application/contact_support_controller.dart';
import '../shared/support/contact_configuration.dart';

const releaseContactConfiguration = ContactConfiguration(
  privacyUrlVi: String.fromEnvironment('MELOOP_PRIVACY_URL_VI'),
  privacyUrlEn: String.fromEnvironment('MELOOP_PRIVACY_URL_EN'),
  supportEmail: String.fromEnvironment('MELOOP_SUPPORT_EMAIL'),
);

List<Override> contactDependencies() {
  if (kReleaseMode && !releaseContactConfiguration.isReadyForRelease) {
    throw StateError('Published privacy URLs and support email are required.');
  }
  return [
    contactConfigurationProvider.overrideWithValue(releaseContactConfiguration),
    contactPlatformProvider.overrideWithValue(const AndroidContactPlatform()),
  ];
}
