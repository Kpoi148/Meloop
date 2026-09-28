import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../frontend/theme/meloop_theme.dart';

class MeloopApp extends StatelessWidget {
  const MeloopApp({super.key, required this.home, this.builder});
  final Widget home;
  final TransitionBuilder? builder;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Meloop',
    debugShowCheckedModeBanner: false,
    theme: MeloopTheme.light,
    builder: builder,
    locale: const Locale('vi'),
    supportedLocales: const [Locale('vi'), Locale('en')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: home,
  );
}
