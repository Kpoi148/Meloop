import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../application/startup_controller.dart';
import '../components/meloop_ui.dart';
import 'preview_copy.dart';

/// Synthetic content matching the Tempo screenshot; never persisted.
class HomeExample extends StatelessWidget {
  const HomeExample({
    super.key,
    required this.onCreate,
    required this.onHistory,
    required this.onCatalog,
    this.profile,
    this.draft,
    this.onInstrument,
    this.showSampleData = true,
  });
  final VoidCallback onCreate, onHistory;
  final VoidCallback? onCatalog;
  final PreviewInstrumentProfile? profile;
  final PreviewPracticeDraft? draft;
  final VoidCallback? onInstrument;
  final bool showSampleData;
  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HomeHeader(profile: profile, onInstrument: onInstrument),
        _StatisticsCard(showSampleData: showSampleData),
        const SizedBox(height: TempoSpace.lg),
        Row(
          children: [
            MeloopIcon(MeloopIcons.target, size: 57),
            SizedBox(width: TempoSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 8,
                    children: [
                      Text(strings.weeklyGoal, style: TempoType.label),
                      Text(
                        strings.goalProgress(showSampleData ? 3 : 0, 5),
                        style: TempoType.caption,
                      ),
                    ],
                  ),
                  const SizedBox(height: TempoSpace.sm),
                  LinearProgressIndicator(
                    value: showSampleData ? .6 : 0,
                    minHeight: 10,
                    color: TempoColors.yellow,
                    backgroundColor: TempoColors.line,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  const SizedBox(height: TempoSpace.xs),
                  Text(strings.mondayToSunday, style: TempoType.caption),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: TempoSpace.md),
        MeloopButton(
          label: draft == null
              ? strings.createPractice
              : strings.continuePractice,
          prominent: true,
          style: MeloopButtonStyle.yellow,
          icon: MeloopIcons.plus,
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              child: Row(
                children: [
                  const MeloopArt.tool(MeloopTool.metro, size: 43),
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
        LayoutBuilder(
          builder: (context, constraints) {
            final title = Text(strings.recentSession, style: TempoType.section);
            final action = TextButton(
              onPressed: onHistory,
              child: Text(strings.viewAll, style: TempoType.caption),
            );
            if (MediaQuery.textScalerOf(context).scale(16) > 20) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [title, action],
              );
            }
            return Row(
              children: [
                Expanded(child: title),
                Flexible(child: action),
              ],
            );
          },
        ),
        const SizedBox(height: TempoSpace.sm),
        if (showSampleData)
          const _RecentCard()
        else
          MeloopStateView(
            state: MeloopViewState.empty,
            title: strings.noPracticeSessions,
            message: strings.profileSessionsEmptyMessage,
          ),
      ],
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({this.profile, this.onInstrument});
  final PreviewInstrumentProfile? profile;
  final VoidCallback? onInstrument;
  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final selected =
        profile ??
        const PreviewInstrumentProfile(
          id: 'guitar-preview',
          instrument: MeloopInstrument.guitar,
        );
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(strings.overview, style: TempoType.heading),
        Text(profileDisplayName(strings, selected)),
      ],
    );
    final top = MeloopTopBar(
      trailing: _InstrumentChip(profile: selected, onPressed: onInstrument),
    );
    if (MediaQuery.textScalerOf(context).scale(16) > 20) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          top,
          const SizedBox(height: TempoSpace.page),
          copy,
          const SizedBox(height: TempoSpace.page),
        ],
      );
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          right: -51,
          top: -32,
          child: Transform.rotate(
            angle: .105,
            child: selected.instrument == MeloopInstrument.guitar
                ? const MeloopArt.scene(MeloopScene.guitar, size: 285)
                : MeloopArt.instrument(selected.instrument, size: 285),
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            top,
            const SizedBox(height: 19),
            copy,
            const SizedBox(height: 16),
          ],
        ),
      ],
    );
  }
}

