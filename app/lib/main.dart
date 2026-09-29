import 'package:flutter/material.dart';

import 'app/meloop_app.dart';
import 'frontend/showcase/welcome_example.dart';

// Backend controllers will be injected by the feature work. No seeded journal.
void main() => runApp(const MeloopApp(home: WelcomeExample()));
