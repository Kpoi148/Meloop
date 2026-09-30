import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../components/meloop_ui.dart';
import 'preview_copy.dart';

class ProfileFormExample extends StatefulWidget {
  const ProfileFormExample({
    super.key,
    required this.onSave,
    required this.onBack,
  });

  final void Function(String name, MeloopInstrument instrument) onSave;
  final VoidCallback onBack;

  @override
  State<ProfileFormExample> createState() => _ProfileFormExampleState();
}

class _ProfileFormExampleState extends State<ProfileFormExample> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _customInstrument = TextEditingController();
  var _instrument = MeloopInstrument.guitar;
  var _seededName = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_seededName) {
      _seededName = true;
      _name.text = context.l10n.defaultProfileName;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _customInstrument.dispose();
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    widget.onSave(_name.text.trim(), _instrument);
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    const instruments = [
      MeloopInstrument.guitar,
      MeloopInstrument.piano,
      MeloopInstrument.ukulele,
      MeloopInstrument.violin,
      MeloopInstrument.flute,
      MeloopInstrument.drums,
    ];
    return MeloopPage(
      topBar: MeloopTopBar(
        title: strings.profileFormTitle,
        onBack: widget.onBack,
      ),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: TempoSpace.page,
          children: [
            Text(strings.profileQuestion, style: TempoType.heading),
            Text(strings.profileSubtitle),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = (constraints.maxWidth - TempoSpace.sm) / 2;
                return Wrap(
                  spacing: TempoSpace.sm,
                  runSpacing: TempoSpace.sm,
                  children: [
                    for (final instrument in instruments)
                      SizedBox(
                        width: width,
                        child: _InstrumentChoice(
                          instrument: instrument,
                          label: instrumentLabel(strings, instrument),
                          selected: _instrument == instrument,
                          onTap: () => setState(() => _instrument = instrument),
                        ),
                      ),
                  ],
                );
              },
            ),
            _InstrumentChoice(
              instrument: MeloopInstrument.other,
              label: strings.instrumentOther,
              description: strings.instrumentOtherDescription,
              selected: _instrument == MeloopInstrument.other,
              horizontal: true,
              onTap: () => setState(() => _instrument = MeloopInstrument.other),
            ),
            if (_instrument == MeloopInstrument.other)
              MeloopField(
                label: strings.customInstrumentName,
                controller: _customInstrument,
                requirement: MeloopFieldRequirement.required,
                hint: strings.customInstrumentHint,
                validator: (value) =>
                    MeloopValidation.customInstrumentFor(value, strings),
              ),
            MeloopField(
              label: strings.profileName,
              controller: _name,
              requirement: MeloopFieldRequirement.required,
              hint: strings.profileNameHint,
              validator: (value) =>
                  MeloopValidation.profileNameFor(value, strings),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _save(),
            ),
            MeloopButton(
              label: strings.saveProfile,
              icon: MeloopIcons.check,
              onPressed: _save,
            ),
            Text(
              strings.profileFootnote,
              textAlign: TextAlign.center,
              style: TempoType.caption,
            ),
          ],
        ),
      ),
    );
  }
}

class _InstrumentChoice extends StatelessWidget {
  const _InstrumentChoice({
    required this.instrument,
    required this.label,
    required this.selected,
    required this.onTap,
    this.description,
    this.horizontal = false,
  });

  final MeloopInstrument instrument;
  final String label;
  final String? description;
  final bool selected;
  final bool horizontal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final content = horizontal
        ? Row(
            children: [
              MeloopArt.instrument(instrument, size: 72),
              const SizedBox(width: TempoSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TempoType.label),
                    if (description != null)
                      Text(description!, style: TempoType.caption),
                  ],
                ),
              ),
              if (selected) const MeloopIcon(MeloopIcons.check),
            ],
          )
        : Column(
            children: [
              MeloopArt.instrument(instrument, size: 82),
              Text(label, style: TempoType.label),
              if (selected) const MeloopIcon(MeloopIcons.check, size: 18),
            ],
          );
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? TempoColors.selection : TempoColors.fieldFill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TempoRadius.card),
          side: BorderSide(
            color: selected ? TempoColors.teal : TempoColors.line,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(TempoRadius.card),
          child: Padding(
            padding: const EdgeInsets.all(TempoSpace.md),
            child: content,
          ),
        ),
      ),
    );
  }
}
