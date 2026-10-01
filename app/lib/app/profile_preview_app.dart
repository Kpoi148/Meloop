import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import '../backend/journal/sqlite_instrument_profile_service.dart';
import '../backend/journal/sqlite_journal_bootstrap.dart';
import '../frontend/application/instrument_profile_service.dart';
import '../frontend/profiles/journal_profile_entry.dart';

import '../frontend/application/app_settings_controller.dart';
import '../frontend/practice_sessions/practice_session.dart';
import '../shared/settings/app_settings_store.dart';
import '../frontend/showcase/instrument_profile_preview.dart';
import '../frontend/showcase/practice_session_examples.dart';
import '../frontend/showcase/profile_preview_service.dart';
import '../frontend/showcase/profile_preview_storage.dart';
import 'meloop_app.dart';
import 'journal_providers.dart';
import 'profile_preview_storage.dart';

MeloopApp createProfilePreviewApp({
  ProfilePreviewStorage? storage,
  AppSettingsStore? settingsStore,
}) => MeloopApp(
  overrides: [
    appSettingsStoreProvider.overrideWith(
      (ref) => settingsStore ?? ref.watch(journalSettingsStoreProvider),
    ),
    practiceSessionsLoaderProvider.overrideWith(
      (ref) => ref.watch(practiceSessionsPreviewLoaderProvider),
    ),
  ],
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

/// Profile storage is real; practice/session screens remain FE previews until
/// their journal integration steps. Preview snapshots are never imported.
MeloopApp createJournalProfileApp({List<Override> overrides = const []}) =>
    MeloopApp(
      overrides: [
        appSettingsStoreProvider.overrideWith(
          (ref) => ref.watch(journalSettingsStoreProvider),
        ),
        practiceSessionsLoaderProvider.overrideWith(
          (ref) => ref.watch(practiceSessionsPreviewLoaderProvider),
        ),
        ...overrides,
      ],
      home: const _JournalProfiles(),
    );

class _JournalProfiles extends ConsumerWidget {
  const _JournalProfiles();
  @override
  Widget build(BuildContext context, WidgetRef ref) => ProviderScope(
    overrides: [
      instrumentProfileServiceProvider.overrideWithValue(
        SqliteInstrumentProfileService(
          owner: ref.watch(journalDatabaseOwnerProvider),
          clock: ref.watch(journalClockProvider),
          initialLanguage: Localizations.localeOf(context).languageCode,
        ),
      ),
      journalBootstrapLoaderProvider.overrideWithValue(
        SqliteJournalBootstrap(
          owner: ref.watch(journalDatabaseOwnerProvider),
          clock: ref.watch(journalClockProvider),
          initialLanguage: Localizations.localeOf(context).languageCode,
        ).read,
      ),
    ],
    child: const JournalProfileEntry(),
  );
}
