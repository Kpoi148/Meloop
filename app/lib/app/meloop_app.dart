import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import '../frontend/theme/meloop_theme.dart';

class MeloopApp extends StatelessWidget {
  const MeloopApp({
    super.key,
    required this.home,
    this.builder,
    this.overrides = const [],
  });
  final Widget home;
  final TransitionBuilder? builder;
  final List<Override> overrides;
  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      title: 'Meloop',
      debugShowCheckedModeBanner: false,
      theme: MeloopTheme.light,
      builder: builder,
      locale: const Locale('vi'),
      supportedLocales: const [Locale('vi'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: home,
    ),
  );
}
