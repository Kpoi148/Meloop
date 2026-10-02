import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../shared/journal/journal_models.dart';
import '../../shared/journal/journal_text.dart';
import '../../shared/journal/practice_timer_service.dart';
import '../application/practice_timer_service.dart';
import '../application/session_form_controller.dart';
import '../application/startup_controller.dart';
import '../components/meloop_ui.dart';
import 'metronome_example.dart';
import 'preview_copy.dart';
import 'session_form_example.dart';

class TimerExample extends ConsumerStatefulWidget {
  const TimerExample({super.key, this.readOnly = false});
  final bool readOnly;

  @override
  ConsumerState<TimerExample> createState() => _TimerExampleState();
}

class _TimerExampleState extends ConsumerState<TimerExample> {
  Timer? _ticker;
  late int _seconds;
  late bool _running;
  String? _draftProfileId;
  PracticeTimerService? _journal;
  bool _finishing = false;

  Future<void> _journalAction(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      /* The service publishes retained values and Retry state. */
    }
  }

  @override
  void initState() {
    super.initState();
    final draft = ref.read(meloopShellControllerProvider).draft;
    if (draft?.sessionId != null) {
      _journal = ref.read(practiceTimerServiceProvider);
    }
    _seconds = draft?.accumulatedSeconds ?? 0;
    _running = !widget.readOnly && (draft?.isRunning ?? false);
    _draftProfileId = draft?.profileId;
    if (_journal == null) _syncTicker();
  }

  @override
  void didUpdateWidget(covariant TimerExample oldWidget) {
    super.didUpdateWidget(oldWidget);
    final draft = ref.read(meloopShellControllerProvider).draft;
    if (draft != null && draft.profileId != _draftProfileId) {
      _seconds = draft.accumulatedSeconds;
      _running = draft.isRunning;
      _draftProfileId = draft.profileId;
      if (_journal == null) _syncTicker();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    final journal = _journal;
    if (journal?.snapshot?.state == PracticeState.running) {
      unawaited(_journalAction(journal!.pause));
    }
    super.dispose();
  }

  void _syncTicker() {
    _ticker?.cancel();
    if (!_running) return;
    _ticker = Timer.periodic(PracticeRules.timerRefreshInterval, (_) {
      if (!mounted) return;
      setState(
        () => _seconds = (_seconds + 1).clamp(
          0,
          PracticeRules.maximumDuration.inSeconds,
        ),
      );
    });
  }

  Future<void> _toggle() async {
    final journal = _journal;
    if (journal != null) {
      await _journalAction(
        journal.snapshot?.state == PracticeState.running
            ? journal.pause
            : journal.resume,
      );
      return;
    }
    setState(() => _running = !_running);
    _syncTicker();
    ref
        .read(meloopShellControllerProvider.notifier)
        .checkpointDraft(seconds: _seconds, isRunning: _running);
  }

  Future<void> _back() async {
    if (_journal != null) {
      await _journalAction(_journal!.pause);
      if (!mounted || _journal!.snapshot?.failed == true) return;
      final timer = _journal!.snapshot!;
      ref
          .read(meloopShellControllerProvider.notifier)
          .checkpointDraft(
            seconds:
                timer.elapsedMilliseconds ~/ Duration.millisecondsPerSecond,
            isRunning: false,
          );
      ref.read(meloopShellControllerProvider.notifier).showMain();
      return;
    }
    _running = false;
    _syncTicker();
    final controller = ref.read(meloopShellControllerProvider.notifier);
    if (!widget.readOnly) {
      controller.checkpointDraft(seconds: _seconds, isRunning: false);
    }
    controller.showMain();
  }

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    try {
      final journal = _journal;
      if (journal != null) {
        await _journalAction(journal.pause);
        if (!mounted || journal.snapshot?.failed == true) return;
        _seconds =
            journal.snapshot!.elapsedMilliseconds ~/
            Duration.millisecondsPerSecond;
      }
      _running = false;
      _syncTicker();
      final shell = ref.read(meloopShellControllerProvider.notifier);
      shell.checkpointDraft(seconds: _seconds, isRunning: false);
      shell.finishDraft();
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => SessionFormExample(
            onHome: () {
              Navigator.of(context).pop();
              shell.selectTab(0);
            },
            sessionId: ref.read(meloopShellControllerProvider).draft?.sessionId,
            initialTitle:
                ref.read(meloopShellControllerProvider).draft?.title ?? '',
            initialDurationSeconds: _seconds.clamp(
              1,
              PracticeRules.maximumDuration.inSeconds,
            ),
            onSave: (values) async {
              await ref.read(sessionFormSaveProvider)(values);
              shell.completeDraft();
            },
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _finishing = false);
    }
  }

  void _metronome() => Navigator.of(context).push<void>(
    MaterialPageRoute(builder: (_) => MetronomeExample(onHome: _back)),
  );

  String _duration(int elapsedSeconds) {
    final hours = elapsedSeconds ~/ 3600;
    final minutes = elapsedSeconds % 3600 ~/ 60;
    final seconds = elapsedSeconds % 60;
    final core =
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
    return hours == 0 ? core : '${hours.toString().padLeft(2, '0')}:$core';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(meloopShellControllerProvider);
    final draft = state.draft;
    if (_journal != null) ref.watch(practiceTimerSnapshotProvider);
    final timer = _journal?.snapshot;
    final seconds = timer == null
        ? _seconds
        : timer.elapsedMilliseconds ~/ Duration.millisecondsPerSecond;
    final running = timer == null
        ? _running
        : timer.state == PracticeState.running;
    final review = timer == null
        ? draft?.isReview == true
        : timer.state == PracticeState.review;
    final profile = state.profiles
        .where((p) => p.id == draft?.profileId)
        .firstOrNull;
    final strings = context.l10n;
    if (draft == null || profile == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(meloopShellControllerProvider.notifier).showMain();
      });
      return const SizedBox.shrink();
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _back();
      },
      child: MeloopPage(
        topBar: MeloopTopBar(title: strings.timerTitle, onBack: _back),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: TempoSpace.page,
          children: [
            MeloopCard(
              color: TempoColors.soft,
              child: Row(
                children: [
                  MeloopArt.instrument(profile.instrument, size: 72),
                  const SizedBox(width: TempoSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profileDisplayName(strings, profile),
                          style: TempoType.label,
                        ),
                        Text(
                          strings.timerOptionalTitle,
                          style: TempoType.caption,
                        ),
                        Text(
                          draft.title.isEmpty
                              ? strings.setPracticeName
                              : draft.title,
                          style: TempoType.title,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (widget.readOnly && _journal == null)
              MeloopNotice(message: strings.journalRecoveryPending),
            if (_journal != null && timer?.failed == true) ...[
              MeloopNotice(
                message: strings.timerCheckpointFailed,
                kind: MeloopNoticeKind.error,
              ),
              MeloopButton(
                label: strings.retry,
                loadingLabel: strings.retrying,
                onPressed: timer!.busy
                    ? null
                    : () => _journalAction(_journal!.retry),
              ),
            ],
            Stack(
              alignment: Alignment.center,
              children: [
                const MeloopIllustration(
                  asset: 'fidelity-timer.png',
                  height: 330,
                ),
                Column(
                  children: [
                    Text(
                      review
                          ? strings.journalReviewState
                          : running
                          ? strings.timerRunning
                          : strings.timerPaused,
                      style: TempoType.label,
                    ),
                    Text(_duration(seconds), style: TempoType.metric),
                    Text(strings.practiceTime, style: TempoType.caption),
                  ],
                ),
              ],
            ),
            MeloopButton(
              label: running ? strings.pause : strings.resume,
              icon: running ? MeloopIcons.pause : MeloopIcons.play,
              loadingLabel: strings.processing,
              onPressed: _journal != null
                  ? (widget.readOnly ||
                            timer?.busy == true ||
                            timer?.failed == true ||
                            review
                        ? null
                        : _toggle)
                  : widget.readOnly
                  ? null
                  : _toggle,
            ),
            MeloopButton(
              label: strings.practiceTools,
              icon: MeloopIcons.music,
              style: MeloopButtonStyle.soft,
              onPressed: widget.readOnly ? null : _metronome,
            ),
            MeloopButton(
              label: strings.finish,
              style: MeloopButtonStyle.orange,
              onPressed:
                  widget.readOnly ||
                      _finishing ||
                      timer?.busy == true ||
                      timer?.failed == true
                  ? null
                  : _finish,
            ),
          ],
        ),
      ),
    );
  }
}
