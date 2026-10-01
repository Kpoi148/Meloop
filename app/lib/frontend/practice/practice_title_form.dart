import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../shared/practice/practice_session_service.dart';
import '../components/meloop_ui.dart';

class PracticeTitleForm extends StatefulWidget {
  const PracticeTitleForm({super.key, required this.service});
  final PracticeSessionService service;

  @override
  State<PracticeTitleForm> createState() => _PracticeTitleFormState();
}

class _PracticeTitleFormState extends State<PracticeTitleForm> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(
    text: widget.service.current.draft!.title,
  );
  bool _saving = false;
  bool _failed = false;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      await widget.service.rename(_title.text.trim());
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _form,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: TempoSpace.lg,
      children: [
        MeloopField(
          label: context.l10n.sessionTitle,
          controller: _title,
          enabled: !_saving,
          requirement: MeloopFieldRequirement.required,
          validator: (value) => MeloopValidation.titleFor(value, context.l10n),
        ),
        if (_failed)
          MeloopNotice(
            message: context.l10n.practiceActionFailed,
            kind: MeloopNoticeKind.error,
          ),
        MeloopButton(
          label: context.l10n.save,
          onPressed: _save,
          isLoading: _saving,
        ),
      ],
    ),
  );
}
