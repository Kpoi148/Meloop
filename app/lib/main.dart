import 'package:flutter/material.dart';

import 'app/meloop_app.dart';
import 'backend/settings/sqlite_app_settings_store.dart';
import 'frontend/application/app_settings_controller.dart';
import 'frontend/application/startup_controller.dart';
import 'frontend/showcase/meloop_ui_showcase.dart';

void main() => runApp(
  MeloopApp(
    overrides: [
      appSettingsStoreProvider.overrideWithValue(
        const SqliteAppSettingsStore(),
      ),
      // Profile/draft repositories will replace this empty UI holder.
      startupSnapshotProvider.overrideWithValue(StartupSnapshot.empty),
    ],
    home: const MeloopUiShowcase(developmentTools: false),
  ),
);
