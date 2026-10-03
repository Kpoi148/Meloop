import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../shared/journal/journal_models.dart' show PracticeState;
import '../application/app_settings_controller.dart';
import '../application/instrument_profile_service.dart';
import '../application/startup_controller.dart';
import '../application/practice_timer_service.dart';
import '../components/meloop_ui.dart';
import '../practice/practice_tools_page.dart';
import '../pitch/pitch_route.dart';
import '../recording/recording_empty_page.dart';
import '../support/privacy_policy_page.dart';
import '../support/contact_support_page.dart';
import '../practice_sessions/practice_sessions_tab.dart';
import '../practice_sessions/practice_session.dart';
import '../home/practice_overview_provider.dart';
import '../home/practice_progress_page.dart';
import 'component_catalog.dart';
import 'home_example.dart';
import 'instrument_profile_preview.dart';
import 'instrument_profiles_example.dart';
import 'instrument_picker_example.dart';
import 'language_selector.dart';
import 'metronome_example.dart';
import 'preview_copy.dart';
import 'recording_example.dart';
import 'recordings_example.dart';
import 'profile_form_example.dart';
import 'preview_data_reset_button.dart';
import 'pro_preview_page.dart';
import 'session_form_example.dart';
import 'settings_example.dart';
import 'showcase_controller.dart';
import 'setup_example.dart';
import 'timer_example.dart';
import 'welcome_example.dart';

/// Development entry point; sample records are never written to journal storage.
class MeloopUiShowcase extends ConsumerStatefulWidget {
  const MeloopUiShowcase({
    super.key,
    this.developmentTools = true,
    this.profile,
    this.onChooseProfile,
    this.onManageProfiles,
    this.onResetData,
    this.isPro = false,
    this.onViewPro,
    this.journalRecoveryReadOnly = false,
    this.allowProfileBrowsingWithDraft = false,
    this.onStartDraft,
  });

  final bool developmentTools;
  final bool journalRecoveryReadOnly;
  final bool allowProfileBrowsingWithDraft;
  final Future<PreviewPracticeDraft> Function(
    String requestId,
    String profileId,
    String title,
  )?
  onStartDraft;
  final InstrumentProfile? profile;
  final VoidCallback? onChooseProfile, onManageProfiles;
  final FutureOr<void> Function()? onResetData;
  final bool isPro;
  final VoidCallback? onViewPro;

  @override
  ConsumerState<MeloopUiShowcase> createState() => _MeloopUiShowcaseState();
}

