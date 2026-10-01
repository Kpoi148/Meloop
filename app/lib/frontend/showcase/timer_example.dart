import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../application/session_form_controller.dart';
import '../application/startup_controller.dart';
import '../components/meloop_ui.dart';
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

  @override
  void initState() {
    super.initState();
    final draft = ref.read(meloopShellControllerProvider).draft;
    _seconds = draft?.accumulatedSeconds ?? 0;
    _running = !widget.readOnly && (draft?.isRunning ?? false);
    _draftProfileId = draft?.profileId;
    _syncTicker();
  }

  @override
  void didUpdateWidget(covariant TimerExample oldWidget) {
    super.didUpdateWidget(oldWidget);
    final draft = ref.read(meloopShellControllerProvider).draft;
    if (draft != null && draft.profileId != _draftProfileId) {
      _seconds = draft.accumulatedSeconds;
      _running = draft.isRunning;
      _draftProfileId = draft.profileId;
      _syncTicker();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _syncTicker() {
    _ticker?.cancel();
    if (!_running) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _seconds = (_seconds + 1).clamp(0, 86400));
    });
  }

  void _toggle() {
    setState(() => _running = !_running);
    _syncTicker();
    ref
        .read(meloopShellControllerProvider.notifier)
        .checkpointDraft(seconds: _seconds, isRunning: _running);
  }

  void _back() {
    _running = false;
    _syncTicker();
    final controller = ref.read(meloopShellControllerProvider.notifier);
    if (!widget.readOnly) {
      controller.checkpointDraft(seconds: _seconds, isRunning: false);
    }
    controller.showMain();
  }

  Future<void> _finish() async {
    _running = false;
    _syncTicker();
    final shell = ref.read(meloopShellControllerProvider.notifier);
    shell.checkpointDraft(seconds: _seconds, isRunning: false);
    shell.finishDraft();
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => SessionFormExample(
          initialTitle:
              ref.read(meloopShellControllerProvider).draft?.title ?? '',
          initialDurationSeconds: _seconds.clamp(1, 86400),
          onSave: (values) async {
            await ref.read(sessionFormSaveProvider)(values);
            shell.completeDraft();
          },
        ),
      ),
    );
  }

  String _duration() {
    final hours = _seconds ~/ 3600;
    final minutes = _seconds % 3600 ~/ 60;
    final seconds = _seconds % 60;
    final core =
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
    return hours == 0 ? core : '${hours.toString().padLeft(2, '0')}:$core';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(meloopShellControllerProvider);
    final draft = state.draft;
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
            if (draft.wasRecovered)
              MeloopNotice(
                message:
                    '${strings.recoveredDraftTitle}\n${strings.recoveredDraftMessage}',
              ),
            if (widget.readOnly)
              MeloopNotice(message: strings.journalRecoveryPending),
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
                      draft.isReview
                          ? strings.journalReviewState
                          : _running
                          ? strings.timerRunning
                          : strings.timerPaused,
                      style: TempoType.label,
                    ),
                    Text(_duration(), style: TempoType.metric),
                    Text(strings.practiceTime, style: TempoType.caption),
                  ],
                ),
              ],
            ),
            MeloopButton(
              label: _running ? strings.pause : strings.resume,
              icon: _running ? MeloopIcons.pause : MeloopIcons.play,
              onPressed: widget.readOnly ? null : _toggle,
            ),
            MeloopButton(
              label: strings.practiceTools,
              icon: MeloopIcons.music,
              style: MeloopButtonStyle.soft,
              onPressed: widget.readOnly ? null : () {},
            ),
            MeloopButton(
              label: strings.finish,
              style: MeloopButtonStyle.orange,
              onPressed: widget.readOnly ? null : _finish,
            ),
          ],
        ),
      ),
    );
  }
}
