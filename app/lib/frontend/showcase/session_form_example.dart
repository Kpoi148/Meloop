import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../application/session_form_controller.dart';
import '../application/session_form_values.dart';
import '../components/meloop_ui.dart';
import '../practice_sessions/practice_session_form_fields.dart';
import '../practice_sessions/practice_session_form_tokens.dart';
import '../practice_sessions/practice_session_top_bar.dart';

export '../application/session_form_values.dart';

class SessionFormExample extends ConsumerStatefulWidget {
  const SessionFormExample({
    super.key,
    this.onSave,
    this.initialTitle = '',
    this.initialDurationSeconds = Duration.secondsPerMinute,
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
  late final int _initialMinutes = widget.editing
      ? _initial.durationSeconds ~/ Duration.secondsPerMinute
      : (_initial.durationSeconds / Duration.secondsPerMinute)
            .round()
            .clamp(
              PracticeSessionFormLimits.minimumNewMinutes,
              PracticeSessionFormLimits.maximumMinutes,
            )
            .toInt();
  late final _title = TextEditingController(text: _initial.title);
  late final _minutes = TextEditingController(text: '$_initialMinutes');
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
      _minutes.text != '$_initialMinutes';

  @override
  void dispose() {
    for (final controller in [
      _title,
      _minutes,
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
    final minutes = int.tryParse(_minutes.text.trim());
    // Keep the saved seconds when its displayed duration is unchanged.
    final remainingSeconds = widget.editing && minutes == _initialMinutes
        ? _initial.durationSeconds % Duration.secondsPerMinute
        : 0;
    final total = minutes == null
        ? 0
        : minutes * Duration.secondsPerMinute + remainingSeconds;
    setState(() {
      _durationError =
          valid &&
              (total < PracticeSessionFormLimits.minimumSeconds ||
                  total > PracticeSessionFormLimits.maximumSeconds)
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
        bpm: int.tryParse(_bpm.text.trim()),
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
        hideBottomNavigationWithKeyboard: false,
        topBar: PracticeSessionTopBar(
          title: widget.editing
              ? strings.editSessionTitle
              : strings.saveSessionTitle,
          onBack: saving ? null : _back,
          onHome: saving || widget.onHome == null ? null : _home,
        ),
        bottomNavigation: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              TempoSpace.page,
              TempoSpace.page,
              TempoSpace.page,
              TempoSpace.sm,
            ),
            child: MeloopButton(
              label: widget.editing
                  ? strings.saveChanges
                  : strings.savePractice,
              icon: MeloopIcons.check,
              onPressed: _save,
              isLoading: saving,
            ),
          ),
        ),
        child: Form(
          key: _form,
          child: PracticeSessionFormFields(
            heading: widget.editing
                ? strings.editSessionHeading
                : strings.sessionFormHeading,
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
            minimumMinutes: widget.editing
                ? PracticeSessionFormLimits.minimumEditMinutes
                : PracticeSessionFormLimits.minimumNewMinutes,
            saving: saving,
            onDate: (value) => setState(() => _date = value),
            onMood: (value) => setState(() => _mood = value),
            onFocus: (value) => setState(() => _focus = value),
            error: saveError,
            durationError: _durationError,
          ),
        ),
      ),
    );
  }
}
