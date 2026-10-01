import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../application/startup_controller.dart';
import '../components/meloop_ui.dart';
import '../theme/tokens/practice_tokens.dart';
import 'preview_copy.dart';

class SetupExample extends StatefulWidget {
  const SetupExample({super.key, this.onStart, this.profile});
  final Future<void> Function(String)? onStart;
  final PreviewInstrumentProfile? profile;
  @override
  State<SetupExample> createState() => _SetupExampleState();
}

class _SetupExampleState extends State<SetupExample> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  bool _starting = false;
  String? _error;

  Future<void> _back() async {
    if (_starting) return;
    if (_title.text.isNotEmpty &&
        !await showMeloopConfirm(
          context,
          title: context.l10n.discardChangesTitle,
          message: context.l10n.discardChangesMessage,
          confirmLabel: context.l10n.discardChanges,
          cancelLabel: context.l10n.continueEditing,
          destructive: true,
        )) {
      return;
    }
    if (mounted) Navigator.of(context).pop();
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
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_back());
      },
      child: MeloopPage(
        topBarGap: PracticeTempo.setupBarGap,
        topBar: MeloopTopBar(
          title: strings.setupTitle,
          onBack: _starting ? null : _back,
        ),
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
                final height =
                    constraints.maxWidth >= PracticeTempo.wideContentWidth
                    ? PracticeTempo.wideSetupStageHeight
                    : PracticeTempo.setupStageHeight;
                final art =
                    profile != null &&
                        profile.instrument != MeloopInstrument.guitar
                    ? SizedBox(
                        height: height,
                        child: Align(
                          alignment: Alignment.bottomRight,
                          child: MeloopArt.instrument(
                            profile.instrument,
                            size: constraints.maxWidth,
                          ),
                        ),
                      )
                    : MeloopIllustration(
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
                  height: height - PracticeTempo.setupProfileOverlap,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(top: 0, left: 0, right: 0, child: art),
                      Positioned(
                        top: PracticeTempo.setupHeadingTop,
                        left: 0,
                        right: 0,
                        child: heading,
                      ),
                    ],
                  ),
                );
              },
            ),
            MeloopCard(
              color: TempoColors.soft,
              padding: PracticeTempo.setupProfilePadding,
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
                    profile == null
                        ? instrumentLabel(strings, MeloopInstrument.guitar)
                        : profileInstrumentLabel(strings, profile),
                  ),
                ],
              ),
            ),
            const SizedBox(height: TempoSpace.lg),
            Form(
              key: _form,
              child: MeloopField(
                label: strings.sessionTitle,
                controller: _title,
                requirement: MeloopFieldRequirement.required,
                hint: strings.sessionTitleHint,
                helper: strings.sessionTitleHelper,
                enabled: !_starting,
                validator: (value) => MeloopValidation.titleFor(value, strings),
              ),
            ),
            const SizedBox(height: TempoSpace.lg),
            MeloopNotice(message: strings.timerStartsHint),
            const SizedBox(height: TempoSpace.lg),
            if (_error != null)
              MeloopNotice(message: _error!, kind: MeloopNoticeKind.error),
            MeloopButton(
              label: strings.startPractice,
              icon: MeloopIcons.play,
              isLoading: _starting,
              onPressed: () async {
                if (!_form.currentState!.validate()) return;
                if (widget.onStart != null) {
                  setState(() {
                    _starting = true;
                    _error = null;
                  });
                  try {
                    await widget.onStart!(_title.text.trim());
                    if (context.mounted) Navigator.of(context).pop();
                  } catch (_) {
                    if (mounted) {
                      setState(() => _error = context.l10n.startPracticeFailed);
                    }
                  } finally {
                    if (mounted) setState(() => _starting = false);
                  }
                  return;
                }
                setState(() => _error = strings.startPracticeFailed);
              },
            ),
          ],
        ),
      ),
    );
  }
}
