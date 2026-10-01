import 'package:flutter/material.dart';

import '../frontend/application/app_settings_controller.dart';
import '../shared/settings/app_settings_store.dart';
import '../frontend/showcase/instrument_profile_preview.dart';
import '../frontend/showcase/profile_preview_service.dart';
import '../frontend/showcase/profile_preview_storage.dart';
import 'meloop_app.dart';
import 'journal_providers.dart';
import 'profile_preview_storage.dart';

MeloopApp createProfilePreviewApp({
  ProfilePreviewStorage? storage,
  AppSettingsStore? settingsStore,
}) => MeloopApp(
  overrides: [
    appSettingsStoreProvider.overrideWith(
      (ref) => settingsStore ?? ref.watch(journalSettingsStoreProvider),
    ),
  ],
  home: InstrumentProfilePreview(
    service: ProfilePreviewService(
      storage: storage ?? SqliteProfilePreviewStorage(),
    ),
  ),
);

void runProfilePreviewApp() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(createProfilePreviewApp());
}