class _MeloopUiShowcaseState extends ConsumerState<MeloopUiShowcase>
    with WidgetsBindingObserver {
  final _practiceScrollControllers = <String, ScrollController>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(practiceCalendarDayProvider);
      ref.invalidate(practiceSessionsProvider);
      ref.invalidate(weeklyPracticeGoalProvider);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final controller in _practiceScrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _catalog() => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => const ComponentCatalog()));

  void _contactHome() {
    Navigator.of(context).pop();
    ref.read(meloopShellControllerProvider.notifier).selectTab(0);
  }

  void _privacy() => Navigator.of(context).push<void>(
    MaterialPageRoute(builder: (_) => PrivacyPolicyPage(onHome: _contactHome)),
  );

  void _support() => Navigator.of(context).push<void>(
    MaterialPageRoute(builder: (_) => ContactSupportPage(onHome: _contactHome)),
  );

  void _tools() => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (toolsContext) => PracticeToolsPage(
        onOpenPitch: () => Navigator.of(toolsContext).push<void>(
          MaterialPageRoute(
            builder: (_) => PitchRoute(onHome: () => _toolsHome(toolsContext)),
          ),
        ),
        onOpenMetronome: () => Navigator.of(toolsContext).push<void>(
          MaterialPageRoute(
            builder: (_) =>
                MetronomeExample(onHome: () => _toolsHome(toolsContext)),
          ),
        ),
        onOpenRecording: () => _recording(toolsContext),
        onOpenRecordings: () => _recordings(toolsContext),
      ),
    ),
  );

  void _toolsHome(BuildContext toolsContext) {
    Navigator.of(toolsContext).pop();
    ref.read(meloopShellControllerProvider.notifier).selectTab(0);
  }

  Future<void> _recordings(BuildContext sourceContext) async {
    final profile = ref.read(meloopShellControllerProvider).selectedProfile;
    if (profile == null) return;
    await Navigator.of(sourceContext).push<void>(
      MaterialPageRoute(
        builder: (recordingsContext) => RecordingsExample(
          profile: profile,
          onHome: () {
            Navigator.of(sourceContext).popUntil((route) => route.isFirst);
            ref.read(meloopShellControllerProvider.notifier).selectTab(0);
          },
          onRecordPractice: () => _recording(recordingsContext),
        ),
      ),
    );
  }

  Future<void> _recording(BuildContext sourceContext) async {
    final shell = ref.read(meloopShellControllerProvider);
    final profile = shell.selectedProfile;
    if (profile == null) return;
    final draft = shell.selectedDraft;
    final sessionId = draft?.sessionId;
    final snapshot = ref.read(practiceTimerServiceProvider)?.snapshot;
    await Navigator.of(sourceContext).push<void>(
      MaterialPageRoute(
        builder: (recordingContext) {
          if (sessionId != null &&
              !draft!.isReview &&
              snapshot?.state != PracticeState.review &&
              snapshot?.state != PracticeState.saved) {
            return RecordingExample(
              sessionId: sessionId,
              title: draft.title,
              profileName: profileDisplayName(context.l10n, profile),
              onHome: () {
                Navigator.of(sourceContext).popUntil((route) => route.isFirst);
                ref.read(meloopShellControllerProvider.notifier).selectTab(0);
              },
            );
          }
          return RecordingEmptyPage(
            onBack: () => Navigator.of(recordingContext).pop(),
            onHome: () {
              Navigator.of(recordingContext).pop();
              Navigator.of(sourceContext).popUntil((route) => route.isFirst);
              ref.read(meloopShellControllerProvider.notifier).selectTab(0);
            },
            onCreatePractice: () async {
              await _setup(profile);
              if (!mounted || !recordingContext.mounted) return;
              if (ref.read(meloopShellControllerProvider).selectedDraft !=
                  null) {
                Navigator.of(recordingContext)
                    .popUntil((route) => route.isFirst);
              }
            },
          );
        },
      ),
    );
  }

  void _resetData() {
    ref.invalidate(showcaseControllerProvider);
    Navigator.of(context).pushAndRemoveUntil<void>(
      MaterialPageRoute(builder: (_) => const InstrumentProfilePreview()),
      (_) => false,
    );
  }

  void _openProfilePage(VoidCallback open) {
    if (!widget.allowProfileBrowsingWithDraft &&
        widget.profile != null &&
        ref.read(meloopShellControllerProvider).draft != null) {
      MeloopNotifications.show(context, context.l10n.unfinishedSessionMessage);
      return;
    }
    open();
  }

  void _profileForm() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (routeContext) => ProfileFormExample(
        onBack: () => Navigator.of(routeContext).pop(),
        onSave: (name, instrument) {
          ref
              .read(meloopShellControllerProvider.notifier)
              .addProfile(name: name, instrument: instrument);
          Navigator.of(routeContext).pop();
        },
      ),
    ),
  );

  Future<void> _setup(PreviewInstrumentProfile profile) async {
    if (ref.read(meloopShellControllerProvider).selectedDraft != null) {
      ref.read(meloopShellControllerProvider.notifier).showTimer();
      return;
    }
    final route = MaterialPageRoute<void>(
      builder: (_) => SetupExample(
        profile: profile,
        onStart: ref.read(meloopShellControllerProvider.notifier).startDraft,
        onJournalStart: widget.onStartDraft == null
            ? null
            : (requestId, title) async {
                final draft = await widget.onStartDraft!(
                  requestId,
                  profile.id,
                  title,
                );
                if (!mounted) return;
                ref
                    .read(meloopShellControllerProvider.notifier)
                    .openStoredDraft(draft);
              },
      ),
    );
    await Navigator.of(context).push(route);
    await route.completed;
  }

  void _profiles() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (routeContext) => Consumer(
        builder: (context, profilesRef, _) {
          final shell = profilesRef.watch(meloopShellControllerProvider);
          return InstrumentProfilesExample(
            profiles: shell.profiles,
            selectedProfileId: shell.selectedProfileId,
            onBack: () => Navigator.of(routeContext).pop(),
            onHome: () {
              Navigator.of(routeContext).pop();
              profilesRef
                  .read(meloopShellControllerProvider.notifier)
                  .selectTab(0);
            },
            onAdd: _profileForm,
          );
        },
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final shell = ref.watch(meloopShellControllerProvider);
    final shellController = ref.read(meloopShellControllerProvider.notifier);
    final showcase = ref.watch(showcaseControllerProvider);
    final showcaseController = ref.read(showcaseControllerProvider.notifier);

    return switch (shell.destination) {
      StartupDestination.welcome => WelcomeExample(
        onCreateProfile: _profileForm,
      ),
      StartupDestination.profilePicker => InstrumentPickerExample(
        profiles: shell.profiles,
        selectedProfileId: shell.selectedProfileId,
        onSelect: shellController.selectProfile,
        onAdd: _profileForm,
        onBack: shell.requiresProfileSelection
            ? null
            : shellController.showMain,
      ),
      StartupDestination.recoveredTimer => TimerExample(
        onOpenRecording: _recording,
        readOnly:
            widget.journalRecoveryReadOnly ||
            (shell.draft?.sessionId != null &&
                ref.read(practiceTimerServiceProvider) == null),
      ),
      StartupDestination.main => _mainTabs(
        shell,
        shellController,
        showcase,
        showcaseController,
      ),
    };
  }

  Widget _mainTabs(
    MeloopShellState shell,
    MeloopShellController shellController,
    ShowcaseState showcase,
    ShowcaseController showcaseController,
  ) {
    final profile = shell.selectedProfile;
    if (profile == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        shellController.reload(StartupSnapshot.empty);
      });
      return const SizedBox.shrink();
    }
    final navigation = MeloopBottomNavigation(
      selectedIndex: shell.selectedTab,
      onSelected: shellController.selectTab,
      compact: shell.selectedTab == 1,
    );
    if (shell.selectedTab == 1) {
      return PracticeSessionsTab(
        key: ValueKey(profile.id),
        profile: profile,
        draft: shell.selectedDraft,
        scrollController: _practiceScrollControllers.putIfAbsent(
          profile.id,
          ScrollController.new,
        ),
        bottomNavigation: navigation,
        onCreate: () => _setup(profile),
        onOpenRecording: _recording,
        onContinue: shellController.showTimer,
        onHome: () => shellController.selectTab(0),
        onInstrument: () => _openProfilePage(
          widget.onChooseProfile ?? shellController.showProfilePicker,
        ),
      );
    }
    return MeloopPage(
      bottomNavigation: navigation,
      child: switch (shell.selectedTab) {
        0 => HomeExample(
          overview: ref.watch(practiceOverviewProvider(profile)),
          profile: profile,
          draft: shell.selectedDraft,
          onCreate: () => _setup(profile),
          onProgress: () => shellController.selectTab(2),
          onTools: _tools,
          onRetry: () => _reloadOverview(profile),
          onInstrument: () => _openProfilePage(
            widget.onChooseProfile ?? shellController.showProfilePicker,
          ),
        ),
        2 => PracticeProgressPage(
          profile: profile,
          overview: ref.watch(practiceOverviewProvider(profile)),
          onRetry: () => _reloadOverview(profile),
          onHistory: () => shellController.selectTab(1),
          onInstrument: () => _openProfilePage(
            widget.onChooseProfile ?? shellController.showProfilePicker,
          ),
        ),
        _ => _settings(profile, showcase, showcaseController),
      },
    );
  }

  void _reloadOverview(PreviewInstrumentProfile profile) {
    ref.invalidate(practiceSessionsProvider(profile));
    ref.invalidate(weeklyPracticeGoalProvider(profile.id));
    ref.invalidate(practiceCalendarDayProvider);
  }

  Widget _settings(
    PreviewInstrumentProfile profile,
    ShowcaseState state,
    ShowcaseController controller,
  ) {
    final strings = context.l10n;
    final settings = SettingsExample(
      profile: profile,
      language: _settingsLanguage(),
      onLanguage: () => showLanguageSelector(context, ref),
      onProfiles: () => _openProfilePage(widget.onManageProfiles ?? _profiles),
      isPro: widget.isPro,
      onPro: widget.onViewPro,
      onRestorePro: () => showProRestoreNotice(context),
      onPrivacy: _privacy,
      onSupport: _support,
    );
    if (widget.profile != null && widget.onResetData != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          settings,
          const SizedBox(height: TempoSpace.page),
          PreviewDataResetButton(onReset: widget.onResetData!),
        ],
      );
    }
    if (!widget.developmentTools) return settings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        settings,
        const SizedBox(height: TempoSpace.page),
        MeloopButton(
          label: strings.componentCatalog,
          style: MeloopButtonStyle.yellow,
          onPressed: _catalog,
        ),
        const SizedBox(height: TempoSpace.md),
        MeloopButton(
          label: strings.openSessionForm,
          style: MeloopButtonStyle.outline,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const SessionFormExample()),
          ),
        ),
        const SizedBox(height: TempoSpace.md),
        MeloopToggle(
          label: strings.simulateNextSaveFailure,
          value: state.failNextSave,
          onChanged: controller.simulateFailure,
        ),
        const SizedBox(height: TempoSpace.md),
        MeloopButton(
          label: strings.openWelcomePreview,
          style: MeloopButtonStyle.outline,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const InstrumentProfilePreview(),
            ),
          ),
        ),
        const SizedBox(height: TempoSpace.md),
        PreviewDataResetButton(onReset: () {}, onComplete: _resetData),
      ],
    );
  }

  String _settingsLanguage() {
    final strings = context.l10n;
    final languageCode =
        ref.watch(appLocaleProvider).value?.languageCode ?? 'vi';
    return languageCode == 'en'
        ? strings.languageEnglish
        : strings.languageVietnamese;
  }
}
