import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../application/app_settings_controller.dart';
import '../application/instrument_profile_service.dart';
import '../application/startup_controller.dart';
import '../components/meloop_ui.dart';
import 'component_catalog.dart';
import 'home_example.dart';
import 'instrument_profile_preview.dart';
import 'instrument_profiles_example.dart';
import 'instrument_picker_example.dart';
import 'language_selector.dart';
import 'profile_form_example.dart';
import 'preview_data_reset_button.dart';
import 'preview_copy.dart';
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
  });

  final bool developmentTools;
  final InstrumentProfile? profile;
  final VoidCallback? onChooseProfile, onManageProfiles;
  final FutureOr<void> Function()? onResetData;

  @override
  ConsumerState<MeloopUiShowcase> createState() => _MeloopUiShowcaseState();
}

class _MeloopUiShowcaseState extends ConsumerState<MeloopUiShowcase> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _catalog() => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => const ComponentCatalog()));

  void _resetData() {
    ref.invalidate(showcaseControllerProvider);
    Navigator.of(context).pushAndRemoveUntil<void>(
      MaterialPageRoute(builder: (_) => const InstrumentProfilePreview()),
      (_) => false,
    );
  }

  void _openProfilePage(VoidCallback open) {
    if (widget.profile != null &&
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

  void _setup(PreviewInstrumentProfile profile) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => SetupExample(
        profile: profile,
        onStart: ref.read(meloopShellControllerProvider.notifier).startDraft,
      ),
    ),
  );

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
    if (_search.text != showcase.query) {
      _search.value = TextEditingValue(
        text: showcase.query,
        selection: TextSelection.collapsed(offset: showcase.query.length),
      );
    }

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
      StartupDestination.recoveredTimer => const TimerExample(),
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
    return MeloopPage(
      bottomNavigation: MeloopBottomNavigation(
        selectedIndex: shell.selectedTab,
        onSelected: shellController.selectTab,
      ),
      child: switch (shell.selectedTab) {
        0 => HomeExample(
          showSampleData: widget.profile == null,
          profile: profile,
          draft: shell.draft,
          onCreate: () => shell.draft == null
              ? _setup(profile)
              : shellController.showTimer(),
          onHistory: () => shellController.selectTab(1),
          onCatalog: widget.developmentTools ? _catalog : null,
          onInstrument: () => _openProfilePage(
            widget.onChooseProfile ?? shellController.showProfilePicker,
          ),
        ),
        1 => _history(shell, showcase, showcaseController),
        2 => _progress(),
        _ => _settings(profile, showcase, showcaseController),
      },
    );
  }

  Widget _history(
    MeloopShellState shell,
    ShowcaseState state,
    ShowcaseController controller,
  ) {
    final strings = context.l10n;
    if (widget.profile case final profile?) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: TempoSpace.page,
        children: [
          const MeloopTopBar(),
          Text(strings.navHistory, style: TempoType.heading),
          Text(
            '${profile.name} · ${profileInstrumentLabel(strings, shell.selectedProfile!)}',
          ),
          if (shell.draft != null)
            MeloopButton(
              label: strings.continuePractice,
              onPressed: ref
                  .read(meloopShellControllerProvider.notifier)
                  .showTimer,
            ),
          MeloopStateView(
            state: MeloopViewState.empty,
            title: strings.noPracticeSessions,
            message: strings.profileSessionsEmptyMessage,
          ),
          MeloopButton(
            label: strings.createPractice,
            onPressed: () => shell.draft == null
                ? _setup(shell.selectedProfile!)
                : ref.read(meloopShellControllerProvider.notifier).showTimer(),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: TempoSpace.page,
      children: [
        const MeloopTopBar(),
        Text(strings.navHistory, style: TempoType.heading),
        Text(strings.historySubtitle),
        if (shell.draft != null)
          MeloopCard(
            color: TempoColors.soft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(strings.unfinishedPractice, style: TempoType.title),
                const SizedBox(height: TempoSpace.sm),
                MeloopButton(
                  label: strings.continuePractice,
                  icon: MeloopIcons.play,
                  onPressed: ref
                      .read(meloopShellControllerProvider.notifier)
                      .showTimer,
                ),
              ],
            ),
          ),
        MeloopSearch(controller: _search, onChanged: controller.search),
        MeloopChoiceGroup<int>(
          label: strings.timeRange,
          initialValue: 0,
          requirement: MeloopFieldRequirement.required,
          requiredMessage: strings.requiredChoice(
            strings.timeRange.toLowerCase(),
          ),
          choices: [
            MeloopChoice(value: 0, label: strings.all),
            MeloopChoice(value: 7, label: strings.sevenDays),
            MeloopChoice(value: 30, label: strings.thirtyDays),
          ],
          onChanged: (_) {},
        ),
        if (state.query.isNotEmpty &&
            !strings.sampleSessionTitle.toLowerCase().contains(
              state.query.toLowerCase(),
            ))
          MeloopStateView(
            state: MeloopViewState.empty,
            title: strings.noMatchingSessions,
            actionLabel: strings.clearSearchAction,
            onAction: () {
              _search.clear();
              controller.search('');
            },
          )
        else
          MeloopCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(strings.sampleSessionTitle, style: TempoType.title),
                Text(strings.sampleSessionDate),
              ],
            ),
          ),
        MeloopButton(
          label: shell.draft == null
              ? strings.createPractice
              : strings.continuePractice,
          icon: shell.draft == null ? MeloopIcons.plus : MeloopIcons.play,
          onPressed: () => shell.draft == null
              ? _setup(shell.selectedProfile!)
              : ref.read(meloopShellControllerProvider.notifier).showTimer(),
        ),
        Text(
          strings.showcaseSaveCount(state.saveCount),
          style: TempoType.caption,
        ),
      ],
    );
  }

  Widget _progress() {
    final strings = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: TempoSpace.page,
      children: [
        MeloopTopBar(title: strings.navProgress),
        Text(strings.progressHeading, style: TempoType.heading),
        MeloopStateView(
          state: MeloopViewState.empty,
          title: strings.noProgressTitle,
          message: strings.noProgressMessage,
        ),
      ],
    );
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
    );
    if (widget.profile != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          settings,
          const SizedBox(height: TempoSpace.page),
          PreviewDataResetButton(onReset: widget.onResetData ?? () {}),
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
