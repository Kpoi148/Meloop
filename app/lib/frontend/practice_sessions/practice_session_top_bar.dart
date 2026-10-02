import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../components/meloop_ui.dart';
import 'practice_session_detail_tokens.dart';

class PracticeSessionTopBar extends StatelessWidget {
  const PracticeSessionTopBar({
    super.key,
    required this.title,
    required this.onBack,
    this.onHome,
  });
  final String title;
  final VoidCallback? onBack, onHome;
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(
      minHeight: PracticeSessionDetailTokens.topBarHeight,
    ),
    child: Row(
      children: [
        _icon(context.l10n.back, MeloopIcons.back, onBack),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TempoType.label.copyWith(fontSize: 17, letterSpacing: 0),
          ),
        ),
        _icon(context.l10n.navHome, MeloopIcons.home, onHome),
      ],
    ),
  );
  Widget _icon(String label, MeloopIcons icon, VoidCallback? action) =>
      IconButton(
        tooltip: label,
        onPressed: action,
        style: IconButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: const Size.square(37),
          padding: const EdgeInsets.all(6),
        ),
        icon: MeloopIcon(
          icon,
          size: PracticeSessionDetailTokens.topBarIconSize,
        ),
      );
}
