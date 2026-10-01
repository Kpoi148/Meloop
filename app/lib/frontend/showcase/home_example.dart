import 'package:flutter/material.dart';

import '../application/instrument_profile_service.dart';
import '../components/meloop_ui.dart';

/// Tempo Home, with synthetic journal content only in the component showcase.
class HomeExample extends StatelessWidget {
  const HomeExample({
    super.key,
    required this.onCreate,
    required this.onHistory,
    required this.onCatalog,
    this.profile,
    this.onChooseProfile,
  });
  final VoidCallback onCreate, onHistory, onCatalog;
  final InstrumentProfile? profile;
  final VoidCallback? onChooseProfile;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _HomeHeader(profile: profile, onChooseProfile: onChooseProfile),
      _StatisticsCard(showSampleData: profile == null),
      const SizedBox(height: TempoSpace.lg),
      Row(
        children: [
          const MeloopIcon(MeloopIcons.target, size: 57),
          const SizedBox(width: TempoSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 8,
                  children: [
                    const Text('Mục tiêu tuần', style: TempoType.label),
                    Text(
                      profile == null ? '3/5 ngày' : '0/5 ngày',
                      style: TempoType.caption,
                    ),
                  ],
                ),
                const SizedBox(height: TempoSpace.sm),
                LinearProgressIndicator(
                  value: profile == null ? .6 : 0,
                  minHeight: 10,
                  color: TempoColors.yellow,
                  backgroundColor: TempoColors.line,
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                ),
                const SizedBox(height: TempoSpace.xs),
                const Text('Thứ Hai – Chủ nhật', style: TempoType.caption),
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
      if (profile == null)
        const _RecentCard()
      else
        const MeloopStateView(
          state: MeloopViewState.empty,
          title: 'Chưa có buổi luyện.',
          message: 'Buổi luyện của hồ sơ này sẽ hiển thị ở đây.',
        ),
    ],
  );
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({this.profile, this.onChooseProfile});
  final InstrumentProfile? profile;
  final VoidCallback? onChooseProfile;
  @override
  Widget build(BuildContext context) {
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tổng quan', style: TempoType.heading),
        Text(profile?.name ?? 'Guitar của tôi'),
      ],
    );
    final top = MeloopTopBar(
      trailing: _InstrumentChip(profile: profile, onTap: onChooseProfile),
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
            child:
                profile == null ||
                    profile!.instrumentType == InstrumentType.guitar
                ? const MeloopArt.scene(MeloopScene.guitar, size: 285)
                : MeloopArt.instrument(
                    MeloopInstrument.values[profile!.instrumentType.index],
                    size: 285,
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
  const _InstrumentChip({this.profile, this.onTap});
  final InstrumentProfile? profile;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Đổi hồ sơ nhạc cụ',
    child: Material(
      color: TempoColors.paper.withValues(alpha: .9),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: TempoColors.line),
        borderRadius: BorderRadius.circular(TempoRadius.pill),
      ),
      child: InkWell(
        key: const Key('choose-profile'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(TempoRadius.pill),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(3, 3, 11, 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MeloopArt.instrument(
                MeloopInstrument.values[profile?.instrumentType.index ?? 0],
                size: 39,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  profile?.instrumentLabel ?? 'Guitar',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 7),
              const MeloopIcon(MeloopIcons.down, size: 18),
            ],
          ),
        ),
      ),
    ),
  );
}

class _StatisticsCard extends StatelessWidget {
  const _StatisticsCard({required this.showSampleData});
  final bool showSampleData;
  List<int> get values =>
      showSampleData ? [20, 0, 25, 0, 30, 25, 35] : List.filled(7, 0);
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
          MeloopResponsiveRow(
            children: [
              _Metric(showSampleData ? '135' : '0', 'phút luyện'),
              _Metric(showSampleData ? '5' : '0', 'buổi luyện'),
              _Metric(showSampleData ? '3' : '0', 'ngày liên tiếp'),
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
