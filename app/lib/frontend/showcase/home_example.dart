import 'package:flutter/material.dart';

import '../components/meloop_ui.dart';

/// Synthetic content matching the Tempo screenshot; never persisted.
class HomeExample extends StatelessWidget {
  const HomeExample({
    super.key,
    required this.onCreate,
    required this.onHistory,
    required this.onCatalog,
  });
  final VoidCallback onCreate, onHistory, onCatalog;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const _HomeHeader(),
      const _StatisticsCard(),
      const SizedBox(height: TempoSpace.lg),
      const Row(
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
                    Text('Mục tiêu tuần', style: TempoType.label),
                    Text('3/5 ngày', style: TempoType.caption),
                  ],
                ),
                SizedBox(height: TempoSpace.sm),
                LinearProgressIndicator(
                  value: .6,
                  minHeight: 10,
                  color: TempoColors.yellow,
                  backgroundColor: TempoColors.line,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                SizedBox(height: TempoSpace.xs),
                Text('Thứ Hai – Chủ nhật', style: TempoType.caption),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: TempoSpace.md),
      MeloopButton(
        label: 'Tạo buổi luyện',
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
                const Expanded(
                  child: Text(
                    'Công cụ luyện tập',
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
          final title = const Text('Buổi gần nhất', style: TempoType.section);
          final action = TextButton(
            onPressed: onHistory,
            child: const Text('Xem tất cả ›', style: TempoType.caption),
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
      const _RecentCard(),
    ],
  );
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();
  @override
  Widget build(BuildContext context) {
    const copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tổng quan', style: TempoType.heading),
        Text('Guitar của tôi'),
      ],
    );
    const top = MeloopTopBar(trailing: _InstrumentChip());
    if (MediaQuery.textScalerOf(context).scale(16) > 20) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          top,
          SizedBox(height: TempoSpace.page),
          copy,
          SizedBox(height: TempoSpace.page),
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
            child: const MeloopArt.scene(MeloopScene.guitar, size: 285),
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
        const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [top, SizedBox(height: 19), copy, SizedBox(height: 16)],
        ),
      ],
    );
  }
}

class _InstrumentChip extends StatelessWidget {
  const _InstrumentChip();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(3, 3, 11, 3),
    decoration: BoxDecoration(
      color: TempoColors.paper.withValues(alpha: .9),
      border: Border.all(color: TempoColors.line),
      borderRadius: BorderRadius.circular(TempoRadius.pill),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MeloopArt.instrument(MeloopInstrument.guitar, size: 39),
        SizedBox(width: 7),
        Flexible(child: Text('Guitar')),
        SizedBox(width: 7),
        MeloopIcon(MeloopIcons.down, size: 18),
      ],
    ),
  );
}

class _StatisticsCard extends StatelessWidget {
  const _StatisticsCard();
  static const values = [20, 0, 25, 0, 30, 25, 35];
  @override
  Widget build(BuildContext context) => MeloopCard(
    color: TempoColors.teal,
    padding: const EdgeInsets.fromLTRB(14, 13, 14, 10),
    child: DefaultTextStyle.merge(
      style: const TextStyle(color: TempoColors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 8,
            children: [
              Text('7 ngày gần nhất', style: TempoType.compactTitle),
              Text('Chi tiết ›', style: TempoType.caption),
            ],
          ),
          const SizedBox(height: 9),
          const MeloopResponsiveRow(
            children: [
              _Metric('135', 'phút luyện'),
              _Metric('5', 'buổi luyện'),
              _Metric('3', 'ngày liên tiếp'),
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
                          ['T5', 'T6', 'T7', 'CN', 'T2', 'T3', 'T4'][i],
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
    const body = Padding(
      padding: EdgeInsets.fromLTRB(0, 9, 9, 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Luyện gam C', style: TempoType.title),
          SizedBox(height: 3),
          Text('Hôm nay · 35 phút · 80 BPM', style: TempoType.compactBody),
          Text(
            'Gam C trưởng, chuyển hợp âm C – G – Am – F.',
            style: TempoType.compactBody,
          ),
          Divider(height: 16),
          Text('CHO LẦN LUYỆN TIẾP', style: TempoType.caption),
          Text(
            'Giữ nhịp ở 80 BPM, thả lỏng bàn tay.',
            style: TempoType.compactBody,
          ),
        ],
      ),
    );
    return MeloopCard(
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 300 ||
              MediaQuery.textScalerOf(context).scale(16) > 20) {
            return const Padding(
              padding: EdgeInsets.all(TempoSpace.md),
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
                const Expanded(child: body),
              ],
            ),
          );
        },
      ),
    );
  }
}
