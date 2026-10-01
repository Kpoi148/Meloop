import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../application/startup_controller.dart';
import '../components/meloop_ui.dart';
import 'preview_copy.dart';
import 'session_form_example.dart';

class SetupExample extends StatefulWidget {
  const SetupExample({super.key, this.onSave, this.onStart, this.profile});
  final Future<void> Function(SessionFormValues)? onSave;
  final ValueChanged<String>? onStart;
  final PreviewInstrumentProfile? profile;
  @override
  State<SetupExample> createState() => _SetupExampleState();
}

class _SetupExampleState extends State<SetupExample> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final profile = widget.profile;
    return MeloopPage(
      topBarGap: 7,
      topBar: MeloopTopBar(
        title: strings.setupTitle,
        onBack: () => Navigator.of(context).pop(),
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
              requirement: MeloopFieldRequirement.required,
              hint: strings.sessionTitleHint,
              helper: strings.sessionTitleHelper,
              validator: (value) => MeloopValidation.titleFor(value, strings),
            ),
          ),
          const SizedBox(height: 17),
          MeloopNotice(message: strings.timerStartsHint),
          const SizedBox(height: TempoSpace.lg),
          MeloopButton(
            label: strings.startPractice,
            icon: MeloopIcons.play,
            onPressed: () {
              if (!_form.currentState!.validate()) return;
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
    );
  }
}
