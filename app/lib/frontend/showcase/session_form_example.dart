import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../shared/journal/journal_models.dart';
import '../../shared/journal/practice_date.dart';
import '../application/session_form_draft_controller.dart';
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
    this.onSaved,
    this.initialReviewInput,
    this.onPersistInput,
    this.instrumentName,
  });
  final SessionFormSave? onSave;
  final String initialTitle;
  final int initialDurationSeconds;
  final SessionFormValues? initialValues;
  final bool editing;
  final VoidCallback? onHome;
  final VoidCallback? onSaved;
  final ReviewInput? initialReviewInput;
  final SessionFormPersistInput? onPersistInput;
  final String? instrumentName;

  /// Stable identity of the journal draft being reviewed.
  final String? sessionId;
  @override
  ConsumerState<SessionFormExample> createState() => _SessionFormExampleState();
}

class _SessionFormExampleState extends ConsumerState<SessionFormExample>
    with WidgetsBindingObserver {
  final _saveId = Object();
  final _form = GlobalKey<FormState>();
  late final _seed =
      widget.initialValues ??
      SessionFormValues(
        title: widget.initialTitle,
        date: DateUtils.dateOnly(DateTime.now()),
        durationSeconds: widget.initialDurationSeconds,
        practiced: '',
        difficulty: '',
        next: '',
      );
  late final _initial = SessionFormValues(
    title: widget.initialReviewInput?.title ?? _seed.title,
    date: widget.initialReviewInput != null
        ? DateTime.parse(widget.initialReviewInput!.practiceDate)
        : _seed.date,
    durationSeconds: _seed.durationSeconds,
    practiced: widget.initialReviewInput?.practiced ?? _seed.practiced,
    difficulty: widget.initialReviewInput?.difficulty ?? _seed.difficulty,
    next: widget.initialReviewInput?.next ?? _seed.next,
    mood: widget.initialReviewInput != null
        ? widget.initialReviewInput!.mood
        : _seed.mood,
    focus: widget.initialReviewInput != null
        ? widget.initialReviewInput!.focus
        : _seed.focus,
    bpm: _seed.bpm,
  );
  late final String _initialHours =
      widget.initialReviewInput?.durationHoursInput ??
      '${_initial.durationSeconds ~/ Duration.secondsPerHour}';
  late final String _initialMinutes =
      widget.initialReviewInput?.durationMinutesInput ??
      '${_initial.durationSeconds ~/ Duration.secondsPerMinute % Duration.minutesPerHour}';
  late final String _initialSeconds =
      widget.initialReviewInput?.durationSecondsInput ??
      '${_initial.durationSeconds % Duration.secondsPerMinute}';
  late final _title = TextEditingController(text: _initial.title);
  late final _hours = TextEditingController(text: _initialHours);
  late final _minutes = TextEditingController(text: _initialMinutes);
  late final _seconds = TextEditingController(text: _initialSeconds);
  late final _practiced = TextEditingController(text: _initial.practiced);
  late final _difficulty = TextEditingController(text: _initial.difficulty);
  late final _next = TextEditingController(text: _initial.next);
  late final _bpm = TextEditingController(
    text: widget.initialReviewInput?.bpmInput ?? _initial.bpm?.toString() ?? '',
  );
  final _titleFocus = FocusNode();
  late DateTime _date = DateUtils.dateOnly(_initial.date);
  late int? _mood = _initial.mood, _focus = _initial.focus;
  String? _durationError;
  bool _confirmingBack = false;
  bool _submitting = false, _leaving = false;
  SessionFormDraftController? _draftController;

  List<TextEditingController> get _inputs => [
    _title,
    _hours,
    _minutes,
    _seconds,
    _practiced,
    _difficulty,
    _next,
    _bpm,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.onPersistInput case final persist?) {
      WidgetsBinding.instance.addObserver(this);
      _draftController = SessionFormDraftController(persist)
        ..addListener(_draftChanged);
      for (final input in _inputs) {
        input.addListener(_inputChanged);
      }
    }
  }

  void _draftChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && !_saving) {
      unawaited(_flushBackgroundDraft());
    }
  }

  Future<void> _flushBackgroundDraft() async {
    try {
      await _draftController?.flush();
    } catch (_) {
      // The draft controller keeps the snapshot and exposes the existing retry UI.
    }
  }

  void _inputChanged() => _draftController?.update(
    ReviewInput(
      title: _title.text,
      practiceDate: PracticeDate.fromLocal(_date).value,
      durationHoursInput: _hours.text,
      durationMinutesInput: _minutes.text,
      durationSecondsInput: _seconds.text,
      practiced: _practiced.text,
      difficulty: _difficulty.text,
      next: _next.text,
      mood: _mood,
      focus: _focus,
      bpmInput: _bpm.text,
    ),
  );

  bool get _saving =>
      _submitting ||
      _leaving ||
      ref.read(sessionFormControllerProvider(_saveId)).isLoading;

  bool get _dirty =>
      _title.text != _initial.title ||
      _practiced.text != _initial.practiced ||
      _difficulty.text != _initial.difficulty ||
      _next.text != _initial.next ||
      _mood != _initial.mood ||
      _focus != _initial.focus ||
      _date != DateUtils.dateOnly(_initial.date) ||
      _bpm.text !=
          (widget.initialReviewInput?.bpmInput ??
              _initial.bpm?.toString() ??
              '') ||
      _hours.text != _initialHours ||
      _seconds.text != _initialSeconds ||
      _minutes.text != _initialMinutes;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _draftController?.dispose();
    for (final controller in _inputs) {
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
    final hours = int.tryParse(_hours.text.trim());
    final seconds = int.tryParse(_seconds.text.trim());
    final total =
        (hours ?? 0) * Duration.secondsPerHour +
        (minutes ?? 0) * Duration.secondsPerMinute +
        (seconds ?? 0);
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
    setState(() => _submitting = true);
    try {
      if (_draftController != null) {
        try {
          await _draftController!.flush();
        } catch (_) {
          // The controller exposes the failure and keeps the retry snapshot.
          return;
        }
      }
      if (!mounted) return;
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
      if (saved && mounted) {
        if (widget.onSaved != null) {
          widget.onSaved!();
        } else {
          Navigator.of(context).pop();
        }
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _retryDraft() async {
    if (_saving) return;
    setState(() => _submitting = true);
    try {
      await _draftController?.flush();
    } catch (_) {
      /* Retain inputs and the recoverable retry snapshot. */
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
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
            title: _draftController == null
                ? context.l10n.discardChangesTitle
                : context.l10n.leaveReviewTitle,
            message: _draftController == null
                ? context.l10n.discardChangesMessage
                : context.l10n.leaveReviewMessage,
            confirmLabel: _draftController == null
                ? context.l10n.discardChanges
                : context.l10n.returnToPractice,
            cancelLabel: context.l10n.continueEditing,
            destructive: _draftController == null,
          )) {
        if (!mounted) return;
        setState(() => _leaving = true);
        await _draftController?.flush();
        if (mounted) leave();
      }
    } catch (_) {
      // A failed flush keeps the form open with a visible retry action.
    } finally {
      _confirmingBack = false;
      if (mounted) setState(() => _leaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final saveState = ref.watch(sessionFormControllerProvider(_saveId));
    final saving = _saving;
    final saveError = saveState.hasError
        ? strings.saveSessionFailed
        : _draftController?.error != null
        ? strings.reviewDraftFailed
        : null;
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
            hours: _hours,
            minutes: _minutes,
            seconds: _seconds,
            practiced: _practiced,
            difficulty: _difficulty,
            next: _next,
            bpm: _bpm,
            date: _date,
            mood: _mood,
            focus: _focus,
            titleFocus: _titleFocus,
            instrumentName: widget.instrumentName,
            saving: saving,
            onDate: (value) {
              setState(() => _date = value);
              _inputChanged();
            },
            onMood: (value) {
              setState(() => _mood = value);
              _inputChanged();
            },
            onFocus: (value) {
              setState(() => _focus = value);
              _inputChanged();
            },
            error: saveError,
            onRetry: saveState.hasError ? _save : _retryDraft,
            durationError: _durationError,
          ),
        ),
      ),
    );
  }
}
