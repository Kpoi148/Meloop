import 'package:flutter/material.dart';

import 'app/meloop_app.dart';
import 'frontend/application/app_settings_controller.dart';
import 'frontend/application/session_form_controller.dart';
import 'frontend/application/startup_controller.dart';
import 'frontend/showcase/meloop_ui_showcase.dart';
import 'frontend/showcase/showcase_controller.dart';
import 'shared/settings/app_settings_store.dart';

final _showcaseSettings = InMemoryAppSettingsStore(languageCode: 'vi');

void main() => runApp(
  MeloopApp(
    overrides: [
      appSettingsStoreProvider.overrideWithValue(_showcaseSettings),
      startupSnapshotProvider.overrideWithValue(StartupSnapshot.manyProfiles),
      sessionFormSaveProvider.overrideWith(
        (ref) => ref.read(showcaseSessionSaveProvider),
      ),
    ],
    home: const MeloopUiShowcase(),
  ),
);
