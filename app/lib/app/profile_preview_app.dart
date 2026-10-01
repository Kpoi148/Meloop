import 'package:flutter/material.dart';

import '../backend/settings/sqlite_app_settings_store.dart';
import '../frontend/application/app_settings_controller.dart';
import '../frontend/practice_sessions/practice_session.dart';
import '../shared/settings/app_settings_store.dart';
import '../frontend/showcase/instrument_profile_preview.dart';
import '../frontend/showcase/practice_session_examples.dart';
import '../frontend/showcase/profile_preview_service.dart';
import '../frontend/showcase/profile_preview_storage.dart';
import 'meloop_app.dart';
import 'profile_preview_storage.dart';

MeloopApp createProfilePreviewApp({
  ProfilePreviewStorage? storage,
  AppSettingsStore? settingsStore,
}) => MeloopApp(
  overrides: [
    appSettingsStoreProvider.overrideWithValue(
      settingsStore ?? const SqliteAppSettingsStore(),
    ),
    practiceSessionsLoaderProvider.overrideWith(
      (ref) => ref.watch(practiceSessionsPreviewLoaderProvider),
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
