import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../application/session_form_controller.dart';
import '../application/session_form_values.dart';
import '../components/meloop_ui.dart';
import '../practice_sessions/practice_session_edit_fields.dart';
import '../practice_sessions/practice_session_top_bar.dart';

export '../application/session_form_values.dart';

class SessionFormExample extends ConsumerStatefulWidget {
  const SessionFormExample({
    super.key,
    this.onSave,
    this.initialTitle = '',
    this.initialDurationSeconds = 60,
    this.sessionId,
    this.initialValues,
    this.editing = false,
    this.onHome,
  });
  final SessionFormSave? onSave;
  final String initialTitle;
  final int initialDurationSeconds;
  final SessionFormValues? initialValues;
  final bool editing;
  final VoidCallback? onHome;

  /// Journal identity for the review adapter; durable Save is integrated in B06.
  final String? sessionId;
  @override
  ConsumerState<SessionFormExample> createState() => _SessionFormExampleState();
}

class _SessionFormExampleState extends ConsumerState<SessionFormExample> {
  final _saveId = Object();
  final _form = GlobalKey<FormState>();
  late final _initial =
      widget.initialValues ??
      SessionFormValues(
        title: widget.initialTitle,
        date: DateUtils.dateOnly(DateTime.now()),
        durationSeconds: widget.initialDurationSeconds,
        practiced: '',
        difficulty: '',
        next: '',
      );
  late final _title = TextEditingController(text: _initial.title);
  late final _hours = TextEditingController(
    text: '${_initial.durationSeconds ~/ Duration.secondsPerHour}',
  );
  late final _minutes = TextEditingController(
    text:
        '${widget.editing ? _initial.durationSeconds ~/ Duration.secondsPerMinute : _initial.durationSeconds % Duration.secondsPerHour ~/ Duration.secondsPerMinute}',
  );
  late final _seconds = TextEditingController(
    text: '${_initial.durationSeconds % Duration.secondsPerMinute}',
  );
  late final _practiced = TextEditingController(text: _initial.practiced);
  late final _difficulty = TextEditingController(text: _initial.difficulty);
  late final _next = TextEditingController(text: _initial.next);
  late final _bpm = TextEditingController(text: _initial.bpm?.toString() ?? '');
  final _titleFocus = FocusNode();
  late DateTime _date = DateUtils.dateOnly(_initial.date);
  late int? _mood = _initial.mood, _focus = _initial.focus;
  String? _durationError;
  bool _confirmingBack = false;

  bool get _saving =>
      ref.read(sessionFormControllerProvider(_saveId)).isLoading;

