import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../application/startup_controller.dart';
import '../components/meloop_ui.dart';
import '../showcase/preview_copy.dart';
import 'practice_session.dart';
import 'practice_session_card.dart';
import 'practice_session_copy.dart';
import 'practice_session_detail_page.dart';
import 'practice_sessions_controller.dart';
import 'practice_sessions_filter_sheet.dart';
import 'practice_sessions_tokens.dart';
import '../theme/tokens/practice_tokens.dart';

class PracticeSessionsTab extends ConsumerStatefulWidget {
  const PracticeSessionsTab({
    super.key,
    required this.profile,
    required this.onCreate,
    required this.onContinue,
    required this.onInstrument,
    required this.bottomNavigation,
    required this.scrollController,
    this.draft,
    this.onHome,
    this.onOpenRecording,
  });

  final PreviewInstrumentProfile profile;
  final PreviewPracticeDraft? draft;
  final Future<void> Function() onCreate;
  final VoidCallback onContinue, onInstrument;
  final VoidCallback? onHome;
  final Future<void> Function(BuildContext)? onOpenRecording;
  final Widget bottomNavigation;
  final ScrollController scrollController;

  @override
  ConsumerState<PracticeSessionsTab> createState() =>
      _PracticeSessionsTabState();
}

class _PracticeSessionsTabState extends ConsumerState<PracticeSessionsTab> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final scroll = widget.scrollController;
    final position = scroll.offset;
    FocusManager.instance.primaryFocus?.unfocus();
    await widget.onCreate();
    if (!mounted || !scroll.hasClients) return;
    scroll.jumpTo(
      position.clamp(
        scroll.position.minScrollExtent,
        scroll.position.maxScrollExtent,
      ),
    );
  }

  void _open(PracticeSession session) {
    if (session.profileId != widget.profile.id) return;
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PracticeSessionDetailPage(
          onOpenRecording: widget.onOpenRecording,
          session: session,
          profile: widget.profile,
          now: ref.read(practiceSessionsClockProvider)(),
          onHome: widget.onHome == null
              ? null
              : () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  widget.onHome!();
                },
        ),
      ),
    );
  }

  Future<void> _filters() async {
    final profileId = widget.profile.id;
    final controller = ref.read(practiceSessionsControllerProvider.notifier);
    FocusManager.instance.primaryFocus?.unfocus();
    final filters = await showPracticeSessionsFilters(
      context,
      current: controller.forProfile(profileId).filters,
    );
    if (!mounted || filters == null || widget.profile.id != profileId) return;
    controller.applyFilters(profileId, filters);
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final profileId = widget.profile.id;
    final view =
        ref.watch(practiceSessionsControllerProvider)[profileId] ??
        const PracticeSessionsViewState();
    final controller = ref.read(practiceSessionsControllerProvider.notifier);
    if (_search.text != view.query) {
      _search.value = TextEditingValue(
        text: view.query,
        selection: TextSelection.collapsed(offset: view.query.length),
      );
    }
    final sessions = ref.watch(practiceSessionsProvider(widget.profile));
    final draft = widget.draft?.profileId == profileId ? widget.draft : null;
    final pageInset =
        MediaQuery.sizeOf(context).width <=
            PracticeSessionsTokens.narrowViewport
        ? PracticeSessionsTokens.narrowPageInset
        : TempoSpace.page;
    return MeloopPage(
      padding: EdgeInsets.fromLTRB(
        pageInset,
        TempoSpace.pageTop,
        pageInset,
        PracticeTempo.fabClearance,
      ),
      scrollController: widget.scrollController,
      floatingActionButton: SizedBox.square(
        dimension: PracticeTempo.fabSize,
        child: FloatingActionButton(
          key: const Key('practice-create'),
          tooltip: draft == null
              ? strings.createPractice
              : strings.continuePractice,
          backgroundColor: TempoColors.teal,
          foregroundColor: TempoColors.white,
          onPressed: _create,
          child: const MeloopIcon(MeloopIcons.plus),
        ),
      ),
      bottomNavigation: widget.bottomNavigation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MeloopTopBar(
            trailing: _ProfileChip(
              profile: widget.profile,
              onPressed: widget.onInstrument,
            ),
          ),
          _Heading(),
          if (draft != null) ...[
            _DraftCard(draft: draft, onContinue: widget.onContinue),
            const SizedBox(height: TempoSpace.page),
          ],
          Row(
            children: [
              Expanded(
                child: MeloopSearch(
                  controller: _search,
                  compact: true,
                  onChanged: (query) => controller.search(profileId, query),
                ),
              ),
              const SizedBox(width: TempoSpace.sm),
              Semantics(
                selected: view.filters.isActive,
                child: IconButton(
                  tooltip: strings.practiceFilters,
                  onPressed: _filters,
                  style: IconButton.styleFrom(
                    fixedSize: const Size.square(TempoSize.fieldMinHeight),
                    backgroundColor: view.filters.isActive
                        ? TempoColors.teal
                        : TempoColors.fieldFill,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(TempoRadius.field),
                      side: const BorderSide(color: TempoColors.fieldBorder),
                    ),
                  ),
                  icon: MeloopIcon(
                    MeloopIcons.filter,
                    color: view.filters.isActive
                        ? TempoColors.white
                        : TempoColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: PracticeSessionsTokens.searchBottomGap),
          sessions.when(
            skipLoadingOnRefresh: false,
            loading: () => MeloopStateView(
              state: MeloopViewState.loading,
              title: strings.loadingSessions,
            ),
            error: (_, _) => MeloopStateView(
              state: MeloopViewState.error,
              title: strings.loadSessionsFailed,
              message: strings.dataKeptRetry,
              actionLabel: strings.retry,
              onAction: () =>
                  ref.invalidate(practiceSessionsProvider(widget.profile)),
            ),
            data: (items) {
              final now = ref.read(practiceSessionsClockProvider)();
              final visible = view.visibleSessions(
                items,
                profileId: profileId,
                now: now,
              );
              if (!items.any((item) => item.profileId == profileId)) {
                return MeloopStateView(
                  state: MeloopViewState.empty,
                  title: strings.noPracticeSessions,
                  message: strings.practiceEmptyMessage,
                );
              }
              if (visible.isEmpty) {
                return MeloopStateView(
                  state: MeloopViewState.empty,
                  title: strings.noMatchingSessions,
                  message: strings.practiceNoResultsMessage,
                  actionLabel: strings.practiceClearSearchAndFilters,
                  onAction: () => controller.clear(profileId),
                );
              }
              final grouped = <DateTime, List<PracticeSession>>{};
              for (final session in visible) {
                grouped
                    .putIfAbsent(DateUtils.dateOnly(session.date), () => [])
                    .add(session);
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final group in grouped.entries) ...[
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: PracticeSessionsTokens.dayBottomGap,
                      ),
                      child: Text(
                        practiceGroupDayLabel(strings, group.key, now),
                        style: PracticeSessionsTokens.dayLabel,
                      ),
                    ),
                    for (final session in group.value) ...[
                      PracticeSessionCard(
                        key: ValueKey(session.id),
                        session: session,
                        instrument: widget.profile.instrument,
                        onOpen: () => _open(session),
                      ),
                      const SizedBox(height: TempoSpace.md),
                    ],
                    if (group.key != grouped.keys.last)
                      const SizedBox(
                        height: PracticeSessionsTokens.dayGap - TempoSpace.md,
                      ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.navHistory, style: PracticeSessionsTokens.heading),
        const SizedBox(height: PracticeSessionsTokens.subtitleGap),
        Text(
          context.l10n.historySubtitle,
          style: PracticeSessionsTokens.subtitle,
        ),
      ],
    );
    final baseFontSize = TempoType.body.fontSize!;
    final textScale =
        MediaQuery.textScalerOf(context).scale(baseFontSize) / baseFontSize;
    final artSize =
        MediaQuery.sizeOf(context).width <=
            PracticeSessionsTokens.narrowViewport
        ? PracticeSessionsTokens.narrowIntroArtSize
        : PracticeSessionsTokens.introArtSize;
    return Padding(
      padding: PracticeSessionsTokens.introMargin,
      child: textScale > PracticeSessionsTokens.introArtMaxTextScale
          ? copy
          : Row(
              children: [
                Expanded(child: copy),
                const SizedBox(width: PracticeSessionsTokens.introArtGap),
                Opacity(
                  opacity: PracticeSessionsTokens.introArtOpacity,
                  child: MeloopArt.scene(MeloopScene.journal, size: artSize),
                ),
              ],
            ),
    );
  }
}

class _ProfileChip extends StatelessWidget {
  const _ProfileChip({required this.profile, required this.onPressed});
  final PreviewInstrumentProfile profile;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.l10n.changeInstrument,
    button: true,
    child: Material(
      color: TempoColors.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TempoRadius.pill),
        side: const BorderSide(color: PracticeSessionsTokens.chipBorder),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(TempoRadius.pill),
        child: Padding(
          padding: PracticeSessionsTokens.chipPadding,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MeloopArt.instrument(
                profile.instrument,
                size: PracticeSessionsTokens.chipArtSize,
              ),
              const SizedBox(width: PracticeSessionsTokens.chipGap),
              Text(
                instrumentLabel(context.l10n, profile.instrument),
                style: PracticeSessionsTokens.chipLabel,
              ),
              const SizedBox(width: PracticeSessionsTokens.chipGap),
              const MeloopIcon(MeloopIcons.down, size: TempoSize.smallIcon),
            ],
          ),
        ),
      ),
    ),
  );
}

class _DraftCard extends StatelessWidget {
  const _DraftCard({required this.draft, required this.onContinue});
  final PreviewPracticeDraft draft;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    return MeloopCard(
      color: TempoColors.selection,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: TempoSpace.sm,
            runSpacing: TempoSpace.sm,
            children: [
              Text(strings.unfinishedPractice, style: TempoType.label),
              Text(
                draft.isReview
                    ? strings.journalReviewState
                    : draft.isRunning
                    ? strings.timerRunning
                    : strings.timerPaused,
                style: TempoType.caption,
              ),
            ],
          ),
          const SizedBox(height: TempoSpace.sm),
          Text(
            draft.title.isEmpty ? strings.timerTitle : draft.title,
            style: TempoType.title,
          ),
          const SizedBox(height: TempoSpace.xs),
          Text(draftDuration(draft.accumulatedSeconds), style: TempoType.label),
          const SizedBox(height: TempoSpace.md),
          MeloopButton(
            label: draft.instrumentName == null
                ? strings.continuePractice
                : strings.continueInstrumentPractice(draft.instrumentName!),
            icon: MeloopIcons.play,
            style: MeloopButtonStyle.soft,
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}
