import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../shared/journal/journal_models.dart';
import '../../shared/journal/practice_timer_service.dart';
import '../application/practice_timer_service.dart';
import '../application/practice_review_provider.dart';
import '../application/review_save_completion.dart';
import '../application/startup_controller.dart';
import '../components/meloop_ui.dart';
import '../practice/practice_duration.dart';
import '../practice/practice_instrument_art.dart';
import '../practice/practice_tools_page.dart';
import '../practice_sessions/practice_session.dart' as ui;
import '../practice_sessions/practice_session_detail_page.dart';
import '../practice_sessions/practice_sessions_controller.dart';
import '../theme/tokens/practice_tokens.dart';
import 'metronome_example.dart';
import 'preview_copy.dart';
import 'session_form_example.dart';

/// Projects the app-scoped snapshot; owns no clock or elapsed state.
class TimerExample extends ConsumerStatefulWidget {
  const TimerExample({super.key, this.readOnly = false});
  final bool readOnly;
  @override
  ConsumerState<TimerExample> createState() => _TimerExampleState();
}

class _TimerExampleState extends ConsumerState<TimerExample> {
  bool _finishing = false;
  String? _error;
  late final PracticeTimerService? _journal = ref.read(
    practiceTimerServiceProvider,
  );
  Future<void> _action(Future<void> Function() command) async {
    try {
      await command();
    } catch (_) {
      if (mounted) setState(() => _error = context.l10n.practiceActionFailed);
    }
  }

  @override
  void dispose() {
    if (_journal?.snapshot?.state == PracticeState.running) {
      unawaited(_journal!.pause().catchError((Object _) {}));
    }
    super.dispose();
  }

  Future<void> _back() async {
    final service = _journal;
    if (service != null) {
      await _action(service.pause);
      if (!mounted || service.snapshot?.failed == true) return;
      ref
          .read(meloopShellControllerProvider.notifier)
          .checkpointDraft(
            seconds:
                service.snapshot!.elapsedMilliseconds ~/
                Duration.millisecondsPerSecond,
            isRunning: false,
          );
    }
    if (mounted) ref.read(meloopShellControllerProvider.notifier).showMain();
  }

