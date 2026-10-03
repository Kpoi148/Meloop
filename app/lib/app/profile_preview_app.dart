import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import '../backend/journal/sqlite_instrument_profile_service.dart';
import '../backend/journal/sqlite_journal_bootstrap.dart';
import '../backend/journal/sqlite_practice_start_service.dart';
import '../frontend/application/practice_review_provider.dart';
import 'journal_practice_adapter.dart';
import '../frontend/application/practice_start_service.dart';
import '../frontend/application/practice_timer_service.dart';
import '../frontend/application/instrument_profile_service.dart';
import '../frontend/profiles/journal_profile_entry.dart';

import '../frontend/application/app_settings_controller.dart';
import '../frontend/practice_sessions/practice_session.dart';
import '../frontend/practice_sessions/practice_session_actions.dart';
import '../shared/settings/app_settings_store.dart';
import '../frontend/showcase/instrument_profile_preview.dart';
import '../frontend/showcase/practice_session_examples.dart';
import '../frontend/showcase/profile_preview_service.dart';
import '../frontend/showcase/profile_preview_storage.dart';
import 'meloop_app.dart';
import 'contact_dependencies.dart';
import 'journal_providers.dart';
import 'journal_practice_lifecycle.dart';
import 'profile_preview_storage.dart';

MeloopApp createProfilePreviewApp({
  ProfilePreviewStorage? storage,
  AppSettingsStore? settingsStore,
}) => MeloopApp(
  overrides: [
    ...contactDependencies(),
    appSettingsStoreProvider.overrideWith(
      (ref) => settingsStore ?? ref.watch(journalSettingsStoreProvider),
    ),
    practiceSessionsLoaderProvider.overrideWith(
      (ref) => ref.watch(practiceSessionsPreviewLoaderProvider),
    ),
    ..._sessionPreviewActions,
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

/// Journal data and timer share one app scope; preview snapshots stay isolated.
MeloopApp createJournalProfileApp({List<Override> overrides = const []}) =>
    MeloopApp(
      overrides: [
        ...contactDependencies(),
        practiceTimerServiceProvider.overrideWith(
          (ref) => ref.watch(journalPracticeTimerProvider),
        ),
        appSettingsStoreProvider.overrideWith(
          (ref) => ref.watch(journalSettingsStoreProvider),
        ),
        practiceSessionsLoaderProvider.overrideWith(
          (ref) =>
              (profile) async =>
                  (await ref
                          .read(journalSessionReaderProvider)
                          .saved(profileId: profile.id))
                      .map(presentPracticeSession)
                      .toList(),
        ),
        practiceReviewLoadProvider.overrideWith(
          (ref) => ref.watch(journalReviewServiceProvider).read,
        ),
        practiceReviewPersistProvider.overrideWith(
          (ref) => ref.watch(journalReviewServiceProvider).persistInput,
        ),
        practiceSessionUpdateProvider.overrideWith((ref) {
          final service = ref.watch(journalSessionUpdateServiceProvider);
          return (session, values) async {
            final updated = presentPracticeSession(
              await service.update(
                profileId: session.profileId,
                sessionId: session.id,
                values: journalReviewValues(values),
              ),
              original: session,
            );
            if (ref.mounted) ref.invalidate(practiceSessionsProvider);
            return updated;
          };
        }),
        practiceTitleUpdateProvider.overrideWith(
          (ref) => ref.watch(journalReviewServiceProvider).rename,
        ),
        practiceReviewSaveProvider.overrideWith((ref) {
          final review = ref.watch(journalReviewServiceProvider);
          return (sessionId, values) async => presentPracticeSession(
            await review.save(sessionId, journalReviewValues(values)),
          );
        }),
        practiceSessionDeleteProvider.overrideWith((ref) {
          final service = ref.watch(journalSessionDeleteServiceProvider);
          return (session) => service.delete(
            profileId: session.profileId,
            sessionId: session.id,
          );
        }),
        ...overrides,
      ],
      home: const JournalPracticeLifecycle(child: _JournalProfiles()),
    );

final _sessionPreviewActions = <Override>[
  practiceSessionUpdateProvider.overrideWith(
    (ref) => ref.read(practiceSessionPreviewChangesProvider.notifier).update,
  ),
  practiceSessionDeleteProvider.overrideWith(
    (ref) => ref.read(practiceSessionPreviewChangesProvider.notifier).delete,
  ),
  practiceRecordingDeleteProvider.overrideWith(
    (ref) => ref
        .read(practiceSessionPreviewChangesProvider.notifier)
        .deleteRecording,
  ),
];

class _JournalProfiles extends ConsumerWidget {
  const _JournalProfiles();
  @override
  Widget build(BuildContext context, WidgetRef ref) => ProviderScope(
    overrides: [
      practiceStartServiceProvider.overrideWithValue(
        SqlitePracticeStartService(
          owner: ref.watch(journalDatabaseOwnerProvider),
          clock: ref.watch(journalClockProvider),
        ),
      ),
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
