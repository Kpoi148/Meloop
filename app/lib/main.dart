import 'package:flutter/material.dart';

import 'app/meloop_app.dart';
import 'frontend/showcase/instrument_profile_preview.dart';

// Interactive FE preview while the local profile service is being implemented.
void main() => runApp(const MeloopApp(home: InstrumentProfilePreview()));
