import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../shared/journal/journal_runtime.dart';
import '../application/startup_controller.dart';
import '../components/meloop_ui.dart';
import 'preview_copy.dart';
import 'session_form_example.dart';

class SetupExample extends StatefulWidget {
  const SetupExample({
    super.key,
    this.onSave,
    this.onStart,
    this.profile,
    this.onJournalStart,
    this.identifiers = const UuidJournalIdentifiers(),
  });
  final Future<void> Function(SessionFormValues)? onSave;
  final ValueChanged<String>? onStart;
  final PreviewInstrumentProfile? profile;
  final Future<void> Function(String requestId, String title)? onJournalStart;
  final JournalIdentifiers identifiers;
  @override
  State<SetupExample> createState() => _SetupExampleState();
}

class _SetupExampleState extends State<SetupExample> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  String? _requestId;
  bool _starting = false;
  bool _startFailed = false;
  bool _confirmingBack = false;

  Future<void> _back() async {
    if (_starting || _confirmingBack) return;
    _confirmingBack = true;
    try {
      final discard =
          _title.text.isEmpty ||
          await showMeloopConfirm(
            context,
            title: context.l10n.discardChangesTitle,
            message: context.l10n.discardChangesMessage,
            confirmLabel: context.l10n.discardChanges,
            cancelLabel: context.l10n.continueEditing,
          );
      if (mounted && discard) Navigator.of(context).pop();
    } finally {
      _confirmingBack = false;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final profile = widget.profile;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _back();
      },
      child: MeloopPage(
        topBarGap: 7,
        topBar: MeloopTopBar(title: strings.setupTitle, onBack: _back),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final large = MediaQuery.textScalerOf(context).scale(16) > 20;
                final heading = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(strings.newPracticeUpper, style: TempoType.caption),
                    const SizedBox(height: TempoSpace.sm),
                    Text(strings.setupQuestion, style: TempoType.setup),
                  ],
                );
                final height = constraints.maxWidth >= 400 ? 430.0 : 370.0;
                final art = MeloopIllustration(
                  asset: 'fidelity-setup.png',
                  height: height,
                );
                if (large) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [heading, art],
                  );
                }
                // Artwork extends under the following profile card, as in Tempo.
                return SizedBox(
                  height: height - 32,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(top: 0, left: 0, right: 0, child: art),
                      Positioned(top: 21, left: 0, right: 0, child: heading),
                    ],
                  ),
                );
              },
            ),
            MeloopCard(
              color: TempoColors.soft,
              padding: EdgeInsets.symmetric(horizontal: 17, vertical: 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile == null
                        ? strings.defaultProfileName
                        : profileDisplayName(strings, profile),
                    style: TempoType.section,
                  ),
                  Text(
                    instrumentLabel(
                      strings,
                      profile?.instrument ?? MeloopInstrument.guitar,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 17),
            Form(
              key: _form,
              child: MeloopField(
                label: strings.sessionTitle,
                controller: _title,
                enabled: !_starting,
                requirement: MeloopFieldRequirement.required,
                hint: strings.sessionTitleHint,
                helper: strings.sessionTitleHelper,
                validator: (value) => MeloopValidation.titleFor(value, strings),
              ),
            ),
            const SizedBox(height: 17),
            MeloopNotice(message: strings.timerStartsHint),
            if (_startFailed) ...[
              const SizedBox(height: TempoSpace.md),
              MeloopNotice(
                message: strings.practiceStartFailed,
                kind: MeloopNoticeKind.error,
              ),
            ],
            const SizedBox(height: TempoSpace.lg),
            MeloopButton(
              label: strings.startPractice,
              icon: MeloopIcons.play,
              loadingLabel: strings.processing,
              onPressed: () async {
                if (!_form.currentState!.validate()) return;
                if (widget.onJournalStart != null) {
                  if (_starting) return;
                  setState(() {
                    _starting = true;
                    _startFailed = false;
                  });
                  try {
                    _requestId ??= widget.identifiers.newId();
                    await widget.onJournalStart!(_requestId!, _title.text);
                    if (context.mounted) Navigator.of(context).pop();
                  } catch (_) {
                    if (mounted) setState(() => _startFailed = true);
                  } finally {
                    if (mounted) setState(() => _starting = false);
                  }
                  return;
                }
                if (widget.onStart != null) {
                  widget.onStart!(_title.text.trim());
                  Navigator.of(context).pop();
                  return;
                }
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => SessionFormExample(
                      initialTitle: _title.text.trim(),
                      onSave: widget.onSave,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
