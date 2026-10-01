import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import '../frontend/application/app_settings_controller.dart';
import '../frontend/application/practice_session_provider.dart';
import '../frontend/application/session_form_controller.dart';
import '../frontend/application/startup_controller.dart';
import '../frontend/showcase/practice_preview_service.dart';
import '../frontend/theme/meloop_theme.dart';
import '../l10n/app_localizations.dart';

class MeloopApp extends StatelessWidget {
  const MeloopApp({
    super.key,
    required this.home,
    this.builder,
    this.overrides = const [],
    this.practiceSessionService,
  });
  final Widget home;
  final TransitionBuilder? builder;
  final List<Override> overrides;
  final PracticeSessionService? practiceSessionService;
  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: [
      // The current entry is an FE preview. Production replaces this adapter.
      practiceSessionServiceProvider.overrideWith((ref) {
        if (practiceSessionService != null) return practiceSessionService;
        final service = PracticePreviewService.fromSnapshot(
          ref.read(startupSnapshotProvider),
          onSave: (values) => ref.read(sessionFormSaveProvider)(values),
        );
        ref.onDispose(service.dispose);
        return service;
      }),
      ...overrides,
    ],
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