  Future<void> _finish() async {
    if (_finishing || _journal == null) return;
    setState(() {
      _finishing = true;
      _error = null;
    });
    try {
      final service = _journal;
      await service.finish();
      final id = service.snapshot!.sessionId;
      final draft = await ref.read(practiceReviewLoadProvider)(id);
      if (!mounted) return;
      final profile = ref
          .read(meloopShellControllerProvider)
          .profiles
          .firstWhere((p) => p.id == draft.session.profileId);
      final shell = ref.read(meloopShellControllerProvider.notifier);
      shell.checkpointDraft(
        seconds:
            draft.accumulatedMilliseconds ~/ Duration.millisecondsPerSecond,
        isRunning: false,
      );
      final container = ProviderScope.containerOf(context);
      final save = container.read(practiceReviewSaveProvider);
      final complete = container.read(practiceReviewCompleteProvider);
      final persist = container.read(practiceReviewPersistProvider);
      final filters = container.read(
        practiceSessionsControllerProvider.notifier,
      );
      final now = container.read(ui.practiceSessionsClockProvider);
      final completion = ReviewSaveCompletion(
        save: (values) => save(id, values),
        complete: () async {
          final counts = await complete(id);
          shell.refreshSavedSessionCounts(counts);
          shell.completeDraft(sessionId: id);
        },
      );
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (routeContext) => UncontrolledProviderScope(
            container: container,
            child: SessionFormExample(
              sessionId: id,
              initialReviewInput: draft.reviewInput,
              instrumentName: profileDisplayName(context.l10n, profile),
              onPersistInput: (input) => persist(id, input),
              isSaveCommitted: () => completion.saved != null,
              initialTitle: draft.session.title,
              initialDurationSeconds:
                  draft.accumulatedMilliseconds ~/
                  Duration.millisecondsPerSecond,
              initialValues: SessionFormValues(
                title: draft.session.title,
                date: DateTime.parse(draft.session.practiceDate.value),
                durationSeconds:
                    draft.accumulatedMilliseconds ~/
                    Duration.millisecondsPerSecond,
                practiced: draft.session.practiced,
                difficulty: draft.session.difficulty,
                next: draft.session.next,
                mood: draft.session.mood,
                focus: draft.session.focus,
                bpm: draft.session.bpm,
              ),
              onSave: completion.submit,
              onSaved: () {
                if (!routeContext.mounted) return;
                filters.clear(profile.id);
                shell.selectProfile(profile.id);
                shell.selectTab(1);
                Navigator.of(routeContext).pushReplacement<void, void>(
                  MaterialPageRoute(
                    builder: (detailContext) => UncontrolledProviderScope(
                      container: container,
                      child: PracticeSessionDetailPage(
                        session: completion.saved!,
                        profile: profile,
                        now: now(),
                        onHome: () {
                          Navigator.of(detailContext)
                              .popUntil((route) => route.isFirst);
                          shell.selectTab(0);
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
      if (completion.saved == null &&
          !completion.isSubmitting &&
          service.snapshot?.sessionId == id) {
        await service.leaveReview();
      }
    } catch (_) {
      if (mounted) setState(() => _error = context.l10n.practiceActionFailed);
    } finally {
      if (mounted) setState(() => _finishing = false);
    }
  }

  void _tools(String sessionId) => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (toolsContext) => PracticeToolsPage(
        sessionId: sessionId,
        onOpenMetronome: () => Navigator.of(toolsContext).push<void>(
          MaterialPageRoute(
            builder: (_) => MetronomeExample(
              onHome: () {
                Navigator.of(toolsContext).pop();
                unawaited(_back());
              },
            ),
          ),
        ),
      ),
    ),
  );

  Future<void> _rename() async {
    final draft = ref.read(meloopShellControllerProvider).draft!;
    final update = ref.read(practiceTitleUpdateProvider);
    if (update == null || draft.sessionId == null) return;
    final title = TextEditingController(text: draft.title);
    final form = GlobalKey<FormState>();
    try {
      await showMeloopSheet<void>(
        context,
        title: context.l10n.renamePractice,
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MeloopField(
                label: context.l10n.sessionTitle,
                controller: title,
                validator: (value) =>
                    MeloopValidation.titleFor(value, context.l10n),
              ),
              const SizedBox(height: TempoSpace.md),
              MeloopButton(
                label: context.l10n.renamePractice,
                onPressed: () async {
                  if (!form.currentState!.validate()) return;
                  await _action(() async {
                    final normalized = await update(
                      draft.sessionId!,
                      title.text,
                    );
                    if (!mounted) return;
                    ref
                        .read(meloopShellControllerProvider.notifier)
                        .renameDraft(draft.sessionId!, normalized);
                    Navigator.of(context).pop();
                  });
                },
              ),
            ],
          ),
        ),
      );
    } finally {
      title.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(meloopShellControllerProvider);
    ref.watch(practiceTimerSnapshotProvider);
    final draft = state.selectedDraft;
    final snapshot = _journal?.snapshot;
    final timer =
        snapshot?.sessionId == draft?.sessionId &&
            snapshot?.profileId == draft?.profileId
        ? snapshot
        : null;
    final profile = state.profiles
        .where((p) => p.id == draft?.profileId)
        .firstOrNull;
    if (draft == null || profile == null) return const SizedBox.shrink();
    final strings = context.l10n;
    final seconds = timer == null
        ? draft.accumulatedSeconds
        : timer.elapsedMilliseconds ~/ Duration.millisecondsPerSecond;
    final running = timer?.state == PracticeState.running;
    final review = timer == null
        ? draft.isReview
        : timer.state == PracticeState.review;
    final blocked =
        widget.readOnly ||
        timer == null ||
        timer.busy ||
        timer.failed ||
        _finishing;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_back());
      },
      child: MeloopPage(
        padding: PracticeTempo.pagePadding,
        topBar: MeloopTopBar(
          title: strings.timerTitle,
          onBack: _finishing ? null : _back,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ProfileHeader(
              profile: profile,
              title: draft.title,
              onRename:
                  blocked || ref.watch(practiceTitleUpdateProvider) == null
                  ? null
                  : _rename,
            ),
            if (widget.readOnly && timer == null)
              MeloopNotice(message: strings.journalRecoveryPending),
            _TimerStage(
              seconds: seconds,
              running: running,
              review: review,
              instrument: profile.instrument,
            ),
            if (timer?.failed == true) ...[
              MeloopNotice(
                message: strings.timerCheckpointFailed,
                kind: MeloopNoticeKind.error,
              ),
              MeloopButton(
                label: strings.retry,
                onPressed: timer!.busy ? null : () => _action(_journal!.retry),
              ),
            ] else if (_error != null)
              MeloopNotice(message: _error!, kind: MeloopNoticeKind.error),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: PracticeTempo.actionGap,
              children: [
                MeloopButton(
                  label: running ? strings.pause : strings.resume,
                  icon: running ? MeloopIcons.pause : MeloopIcons.play,
                  prominent: true,
                  borderRadius: TempoRadius.pill,
                  minimumHeight: PracticeTempo.timerButtonHeight,
                  onPressed: blocked || review
                      ? null
                      : () => _action(
                          running ? _journal!.pause : _journal!.resume,
                        ),
                ),
                MeloopButton(
                  label: strings.practiceTools,
                  icon: MeloopIcons.music,
                  style: MeloopButtonStyle.soft,
                  prominent: true,
                  borderRadius: TempoRadius.pill,
                  minimumHeight: PracticeTempo.toolsButtonHeight,
                  backgroundColor: PracticeTempo.toolsActionBackground,
                  onPressed: widget.readOnly || timer == null
                      ? null
                      : () => _tools(timer.sessionId),
                ),
                MeloopButton(
                  label: strings.finish,
                  style: MeloopButtonStyle.orange,
                  prominent: true,
                  borderRadius: TempoRadius.pill,
                  minimumHeight: PracticeTempo.timerButtonHeight,
                  onPressed: blocked ? null : _finish,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.profile,
    required this.title,
    this.onRename,
  });
  final PreviewInstrumentProfile profile;
  final String title;
  final VoidCallback? onRename;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < PracticeTempo.compactContentWidth;
      final cover = PracticeProfileCover(
        key: const Key('practice-profile-cover'),
        instrument: profile.instrument,
        size: compact
            ? PracticeTempo.compactProfileCover
            : PracticeTempo.profileCover,
      );
      final copy = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            profileDisplayName(context.l10n, profile),
            style: PracticeTempo.profileName,
          ),
          const SizedBox(height: TempoSpace.sm),
          Text(
            context.l10n.timerOptionalTitle,
            style: PracticeTempo.titleCaption,
          ),
          TextButton(
            onPressed: onRename,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
              textStyle: PracticeTempo.sessionName,
              disabledForegroundColor: TempoColors.ink,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    title.isEmpty ? context.l10n.setPracticeName : title,
                  ),
                ),
                const SizedBox(width: PracticeTempo.titleIconGap),
                const MeloopIcon(
                  MeloopIcons.edit,
                  size: PracticeTempo.titleIconSize,
                ),
              ],
            ),
          ),
        ],
      );
      if (MediaQuery.textScalerOf(context).scale(16) > 20) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: TempoSpace.md,
          children: [cover, copy],
        );
      }
      return Row(
        children: [
          cover,
          const SizedBox(width: PracticeTempo.profileGap),
          Expanded(child: copy),
        ],
      );
    },
  );
}

