import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../layout/meloop_icon.dart';
import '../../theme/tokens/tempo_tokens.dart';

class MeloopSearch extends StatelessWidget {
  const MeloopSearch({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hint,
    this.compact = false,
  });
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? hint;
  final bool compact;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, child) => TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      onChanged: onChanged,
      style: compact
          ? TempoType.body.copyWith(height: 1.25, letterSpacing: 0)
          : null,
      decoration: InputDecoration(
        isDense: compact,
        constraints: compact
            ? const BoxConstraints(minHeight: TempoSize.fieldMinHeight)
            : null,
        hintStyle: compact
            ? TempoType.body.copyWith(
                height: 1.25,
                letterSpacing: 0,
                color: TempoColors.muted,
              )
            : null,
        hintText: hint ?? context.l10n.searchHint,
        prefixIcon: Padding(
          padding: EdgeInsets.all(12),
          child: MeloopIcon(
            MeloopIcons.search,
            size: compact ? TempoSpace.page : null,
          ),
        ),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: context.l10n.clearSearch,
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
                icon: const MeloopIcon(MeloopIcons.close),
              ),
      ),
    ),
  );
}
