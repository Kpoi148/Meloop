import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../shared/journal/journal_bootstrap.dart';
import '../../shared/journal/journal_models.dart';
import '../application/instrument_profile_service.dart';
import '../application/startup_controller.dart';
import '../components/meloop_ui.dart';
import '../showcase/meloop_ui_showcase.dart';
import '../showcase/pro_preview_page.dart';
import 'instrument_profiles_feature.dart';

typedef JournalBootstrapLoader = Future<JournalBootstrapSnapshot> Function();
final journalBootstrapLoaderProvider = Provider<JournalBootstrapLoader>(
  (ref) => throw StateError('Journal bootstrap has not been configured.'),
);

/// Real profile/bootstrap entry. Session mutations remain separate integrations.
class JournalProfileEntry extends ConsumerStatefulWidget {
  const JournalProfileEntry({super.key});
  @override
  ConsumerState<JournalProfileEntry> createState() =>
      _JournalProfileEntryState();
}

class _JournalProfileEntryState extends ConsumerState<JournalProfileEntry> {
  JournalBootstrapSnapshot? _snapshot;
  InstrumentProfile? _selected;
  bool _loading = true, _failed = false, _profilesVisible = false;
  bool _recoverOnEntry = true;
  int _generation = 0, _request = 0;
  ProfileEntryPage _entry = ProfileEntryPage.automatic;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() => _load(freshEntry: true));
  }

  Future<void> _load({bool freshEntry = false, String? selectedId}) async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final snapshot = await ref.read(journalBootstrapLoaderProvider)();
      if (!mounted || request != _request) return;
      final directory = snapshot.directory;
      setState(() {
        _snapshot = snapshot;
        _selected =
            directory.byId(selectedId ?? directory.selectedProfileId ?? '') ??
            directory.profiles.firstOrNull;
        _loading = false;
        _generation++;
        _recoverOnEntry = freshEntry && snapshot.draft != null;
        _profilesVisible =
            directory.profiles.isEmpty ||
            (freshEntry &&
                snapshot.draft == null &&
                directory.profiles.length > 1);
        _entry = ProfileEntryPage.automatic;
      });
    } catch (_) {
      if (mounted && request == _request) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  void _profiles(ProfileEntryPage entry) => setState(() {
    _entry = entry;
    _profilesVisible = true;
  });

  Future<void> _pro() => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => ProPreviewPage(
        isPro: false,
        onEnablePreview: () async {
          throw const ProfileServiceException(ProfileServiceError.storage);
        },
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    if (_loading) {
      return MeloopPage(
        child: MeloopStateView(
          state: MeloopViewState.loading,
          title: strings.profilesLoading,
        ),
      );
    }
    if (_failed) {
      return MeloopPage(
        child: MeloopStateView(
          state: MeloopViewState.error,
          title: strings.profilesLoadFailed,
          actionLabel: strings.retry,
          onAction: () => _load(freshEntry: true),
        ),
      );
    }
    if (_profilesVisible) {
      return InstrumentProfilesFeature(
        key: ValueKey((_generation, _entry)),
        entryPage: _entry,
        onOpenHome: (profile) => _load(selectedId: profile.id),
        onViewPro: _pro,
      );
    }
    final snapshot = _snapshot!;
    final draft = snapshot.draft;
    final draftProfile = draft == null
        ? null
        : snapshot.directory.byId(draft.session.profileId);
    final shellDraft = draft == null
        ? null
        : PreviewPracticeDraft(
            profileId: draft.session.profileId,
            title: draft.reviewInput?.title ?? draft.session.title,
            accumulatedSeconds:
                draft.accumulatedMilliseconds ~/ Duration.millisecondsPerSecond,
            wasRecovered: true,
            instrumentName: draftProfile!.name,
            isReview: draft.session.state == PracticeState.review,
          );
    final profiles = [
      for (final p in snapshot.directory.profiles)
        PreviewInstrumentProfile(
          id: p.id,
          name: p.name,
          instrument: MeloopInstrument.values.byName(p.instrumentType.name),
          savedSessionCount: p.savedSessionCount,
          customInstrumentName: p.customType.isEmpty ? null : p.customType,
        ),
    ];
    return ProviderScope(
      key: ValueKey((_generation, _selected!.id)),
      overrides: [
        startupSnapshotProvider.overrideWithValue(
          StartupSnapshot(
            profiles: profiles,
            selectedProfileId: _selected!.id,
            draft: shellDraft,
            recoverDraftOnEntry: _recoverOnEntry,
            hasChosenProfile: true,
          ),
        ),
        meloopShellControllerProvider.overrideWith(MeloopShellController.new),
      ],
      child: MeloopUiShowcase(
        developmentTools: false,
        profile: _selected,
        journalRecoveryReadOnly: draft != null,
        allowProfileBrowsingWithDraft: true,
        onChooseProfile: () => _profiles(ProfileEntryPage.picker),
        onManageProfiles: () => _profiles(ProfileEntryPage.manager),
        onViewPro: _pro,
      ),
    );
  }
}
