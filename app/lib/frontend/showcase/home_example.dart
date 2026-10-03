import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../application/startup_controller.dart';
import '../components/meloop_ui.dart';
import '../home/overview_tokens.dart';
import '../home/overview_widgets.dart';
import '../home/practice_overview_provider.dart';
import '../practice_sessions/practice_session.dart';
import '../practice_sessions/practice_session_copy.dart';
import '../practice_sessions/practice_session_summary.dart';
import 'preview_copy.dart';

/// Tempo Home renders supplied saved records; it never creates sample data.
class HomeExample extends StatelessWidget {
  const HomeExample({
    super.key,
    required this.profile,
    required this.overview,
    required this.onCreate,
    required this.onProgress,
    required this.onCatalog,
    required this.onRetry,
    this.draft,
    this.onInstrument,
  });
  final PreviewInstrumentProfile profile;
  final AsyncValue<PracticeOverview> overview;
  final VoidCallback onCreate, onProgress, onCatalog, onRetry;
  final PreviewPracticeDraft? draft;
  final VoidCallback? onInstrument;
  PracticeSessionSummary? get sessionSummary => overview.value?.summary;

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final currentDraft = draft?.profileId == profile.id ? draft : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HomeHeader(profile: profile, onInstrument: onInstrument),
        overview.when(
          skipLoadingOnRefresh: false,
          data: (data) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PracticeStatisticsCard(
                summary: data.summary,
                onProgress: onProgress,
              ),
              const SizedBox(height: TempoSpace.lg),
              WeeklyGoalStrip(summary: data.summary, goal: data.goal),
            ],
          ),
          error: (_, _) => MeloopStateView(
            state: MeloopViewState.error,
            title: strings.practiceOverviewLoadFailed,
            actionLabel: strings.retry,
            onAction: onRetry,
          ),
          loading: () => MeloopStateView(
            state: MeloopViewState.loading,
            title: strings.practiceOverviewLoading,
          ),
        ),
        const SizedBox(height: TempoSpace.md),
        MeloopButton(
          label: currentDraft == null
              ? strings.createPractice
              : currentDraft.instrumentName == null
              ? strings.continuePractice
              : strings.continueInstrumentPractice(
                  currentDraft.instrumentName!,
                ),
          prominent: true,
          style: MeloopButtonStyle.yellow,
          icon: currentDraft == null ? MeloopIcons.plus : MeloopIcons.play,
          onPressed: onCreate,
        ),
        const SizedBox(height: TempoSpace.sm),
        Material(
          color: TempoColors.fieldFill,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TempoRadius.action),
            side: const BorderSide(color: TempoColors.line),
          ),
          child: InkWell(
            onTap: onCatalog,
            borderRadius: BorderRadius.circular(TempoRadius.action),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: TempoSpace.md,
                vertical: TempoSpace.xs,
              ),
              child: Row(
                children: [
                  const MeloopArt.tool(
                    MeloopTool.metro,
                    size: OverviewTokens.toolsArtSize,
                  ),
                  const SizedBox(width: TempoSpace.md),
                  Expanded(
                    child: Text(
                      strings.practiceTools,
                      style: TempoType.compactTitle,
                    ),
                  ),
                  const MeloopIcon(MeloopIcons.arrow),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: TempoSpace.md),
        // Intentionally no history link, status badge or interaction in this block.
        Column(
          key: const Key('home-recent-session'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(strings.recentSession, style: TempoType.section),
            const SizedBox(height: TempoSpace.sm),
            if (overview.hasValue) ...[
              if (overview.requireValue.summary.latest case final session?)
                _RecentCard(
                  session: session,
                  profile: profile,
                  today: overview.requireValue.summary.days.last,
                )
              else
                MeloopStateView(
                  state: MeloopViewState.empty,
                  title: strings.noPracticeSessions,
                  message: strings.profileSessionsEmptyMessage,
                ),
            ],
          ],
        ),
      ],
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.profile, this.onInstrument});
  final PreviewInstrumentProfile profile;
  final VoidCallback? onInstrument;
  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MeloopTopBar(
          trailing: SelectedInstrumentChip(
            profile: profile,
            onPressed: onInstrument,
          ),
        ),
        const SizedBox(height: TempoSpace.page),
        Text(strings.overview, style: TempoType.heading),
        Text(profileDisplayName(strings, profile)),
        const SizedBox(height: TempoSpace.lg),
      ],
    );
    if (MediaQuery.textScalerOf(context).scale(16) > 20) return content;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          right: OverviewTokens.heroRight,
          top: OverviewTokens.heroTop,
          child: Transform.rotate(
            angle: OverviewTokens.heroAngle,
            child: profile.instrument == MeloopInstrument.guitar
                ? const MeloopArt.scene(
                    MeloopScene.guitar,
                    size: OverviewTokens.heroArtSize,
                  )
                : MeloopArt.instrument(
                    profile.instrument,
                    size: OverviewTokens.heroArtSize,
                  ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    TempoColors.paper,
                    TempoColors.paper.withValues(alpha: .75),
                    TempoColors.paper.withValues(alpha: 0),
                  ],
                  stops: const [0, .35, .75],
                ),
              ),
            ),
          ),
        ),
        content,
      ],
    );
  }
}

class _RecentCard extends StatelessWidget {
  const _RecentCard({
    required this.session,
    required this.profile,
    required this.today,
  });
  final PracticeSession session;
  final PreviewInstrumentProfile profile;
  final DateTime today;
  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final duration = practiceDuration(strings, session.duration);
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: TempoSpace.xs,
      children: [
        Text(
          session.title,
          style: TempoType.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          practiceDayLabel(strings, session.date, today),
          style: TempoType.compactBody,
        ),
        Text(
          session.bpm == null
              ? duration
              : strings.practiceDurationWithBpm(duration, session.bpm!),
          style: TempoType.compactBody,
        ),
        if (session.practiced.isNotEmpty)
          Text(
            session.practiced,
            style: TempoType.compactBody,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
    return MeloopCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < OverviewTokens.compactRecentWidth ||
              MediaQuery.textScalerOf(context).scale(16) > 20) {
            return body;
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: OverviewTokens.recentArtWidth,
                height: OverviewTokens.recentArtHeight,
                child: ClipRect(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: MeloopArt.instrument(
                      profile.instrument,
                      size: OverviewTokens.recentArtHeight,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: TempoSpace.md),
              Expanded(child: body),
            ],
          );
        },
      ),
    );
  }
}
