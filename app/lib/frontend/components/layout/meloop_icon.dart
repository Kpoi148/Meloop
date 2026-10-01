import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/tokens/tempo_tokens.dart';

enum MeloopIcons {
  home,
  book,
  chart,
  settings,
  arrow,
  back,
  down,
  plus,
  minus,
  check,
  target,
  play,
  pause,
  stop,
  clock,
  shield,
  lock,
  search,
  filter,
  edit,
  trash,
  music,
  mic,
  download,
  upload,
  star,
  bell,
  globe,
  mail,
  close,
  more,
  refresh,
  folder,
  volume,
  help,
}

/// Uses the exact 24 × 24 stroke paths from the Tempo HTML prototype.
class MeloopIcon extends StatelessWidget {
  const MeloopIcon(this.icon, {super.key, this.size, this.color});
  final MeloopIcons icon;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    'assets/icons/${icon.name}.svg',
    width: size ?? TempoSize.icon,
    height: size ?? TempoSize.icon,
    excludeFromSemantics: true,
    colorFilter: ColorFilter.mode(
      color ?? IconTheme.of(context).color ?? TempoColors.ink,
      BlendMode.srcIn,
    ),
  );
}
