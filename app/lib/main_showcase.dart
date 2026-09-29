import 'package:flutter/material.dart';

import 'app/meloop_app.dart';
import 'frontend/application/session_form_controller.dart';
import 'frontend/showcase/meloop_ui_showcase.dart';
import 'frontend/showcase/showcase_controller.dart';

void main() => runApp(
  MeloopApp(
    overrides: [
      sessionFormSaveProvider.overrideWith(
        (ref) => ref.read(showcaseSessionSaveProvider),
      ),
    ],
    home: const MeloopUiShowcase(),
  ),
);
