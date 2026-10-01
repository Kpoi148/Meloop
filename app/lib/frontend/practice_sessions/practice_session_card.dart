import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../components/meloop_ui.dart';
import 'practice_session.dart';
import 'practice_session_copy.dart';
import 'practice_sessions_tokens.dart';

class PracticeSessionCard extends StatelessWidget {
  const PracticeSessionCard({
    super.key,
    required this.session,
    required this.instrument,
    required this.onOpen,
  });

  final PracticeSession session;
  final MeloopInstrument instrument;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final body = Padding(
      padding: PracticeSessionsTokens.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(session.title, style: PracticeSessionsTokens.cardTitle),
          const SizedBox(height: PracticeSessionsTokens.cardTextGap),
          Text(
            session.bpm == null
                ? practiceDuration(strings, session.duration)
                : strings.practiceDurationWithBpm(
                    practiceDuration(strings, session.duration),
                    session.bpm!,
                  ),
            style: PracticeSessionsTokens.cardMeta,
          ),
          if (session.practiced.isNotEmpty) ...[
            const SizedBox(height: PracticeSessionsTokens.cardTextGap),
            Text(
              session.practiced,
              style: PracticeSessionsTokens.cardNotes,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (session.mood != null ||
              session.focus != null ||
              session.recordingCount > 0) ...[
            const SizedBox(height: PracticeSessionsTokens.cardTextGap),
            PracticeSessionIndicators(session: session),
          ],
        ],
      ),
    );
    return Semantics(
      button: true,
      child: Material(
        color: PracticeSessionsTokens.cardFill,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: TempoColors.line),
          borderRadius: BorderRadius.circular(TempoRadius.action),
        ),
        child: InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(1),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth <
                        PracticeSessionsTokens.compactCardWidth ||
                    MediaQuery.textScalerOf(context).scale(16) > 20) {
                  return body;
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: PracticeSessionsTokens.cardArtWidth,
                      height: PracticeSessionsTokens.cardArtHeight,
                      child: ClipRect(
                        child: ColoredBox(
                          color: PracticeSessionsTokens.cardArtFill,
                          child: FittedBox(
                            fit: BoxFit.fill,
                            child: MeloopArt.instrument(
                              instrument,
                              size: PracticeSessionsTokens.cardArtHeight,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(child: body),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class PracticeSessionIndicators extends StatelessWidget {
  const PracticeSessionIndicators({super.key, required this.session});
  final PracticeSession session;

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    return Wrap(
      spacing: PracticeSessionsTokens.cardTextGap,
      runSpacing: TempoSpace.xs,
      children: [
        if (session.mood != null)
          _Indicator(
            icon: MeloopIcons.star,
            label: strings.practiceRatingShort(session.mood!),
            description: strings.practiceMoodScore(session.mood!),
          ),
        if (session.focus != null)
          _Indicator(
            icon: MeloopIcons.target,
            label: strings.practiceRatingShort(session.focus!),
            description: strings.practiceFocusScore(session.focus!),
          ),
        if (session.recordingCount > 0)
          _Indicator(
            icon: MeloopIcons.mic,
            label: strings.practiceRecordingCount(session.recordingCount),
            description: strings.practiceRecordingCount(session.recordingCount),
          ),
      ],
    );
  }
}

class _Indicator extends StatelessWidget {
  const _Indicator({
    required this.icon,
    required this.label,
    required this.description,
  });
  final MeloopIcons icon;
  final String label, description;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: description,
    child: Semantics(
      label: description,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MeloopIcon(
            icon,
            size: PracticeSessionsTokens.indicatorIconSize,
            color: TempoColors.muted,
          ),
          const SizedBox(width: TempoSpace.xs),
          Flexible(child: Text(label, style: PracticeSessionsTokens.indicator)),
        ],
      ),
    ),
  );
}
