import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import '../frontend/application/app_settings_controller.dart';
import '../frontend/theme/meloop_theme.dart';
import '../l10n/app_localizations.dart';

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
    child: _MeloopMaterialApp(home: home, builder: builder),
  );
}

class _MeloopMaterialApp extends ConsumerWidget {
  const _MeloopMaterialApp({required this.home, this.builder});

  final Widget home;
  final TransitionBuilder? builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(appLocaleProvider).value ?? const Locale('vi');
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: MeloopTheme.light,
      builder: builder,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: home,
    );
  }
}
