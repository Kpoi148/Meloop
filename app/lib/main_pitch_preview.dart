import 'package:flutter/material.dart';

import 'app/meloop_app.dart';
import 'frontend/application/app_settings_controller.dart';
import 'frontend/showcase/pitch_preview_launcher.dart';
import 'shared/settings/app_settings_store.dart';

/// Manual FE review entry. Run with a separate Android application ID suffix.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MeloopApp(
      overrides: [
        appSettingsStoreProvider.overrideWithValue(
          InMemoryAppSettingsStore(languageCode: 'vi'),
        ),
      ],
      home: const PitchPreviewLauncher(),
    ),
  );
}
