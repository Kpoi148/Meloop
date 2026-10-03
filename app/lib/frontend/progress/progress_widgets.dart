import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../l10n/l10n.dart';
import '../application/startup_controller.dart';
import '../components/meloop_ui.dart';
import '../showcase/preview_copy.dart';
import 'progress_data.dart';
import 'progress_tokens.dart';

class ProgressInstrumentChip extends StatelessWidget {
  const ProgressInstrumentChip({
    super.key,
    required this.profile,
    required this.onPressed,
  });
  final PreviewInstrumentProfile profile;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) {
    final largeText =
        MediaQuery.textScalerOf(context).scale(16) / 16 >
        ProgressTokens.largeTextThreshold;
    return Semantics(
      button: true,
      label: context.l10n.changeInstrument,
      child: InkWell(
        key: const Key('choose-profile'),
        onTap: onPressed,
        borderRadius: BorderRadius.circular(TempoRadius.pill),
        child: Container(
          constraints: BoxConstraints(
            maxWidth:
                (MediaQuery.sizeOf(context).width - TempoSpace.page * 2).clamp(
                  0,
                  TempoSize.contentMaxWidth,
                ) *
                (largeText ? 1 : ProgressTokens.chipWidthFraction),
          ),
          padding: ProgressTokens.chipPadding,
          decoration: BoxDecoration(
            color: TempoColors.white.withValues(alpha: .6),
            border: Border.all(color: ProgressTokens.chipBorder),
            borderRadius: BorderRadius.circular(TempoRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: ProgressTokens.chipGap,
            children: [
              MeloopArt.instrument(
                profile.instrument,
                size: ProgressTokens.chipArtSize,
                filterQuality: FilterQuality.high,
              ),
              Flexible(
                child: Text(
                  profileInstrumentLabel(context.l10n, profile),
                  style: TempoType.body.copyWith(
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ),
              const MeloopIcon(MeloopIcons.down, size: TempoSize.smallIcon),
            ],
          ),
        ),
      ),
    );
  }
}

class ProgressRoundIcon extends StatelessWidget {
  const ProgressRoundIcon({
    super.key,
    required this.icon,
    this.sage = false,
    this.small = false,
    this.mood = false,
  });
  final MeloopIcons icon;
  final bool sage, small, mood;
  @override
  Widget build(BuildContext context) {
    final glyph = small
        ? ProgressTokens.ratingIconGlyph
        : ProgressTokens.roundIconGlyph;
    return Container(
      width: small
          ? ProgressTokens.ratingIconSize
          : ProgressTokens.roundIconSize,
      height: small
          ? ProgressTokens.ratingIconSize
          : ProgressTokens.roundIconSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: sage
            ? ProgressTokens.sageIconFill
            : ProgressTokens.roundIconFill,
      ),
      child: mood
          ? SvgPicture.asset(
              'assets/icons/mood-5.svg',
              width: glyph,
              height: glyph,
              excludeFromSemantics: true,
              colorFilter: const ColorFilter.mode(
                TempoColors.ink,
                BlendMode.srcIn,
              ),
            )
          : MeloopIcon(icon, size: glyph),
    );
  }
}

class ProgressTogether extends StatelessWidget {
  const ProgressTogether({super.key, required this.data});
  final ProgressData data;
  @override
  Widget build(BuildContext context) {
    final largeText =
        MediaQuery.textScalerOf(context).scale(16) / 16 >
        ProgressTokens.largeTextThreshold;
    Widget item(
      MeloopIcons icon,
      String label,
      String value,
      Key key,
      bool sage,
    ) => Row(
      children: [
        ProgressRoundIcon(icon: icon, sage: sage),
        const SizedBox(width: ProgressTokens.detailGap),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: ProgressTokens.togetherLabel),
              Text(value, key: key, style: ProgressTokens.togetherValue),
            ],
          ),
        ),
      ],
    );
    final streak = item(
      MeloopIcons.music,
      context.l10n.progressStreak,
      context.l10n.progressDays(data.consecutiveDays),
      const Key('overview-streak'),
      false,
    );
    final goal = item(
      MeloopIcons.target,
      context.l10n.weeklyGoal,
      data.goal?.enabled == true
          ? context.l10n.goalProgress(data.goalDays, data.goal!.targetDays)
          : context.l10n.weeklyGoalOff,
      const Key('overview-weekly-goal'),
      true,
    );
    return Container(
      padding: ProgressTokens.togetherPadding,
      decoration: BoxDecoration(
        color: ProgressTokens.togetherFill,
        borderRadius: BorderRadius.circular(TempoRadius.action),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (largeText)
            Column(spacing: TempoSpace.md, children: [streak, goal])
          else
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: ProgressTokens.togetherDivider,
                          ),
                        ),
                      ),
                      child: streak,
                    ),
                  ),
                  const SizedBox(width: ProgressTokens.togetherGap),
                  Expanded(child: goal),
                ],
              ),
            ),
          const SizedBox(height: ProgressTokens.detailGap),
          Text(
            context.l10n.progressQualifyingDayHint,
            style: ProgressTokens.hint,
          ),
        ],
      ),
    );
  }
}

class ProgressLink extends StatelessWidget {
  const ProgressLink({
    super.key,
    required this.label,
    required this.icon,
    this.sage = false,
    this.onPressed,
  });
  final String label;
  final MeloopIcons icon;
  final bool sage;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(TempoRadius.recent),
      side: const BorderSide(color: TempoColors.line),
    ),
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(TempoRadius.recent),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: ProgressTokens.linkHeight),
        child: Padding(
          padding: ProgressTokens.linkPadding,
          child: Row(
            children: [
              ProgressRoundIcon(icon: icon, sage: sage),
              const SizedBox(width: TempoSpace.md),
              Expanded(child: Text(label, style: ProgressTokens.link)),
              const MeloopIcon(MeloopIcons.arrow),
            ],
          ),
        ),
      ),
    ),
  );
}
