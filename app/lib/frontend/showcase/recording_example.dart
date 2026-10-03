import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../shared/journal/journal_models.dart';
import '../application/practice_timer_service.dart';
import '../components/meloop_ui.dart';
import '../recording/recording_page.dart';
import '../recording/recording_ui_state.dart';
import 'recording_preview_controller.dart';

/// UI-only adapter; recording inputs and interactions stay in the showcase.
class RecordingExample extends ConsumerStatefulWidget {
  const RecordingExample({
    super.key,
    required this.sessionId,
    required this.title,
    required this.profileName,
    required this.onHome,
  });
  final String sessionId, title, profileName;
  final VoidCallback onHome;

  @override
  ConsumerState<RecordingExample> createState() => _RecordingExampleState();
}

class _RecordingExampleState extends ConsumerState<RecordingExample>
    with WidgetsBindingObserver {
  late final RecordingPreviewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ref.read(recordingPreviewControllerProvider.notifier);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _controller.stop(widget.sessionId, issue: RecordingIssue.interrupted);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.closePreview(widget.sessionId);
    super.dispose();
  }

  void _back() {
    _controller.stop(widget.sessionId);
    Navigator.of(context).pop();
  }

  void _home() {
    _back();
    widget.onHome();
  }

  Future<void> _discard() async {
    _controller.stop(widget.sessionId);
    final strings = context.l10n;
    if (await showMeloopConfirm(
      context,
      title: strings.recordingDiscardTitle,
      message: strings.recordingDiscardMessage,
      confirmLabel: strings.recordingDiscard,
      destructive: true,
    )) {
      _controller.discard(widget.sessionId);
    }
  }

  void _keep() {
    if (_controller.keep(widget.sessionId)) {
      MeloopNotifications.show(
        context,
        context.l10n.recordingKept,
        kind: MeloopNoticeKind.success,
      );
    }
  }

  void _start(bool running) {
    if (_controller.forSession(widget.sessionId).phase ==
        RecordingPhase.review) {
      MeloopNotifications.show(context, context.l10n.recordingPendingHint);
      return;
    }
    _controller.start(widget.sessionId, sessionRunning: running);
  }

  Future<void> _viewPro() async {
    _controller.stop(widget.sessionId);
    final strings = context.l10n;
    await showMeloopSheet<void>(
      context,
      title: strings.recordingProTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: TempoSpace.lg,
        children: [
          Text(strings.recordingProDescription),
          Text(strings.recordingProJournalHint, style: TempoType.caption),
          MeloopButton(
            label: strings.recordingContinuePractice,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(recordingPreviewControllerProvider);
    ref.watch(recordingPreviewInputsProvider);
    ref.watch(practiceTimerSnapshotProvider);
    final snapshot = ref.watch(practiceTimerServiceProvider)?.snapshot;
    final running =
        snapshot?.sessionId == widget.sessionId &&
        snapshot?.state == PracticeState.running &&
        snapshot?.busy == false &&
        snapshot?.failed == false;
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _controller.stop(widget.sessionId);
      },
      child: RecordingPage(
        title: widget.title,
        profileName: widget.profileName,
        state: _controller.forSession(widget.sessionId),
        sessionRunning: running,
        onBack: _back,
        onHome: _home,
        onStart: () => _start(running),
        onStop: () => _controller.stop(widget.sessionId),
        onKeep: _keep,
        onDiscard: _discard,
        onTogglePlayback: () => _controller.togglePlayback(widget.sessionId),
        onSeek: (position) => _controller.seek(widget.sessionId, position),
        onViewPro: _viewPro,
      ),
    );
  }
}