class _InstrumentChip extends StatelessWidget {
  const _InstrumentChip({required this.profile, this.onPressed});
  final PreviewInstrumentProfile profile;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => Semantics(
    label: context.l10n.changeInstrument,
    button: true,
    child: InkWell(
      key: const Key('choose-profile'),
      onTap: onPressed,
      borderRadius: BorderRadius.circular(TempoRadius.pill),
      child: Container(
        padding: const EdgeInsets.fromLTRB(3, 3, 11, 3),
        decoration: BoxDecoration(
          color: TempoColors.paper.withValues(alpha: .9),
          border: Border.all(color: TempoColors.line),
          borderRadius: BorderRadius.circular(TempoRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MeloopArt.instrument(profile.instrument, size: 39),
            const SizedBox(width: 7),
            Flexible(
              child: Text(profileInstrumentLabel(context.l10n, profile)),
            ),
            const SizedBox(width: 7),
            const MeloopIcon(MeloopIcons.down, size: 18),
          ],
        ),
      ),
    ),
  );
}

class _StatisticsCard extends StatelessWidget {
  const _StatisticsCard({required this.showSampleData});
  final bool showSampleData;
  List<int> get values => showSampleData
      ? const [20, 0, 25, 0, 30, 25, 35]
      : List<int>.filled(7, 0);
  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final weekdays = MaterialLocalizations.of(context).narrowWeekdays;
    return MeloopCard(
      color: TempoColors.teal,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 10),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: TempoColors.white),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 8,
              children: [
                Text(strings.lastSevenDays, style: TempoType.compactTitle),
                Text(strings.details, style: TempoType.caption),
              ],
            ),
            const SizedBox(height: 9),
            MeloopResponsiveRow(
              children: [
                _Metric(showSampleData ? '135' : '0', strings.practiceMinutes),
                _Metric(showSampleData ? '5' : '0', strings.practiceSessions),
                _Metric(showSampleData ? '3' : '0', strings.consecutiveDays),
              ],
            ),
            const SizedBox(height: TempoSpace.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        children: [
                          Text('${values[i]}', style: TempoType.caption),
                          Container(
                            height: values[i] == 0 ? 2 : values[i] * .9,
                            decoration: BoxDecoration(
                              color: i == 6
                                  ? TempoColors.yellow
                                  : TempoColors.chart,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            [
                              weekdays[4],
                              weekdays[5],
                              weekdays[6],
                              weekdays[0],
                              weekdays[1],
                              weekdays[2],
                              weekdays[3],
                            ][i],
                            style: TempoType.caption,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.value, this.label);
  final String value, label;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: TempoType.metric),
      Text(
        label,
        style: TempoType.caption.copyWith(height: 1.1),
        textAlign: TextAlign.center,
      ),
    ],
  );
}

class _RecentCard extends StatelessWidget {
  const _RecentCard();
  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final body = Padding(
      padding: const EdgeInsets.fromLTRB(0, 9, 9, 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(strings.sampleSessionTitle, style: TempoType.title),
          const SizedBox(height: 3),
          Text(strings.sampleSessionMeta, style: TempoType.compactBody),
          Text(strings.sampleSessionNotes, style: TempoType.compactBody),
          const Divider(height: 16),
          Text(strings.nextPracticeUpper, style: TempoType.caption),
          Text(strings.sampleNextNotes, style: TempoType.compactBody),
        ],
      ),
    );
    return MeloopCard(
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 300 ||
              MediaQuery.textScalerOf(context).scale(16) > 20) {
            return Padding(
              padding: const EdgeInsets.all(TempoSpace.md),
              child: body,
            );
          }
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 106,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(TempoRadius.recent),
                    ),
                    child: OverflowBox(
                      maxWidth: 220,
                      maxHeight: 220,
                      alignment: const Alignment(.5, -.4),
                      child: const MeloopArt.scene(
                        MeloopScene.guitar,
                        size: 220,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: TempoSpace.md),
                Expanded(child: body),
              ],
            ),
          );
        },
      ),
    );
  }
}
