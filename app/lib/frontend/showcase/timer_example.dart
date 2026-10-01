import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../application/practice_session_provider.dart';
import '../application/startup_controller.dart';
import '../components/meloop_ui.dart';
import '../practice/practice_duration.dart';
import '../practice/practice_instrument_art.dart';
import '../practice/practice_tools_page.dart';
import '../practice/practice_title_form.dart';
import '../practice/saved_practice_page.dart';
import '../theme/tokens/practice_tokens.dart';
import 'preview_copy.dart';
import 'session_form_example.dart';

/// Displays service snapshots. No clock or elapsed-time state lives here.
class TimerExample extends ConsumerStatefulWidget {
  const TimerExample({super.key});

  @override
  ConsumerState<TimerExample> createState() => _TimerExampleState();
}

class _TimerExampleState extends ConsumerState<TimerExample> {
  bool _busy = false;
  String? _error;

  PracticeSessionService get _service =>
      ref.read(practiceSessionServiceProvider)!;

  Future<void> _command(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (_) {
      if (mounted) setState(() => _error = context.l10n.practiceActionFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _back() => _command(() async {
    await _service.pause();
    if (mounted) ref.read(meloopShellControllerProvider.notifier).showMain();
  });

  Future<void> _finish() => _command(() async {
    final service = _service;
    final shell = ref.read(meloopShellControllerProvider.notifier);
    final profile = ref.read(meloopShellControllerProvider).selectedProfile!;
    final container = ProviderScope.containerOf(context);
    final draft = await service.finish();
    if (!mounted) return;
    SavedPracticeSession? saved;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (routeContext) => UncontrolledProviderScope(
          container: container,
          child: SessionFormExample(
            initialTitle: draft.title,
            initialDate: draft.startedAt,
            initialDurationSeconds: draft.elapsed.inSeconds,
            onSave: (values) async {
              saved = await service.save(draft.id, values);
            },
            onSaved: () {
              shell.selectTab(1);
              Navigator.of(routeContext).pushReplacement<void, void>(
                MaterialPageRoute(
                  builder: (_) =>
                      SavedPracticePage(session: saved!, profile: profile),
                ),
              );
            },
          ),
        ),
      ),
    );
    // Back from review keeps the same session, paused and ready to resume.
    if (service.current.draft?.id == draft.id) await service.leaveReview();
  });

  Future<void> _rename() => showMeloopSheet<void>(
    context,
    title: context.l10n.renamePractice,
    child: PracticeTitleForm(service: _service),
  );

  Future<void> _options() => showMeloopSheet<void>(
    context,
    title: context.l10n.timerOptions,
    child: Builder(
      builder: (sheetContext) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: TempoSpace.md,
        children: [
          MeloopButton(
            label: context.l10n.renamePractice,
            icon: MeloopIcons.edit,
            style: MeloopButtonStyle.outline,
            onPressed: () {
              Navigator.of(sheetContext).pop();
              unawaited(_rename());
            },
          ),
          MeloopButton(
            label: context.l10n.cancelPractice,
            icon: MeloopIcons.trash,
            style: MeloopButtonStyle.soft,
            onPressed: () async {
              Navigator.of(sheetContext).pop();
              final service = _service;
              final shell = ref.read(meloopShellControllerProvider.notifier);
              final cancelled = await showMeloopConfirm(
                context,
                title: context.l10n.cancelPracticeTitle,
                message: context.l10n.cancelPracticeMessage,
                confirmLabel: context.l10n.cancelPractice,
                cancelLabel: context.l10n.keepPracticing,
                destructive: true,
                onConfirm: service.discard,
                failureMessage: context.l10n.practiceActionFailed,
              );
              if (cancelled) shell.selectTab(1);
            },
          ),
        ],
      ),
    ),
  );

  void _tools(String id) {
    final container = ProviderScope.containerOf(context);
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => UncontrolledProviderScope(
          container: container,
          child: PracticeToolsPage(sessionId: id),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shell = ref.watch(meloopShellControllerProvider);
    final draft = _service.current.draft;
    final profile = shell.selectedProfile;
    final strings = context.l10n;
    if (draft == null || profile == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(meloopShellControllerProvider.notifier).showMain();
        }
      });
      return const SizedBox.shrink();
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_back());
      },
      child: MeloopPage(
        padding: PracticeTempo.pagePadding,
        topBar: MeloopTopBar(
          title: strings.timerTitle,
          onBack: _busy ? null : _back,
          trailing: IconButton(
            tooltip: strings.timerOptions,
            onPressed: _busy ? null : _options,
            icon: const MeloopIcon(MeloopIcons.more),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ProfileHeader(
              profile: profile,
              title: draft.title,
              onRename: _busy ? null : _rename,
            ),
            if (draft.wasRecovered) ...[
              const SizedBox(height: TempoSpace.md),
              MeloopNotice(
                message:
                    '${strings.recoveredDraftTitle}\n${strings.recoveredDraftMessage}',
              ),
            ],
            _TimerStage(draft: draft, instrument: profile.instrument),
            if (_error != null)
              MeloopNotice(message: _error!, kind: MeloopNoticeKind.error),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: PracticeTempo.actionGap,
              children: [
                MeloopButton(
                  label: draft.isRunning ? strings.pause : strings.resume,
                  icon: draft.isRunning ? MeloopIcons.pause : MeloopIcons.play,
                  prominent: true,
                  borderRadius: TempoRadius.pill,
                  minimumHeight: PracticeTempo.timerButtonHeight,
                  onPressed: _busy
                      ? null
                      : () => _command(
                          draft.isRunning ? _service.pause : _service.resume,
                        ),
                ),
                MeloopButton(
                  label: strings.timerTools,
                  icon: MeloopIcons.music,
                  style: MeloopButtonStyle.soft,
                  backgroundColor: PracticeTempo.toolsActionBackground,
                  prominent: true,
                  borderRadius: TempoRadius.pill,
                  minimumHeight: PracticeTempo.toolsButtonHeight,
                  onPressed: _busy ? null : () => _tools(draft.id),
                ),
                MeloopButton(
                  label: strings.finish,
                  style: MeloopButtonStyle.orange,
                  prominent: true,
                  borderRadius: TempoRadius.pill,
                  minimumHeight: PracticeTempo.timerButtonHeight,
                  onPressed: _busy ? null : _finish,
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
    required this.onRename,
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
          Text(context.l10n.sessionTitle, style: PracticeTempo.titleCaption),
          TextButton(
            onPressed: onRename,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
              textStyle: PracticeTempo.sessionName,
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
  const _TimerStage({required this.draft, required this.instrument});
  final PracticeSessionDraft draft;
  final MeloopInstrument instrument;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= PracticeTempo.wideContentWidth;
      final largeText = MediaQuery.textScalerOf(context).scale(16) > 20;
      final duration = formatPracticeDuration(draft.elapsed);
      final readout = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            (draft.isRunning
                    ? context.l10n.timerRunning
                    : context.l10n.timerPaused)
                .toUpperCase(),
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
