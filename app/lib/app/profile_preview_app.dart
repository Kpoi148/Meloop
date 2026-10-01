import 'package:flutter/material.dart';

import '../frontend/showcase/instrument_profile_preview.dart';
import '../frontend/showcase/profile_preview_service.dart';
import '../frontend/showcase/profile_preview_storage.dart';
import 'meloop_app.dart';
import 'profile_preview_storage.dart';

MeloopApp createProfilePreviewApp({ProfilePreviewStorage? storage}) =>
    MeloopApp(
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