class _TimerStage extends StatelessWidget {
  const _TimerStage({
    required this.seconds,
    required this.running,
    required this.review,
    required this.instrument,
  });
  final int seconds;
  final bool running, review;
  final MeloopInstrument instrument;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= PracticeTempo.wideContentWidth;
      final largeText = MediaQuery.textScalerOf(context).scale(16) > 20;
      final duration = formatPracticeDuration(Duration(seconds: seconds));
      final readout = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            review
                ? context.l10n.journalReviewState
                : running
                ? context.l10n.timerRunning.toUpperCase()
                : context.l10n.timerPaused,
            style: PracticeTempo.runningLabel,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: TempoSpace.sm),
          Text(
            duration,
            key: const Key('practice-elapsed'),
            style: duration.length > 5 || largeText
                ? PracticeTempo.longReadout
                : wide
                ? PracticeTempo.wideReadout
                : constraints.maxWidth < PracticeTempo.compactContentWidth
                ? PracticeTempo.compactReadout
                : PracticeTempo.readout,
            textAlign: TextAlign.center,
          ),
          Text(
            context.l10n.practiceTime,
            style: TempoType.label,
            textAlign: TextAlign.center,
          ),
        ],
      );
      final height = wide
          ? PracticeTempo.wideStageHeight
          : PracticeTempo.stageHeight;
      final artwork = PracticeTimerArtwork(
        key: const Key('practice-timer-artwork'),
        instrument: instrument,
        height: height,
      );
      if (largeText) {
        return Column(
          children: [
            artwork,
            readout,
            const SizedBox(height: TempoSpace.xl),
          ],
        );
      }
      return SizedBox(
        height: height - PracticeTempo.stageOverlap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -PracticeTempo.stageOverlap,
              left: 0,
              right: 0,
              child: artwork,
            ),
            Positioned(
              top:
                  (wide
                      ? PracticeTempo.wideReadoutTop
                      : PracticeTempo.readoutTop) -
                  PracticeTempo.stageOverlap,
              left:
                  (wide
                      ? PracticeTempo.wideReadoutLeft
                      : constraints.maxWidth < PracticeTempo.compactContentWidth
                      ? PracticeTempo.compactReadoutLeft
                      : PracticeTempo.readoutLeft) -
                  TempoSpace.page,
              right:
                  (wide
                      ? PracticeTempo.wideReadoutRight
                      : PracticeTempo.readoutRight) -
                  TempoSpace.page,
              child: readout,
            ),
          ],
        ),
      );
    },
  );
}
