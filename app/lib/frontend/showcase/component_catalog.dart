import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../components/meloop_ui.dart';

class ComponentCatalog extends StatefulWidget {
  const ComponentCatalog({super.key});
  @override
  State<ComponentCatalog> createState() => _ComponentCatalogState();
}

class _ComponentCatalogState extends State<ComponentCatalog> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _bpm = TextEditingController(text: '80');
  bool _reminder = false, _diagnostics = false;
  int _tab = 7;
  int? _rating;
  @override
  void dispose() {
    _name.dispose();
    _bpm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    return MeloopPage(
      topBar: MeloopTopBar(
        title: strings.catalogTitle,
        onBack: () => Navigator.of(context).pop(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: TempoSpace.page,
        children: [
          Text(strings.catalogHeading, style: TempoType.heading),
          Text(strings.catalogSubtitle, style: TempoType.caption),
          Text(strings.catalogButtons, style: TempoType.section),
          for (final style in MeloopButtonStyle.values)
            MeloopButton(
              label: switch (style) {
                MeloopButtonStyle.primary => strings.savePractice,
                MeloopButtonStyle.yellow => strings.createPractice,
                MeloopButtonStyle.outline => strings.addInstrument,
                MeloopButtonStyle.soft => strings.practiceTools,
                MeloopButtonStyle.orange => strings.endPractice,
                MeloopButtonStyle.danger => strings.deleteSession,
              },
              style: style,
              icon: MeloopIcons.check,
              onPressed: () async {
                await Future<void>.delayed(const Duration(milliseconds: 800));
              },
            ),
          MeloopButton(label: strings.unavailable, onPressed: null),
          MeloopButton(label: strings.save, onPressed: null, isLoading: true),
          Text(strings.catalogFields, style: TempoType.section),
          Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: TempoSpace.lg,
              children: [
                MeloopField(
                  label: strings.profileName,
                  controller: _name,
                  requirement: MeloopFieldRequirement.required,
                  validator: (value) =>
                      MeloopValidation.profileNameFor(value, strings),
                  helper: strings.profileHelper,
                ),
                MeloopField(
                  label: strings.tempoBpm,
                  controller: _bpm,
                  type: MeloopInputType.integer,
                  requirement: MeloopFieldRequirement.required,
                  validator: (value) => MeloopValidation.integer(
                    value,
                    label: strings.bpm,
                    min: 40,
                    max: 240,
                    strings: strings,
                  ),
                ),
                MeloopButton(
                  label: strings.validateData,
                  onPressed: () {
                    _form.currentState!.validate();
                  },
                ),
              ],
            ),
          ),
          Text(strings.catalogChoices, style: TempoType.section),
          MeloopChoiceGroup<int>(
            label: strings.timeRange,
            initialValue: _tab,
            requirement: MeloopFieldRequirement.required,
            requiredMessage: strings.requiredChoice(
              strings.timeRange.toLowerCase(),
            ),
            choices: [
              MeloopChoice(value: 7, label: strings.sevenDays),
              MeloopChoice(value: 30, label: strings.thirtyDays),
              MeloopChoice(value: 0, label: strings.all),
            ],
            onChanged: (value) => setState(() => _tab = value!),
          ),
          MeloopSelect<int>(
            label: strings.beatsPerBar,
            initialValue: 4,
            requirement: MeloopFieldRequirement.required,
            choices: [
              for (var i = 1; i <= 12; i++)
                MeloopChoice(value: i, label: strings.beats(i)),
            ],
            onChanged: (_) {},
          ),
          MeloopChoiceGroup<int>(
            label: strings.mood,
            initialValue: _rating,
            clearable: true,
            choices: [
              for (var i = 1; i <= 5; i++)
                MeloopChoice(value: i, label: '$i / 5'),
            ],
            onChanged: (value) => setState(() => _rating = value),
          ),
          MeloopToggle(
            label: strings.reminder,
            description: strings.reminderDescription,
            value: _reminder,
            onChanged: (value) => setState(() => _reminder = value),
          ),
          MeloopToggle(
            label: strings.attachDiagnostics,
            description: strings.attachDiagnosticsDescription,
            checkbox: true,
            value: _diagnostics,
            onChanged: (value) => setState(() => _diagnostics = value),
          ),
          Text(strings.catalogDialogs, style: TempoType.section),
          MeloopButton(
            label: strings.openConfirmDialog,
            style: MeloopButtonStyle.outline,
            onPressed: () async {
              await showMeloopConfirm(
                context,
                title: '${strings.deleteSession}?',
                message: strings.deleteSessionMessage,
                destructive: true,
                confirmLabel: strings.deleteSession,
              );
            },
          ),
          MeloopButton(
            label: strings.openChoiceSheet,
            style: MeloopButtonStyle.soft,
            onPressed: () async {
              await showMeloopSheet<void>(
                context,
                title: strings.tempoComponents,
                child: MeloopNotice(message: strings.sharedThemeNotice),
              );
            },
          ),
          MeloopButton(
            label: strings.showNotification,
            style: MeloopButtonStyle.outline,
            onPressed: () => MeloopNotifications.show(
              context,
              strings.sampleActionComplete,
              kind: MeloopNoticeKind.success,
            ),
          ),
          MeloopNotice(message: strings.journalOnDevice),
          MeloopNotice(
            message: strings.sessionSaved,
            kind: MeloopNoticeKind.success,
          ),
          MeloopNotice(
            message: strings.saveFailedKeepsContent,
            kind: MeloopNoticeKind.error,
          ),
          Text(strings.catalogStates, style: TempoType.section),
          MeloopStateView(
            state: MeloopViewState.loading,
            title: strings.loadingSessions,
          ),
          MeloopStateView(
            state: MeloopViewState.empty,
            title: strings.journeyStartsToday,
            message: strings.saveFirstSession,
            actionLabel: strings.createPractice,
            onAction: () {},
          ),
          MeloopStateView(
            state: MeloopViewState.error,
            title: strings.loadSessionsFailed,
            message: strings.dataKeptRetry,
            actionLabel: strings.retry,
            onAction: () {},
          ),
        ],
      ),
    );
  }
}