  bool get _dirty =>
      _title.text != _initial.title ||
      _practiced.text != _initial.practiced ||
      _difficulty.text != _initial.difficulty ||
      _next.text != _initial.next ||
      _mood != _initial.mood ||
      _focus != _initial.focus ||
      _date != DateUtils.dateOnly(_initial.date) ||
      _bpm.text != (_initial.bpm?.toString() ?? '') ||
      (!widget.editing &&
          _hours.text !=
              '${_initial.durationSeconds ~/ Duration.secondsPerHour}') ||
      _minutes.text !=
          '${widget.editing ? _initial.durationSeconds ~/ Duration.secondsPerMinute : _initial.durationSeconds % Duration.secondsPerHour ~/ Duration.secondsPerMinute}' ||
      _seconds.text !=
          '${_initial.durationSeconds % Duration.secondsPerMinute}';
  @override
  void dispose() {
    for (final controller in [
      _title,
      _hours,
      _minutes,
      _seconds,
      _practiced,
      _difficulty,
      _next,
      _bpm,
    ]) {
      controller.dispose();
    }
    _titleFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final controller = ref.read(
      sessionFormControllerProvider(_saveId).notifier,
    );
    controller.clearError();
    final valid = _form.currentState!.validate();
    final h = int.tryParse(_hours.text.trim()),
        m = int.tryParse(_minutes.text.trim()),
        s = int.tryParse(_seconds.text.trim());
    final total = h == null || m == null || s == null
        ? 0
        : widget.editing
        ? m * Duration.secondsPerMinute + s
        : h * Duration.secondsPerHour + m * Duration.secondsPerMinute + s;
    setState(() {
      _durationError = total < 1 || total > 86400
          ? context.l10n.durationRange
          : null;
    });
    if (!valid || _durationError != null) {
      if (MeloopValidation.titleFor(_title.text, context.l10n) != null) {
        _titleFocus.requestFocus();
      }
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    final saved = await controller.save(
      SessionFormValues(
        title: _title.text.trim(),
        date: _date,
        durationSeconds: total,
        practiced: _practiced.text.trim().isEmpty ? '' : _practiced.text,
        difficulty: _difficulty.text.trim().isEmpty ? '' : _difficulty.text,
        next: _next.text.trim().isEmpty ? '' : _next.text,
        mood: _mood,
        focus: _focus,
        bpm: widget.editing ? int.tryParse(_bpm.text.trim()) : _initial.bpm,
      ),
      onSave: widget.onSave,
    );
    if (saved && mounted) Navigator.of(context).pop();
  }

  Future<void> _back() => _leave(() => Navigator.of(context).pop());
  Future<void> _home() => _leave(widget.onHome!);

  Future<void> _leave(VoidCallback leave) async {
    if (_saving || _confirmingBack) return;
    _confirmingBack = true;
    try {
      if (!_dirty ||
          await showMeloopConfirm(
            context,
            title: context.l10n.discardChangesTitle,
            message: context.l10n.discardChangesMessage,
            confirmLabel: context.l10n.discardChanges,
            cancelLabel: context.l10n.continueEditing,
            destructive: true,
          )) {
        if (mounted) leave();
      }
    } finally {
      _confirmingBack = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final saveState = ref.watch(sessionFormControllerProvider(_saveId));
    final saving = saveState.isLoading;
    final saveError = saveState.hasError ? strings.saveSessionFailed : null;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_back());
      },
      child: MeloopPage(
        hideBottomNavigationWithKeyboard: !widget.editing,
        topBar: widget.editing
            ? PracticeSessionTopBar(
                title: strings.editSessionTitle,
                onBack: saving ? null : _back,
                onHome: saving || widget.onHome == null ? null : _home,
              )
            : MeloopTopBar(
                title: strings.saveSessionTitle,
                onBack: saving ? null : _back,
              ),
        bottomNavigation: widget.editing
            ? SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    TempoSpace.page,
                    TempoSpace.page,
                    TempoSpace.page,
                    TempoSpace.sm,
                  ),
                  child: MeloopButton(
                    label: strings.saveChanges,
                    icon: MeloopIcons.check,
                    onPressed: _save,
                    isLoading: saving,
                  ),
                ),
              )
            : null,
        child: Form(
          key: _form,
          child: widget.editing
              ? PracticeSessionEditFields(
                  title: _title,
                  minutes: _minutes,
                  practiced: _practiced,
                  difficulty: _difficulty,
                  next: _next,
                  bpm: _bpm,
                  date: _date,
                  mood: _mood,
                  focus: _focus,
                  titleFocus: _titleFocus,
                  saving: saving,
                  onDate: (value) => setState(() => _date = value),
                  onMood: (value) => setState(() => _mood = value),
                  onFocus: (value) => setState(() => _focus = value),
                  error: saveError,
                  durationError: _durationError,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: TempoSpace.page,
                  children: [
                    Text(strings.sessionFormHeading, style: TempoType.heading),
                    Text(strings.sessionFormSubtitle),
                    MeloopField(
                      label: strings.sessionTitle,
                      controller: _title,
                      focusNode: _titleFocus,
                      requirement: MeloopFieldRequirement.required,
                      hint: strings.sessionTitleHint,
                      validator: (value) =>
                          MeloopValidation.titleFor(value, strings),
                      enabled: !saving,
                    ),
                    MeloopDateField(
                      label: strings.practiceDate,
                      value: _date,
                      enabled: !saving,
                      onChanged: (date) => setState(() => _date = date),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        MeloopResponsiveRow(
                          children: [
                            _durationField(strings.hours, _hours, 24),
                            _durationField(strings.minutes, _minutes, 59),
                            _durationField(strings.seconds, _seconds, 59),
                          ],
                        ),
                        if (_durationError != null)
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              _durationError!,
                              style: TempoType.caption.copyWith(
                                color: TempoColors.error,
                              ),
                            ),
                          ),
                      ],
                    ),
                    _rating(
                      strings.mood,
                      _mood,
                      (value) => setState(() => _mood = value),
                    ),
                    _rating(
                      strings.focusLevel,
                      _focus,
                      (value) => setState(() => _focus = value),
                    ),
                    const Divider(),
                    MeloopField(
                      label: strings.practicedWhat,
                      controller: _practiced,
                      type: MeloopInputType.multiline,
                      hint: strings.practicedHint,
                      validator: (value) =>
                          MeloopValidation.noteFor(value, strings),
                      enabled: !saving,
                    ),
                    MeloopField(
                      label: strings.difficulty,
                      controller: _difficulty,
                      type: MeloopInputType.multiline,
                      hint: strings.difficultyHint,
                      validator: (value) =>
                          MeloopValidation.noteFor(value, strings),
                      enabled: !saving,
                    ),
                    MeloopField(
                      label: strings.nextPractice,
                      controller: _next,
                      type: MeloopInputType.multiline,
                      validator: (value) =>
                          MeloopValidation.noteFor(value, strings),
                      enabled: !saving,
                    ),
                    if (saveError != null)
                      MeloopNotice(
                        message: saveError,
                        kind: MeloopNoticeKind.error,
                      ),
                    MeloopButton(
                      label: strings.savePractice,
                      icon: MeloopIcons.check,
                      onPressed: _save,
                      isLoading: saving,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _durationField(
    String label,
    TextEditingController controller,
    int max,
  ) => MeloopField(
    label: label,
    controller: controller,
    type: MeloopInputType.integer,
    requirement: MeloopFieldRequirement.required,
    enabled: !_saving,
    validator: (value) => MeloopValidation.integer(
      value,
      label: label,
      min: 0,
      max: max,
      strings: context.l10n,
    ),
  );
  Widget _rating(String label, int? value, ValueChanged<int?> onChanged) =>
      MeloopRating(
        label: label,
        initialValue: value,
        mood: label == context.l10n.mood,
        enabled: !_saving,
        onChanged: onChanged,
      );
}
