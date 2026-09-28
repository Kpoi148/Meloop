import 'package:flutter/material.dart';

import '../../theme/tokens/tempo_tokens.dart';
import '../layout/meloop_icon.dart';

class MeloopWordmark extends StatelessWidget {
  const MeloopWordmark({super.key});
  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: [
        const TextSpan(text: 'meloop'),
        TextSpan(
          text: '.',
          style: TempoType.wordmark.copyWith(color: TempoColors.yellow),
        ),
      ],
    ),
    style: TempoType.wordmark,
    semanticsLabel: 'Meloop',
    textScaler: TextScaler.noScaling,
  );
}

class MeloopTopBar extends StatelessWidget {
  const MeloopTopBar({
    super.key,
    this.title,
    this.onBack,
    this.trailing,
    this.centerWordmark = false,
  });
  final String? title;
  final VoidCallback? onBack;
  final Widget? trailing;
  final bool centerWordmark;
  @override
  Widget build(BuildContext context) {
    if (title == null && MediaQuery.textScalerOf(context).scale(16) > 24) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: TempoSpace.sm,
        children: [const MeloopWordmark(), ?trailing],
      );
    }
    return Row(
      children: [
        if (centerWordmark) const SizedBox(width: TempoSize.touchTarget),
        if (onBack != null)
          IconButton(
            tooltip: 'Quay lại',
            onPressed: onBack,
            icon: const MeloopIcon(MeloopIcons.back),
          ),
        Expanded(
          child: title == null
              ? Align(
                  alignment: centerWordmark
                      ? Alignment.center
                      : Alignment.centerLeft,
                  child: const MeloopWordmark(),
                )
              : Text(
                  title!,
                  style: TempoType.label,
                  textAlign: onBack == null
                      ? TextAlign.start
                      : TextAlign.center,
                ),
        ),
        if (trailing != null)
          trailing!
        else if (onBack != null)
          const SizedBox(width: TempoSize.touchTarget),
      ],
    );
  }
}

class MeloopNavItem {
  const MeloopNavItem(this.label, this.icon);
  final String label;
  final MeloopIcons icon;
}

class MeloopBottomNavigation extends StatelessWidget {
  const MeloopBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    this.items = defaults,
  });
  static const defaults = [
    MeloopNavItem('Trang chủ', MeloopIcons.home),
    MeloopNavItem('Buổi luyện', MeloopIcons.book),
    MeloopNavItem('Tiến độ', MeloopIcons.chart),
    MeloopNavItem('Cài đặt', MeloopIcons.settings),
  ];
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<MeloopNavItem> items;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: TempoColors.paper,
      border: Border(top: BorderSide(color: TempoColors.line)),
    ),
    child: SafeArea(
      top: false,
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: TempoSize.contentMaxWidth,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: Semantics(
                      selected: selectedIndex == i,
                      button: true,
                      child: InkWell(
                        onTap: () => onSelected(i),
                        borderRadius: BorderRadius.circular(TempoRadius.field),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 2,
                            vertical: 4,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 38,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: selectedIndex == i
                                      ? TempoColors.yellow
                                      : null,
                                  borderRadius: BorderRadius.circular(
                                    TempoRadius.pill,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: MeloopIcon(
                                  items[i].icon,
                                  size: TempoSize.navigationIcon,
                                ),
                              ),
                              const SizedBox(height: TempoSpace.xs),
                              Text(
                                items[i].label,
                                textAlign: TextAlign.center,
                                style: TempoType.caption.copyWith(
                                  fontWeight: selectedIndex == i
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: TempoSpace.sm),
                              Container(
                                width: 35,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: selectedIndex == i
                                      ? TempoColors.yellow
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
