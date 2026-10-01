import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../layout/meloop_icon.dart';

class MeloopSearch extends StatelessWidget {
  const MeloopSearch({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hint,
  });
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? hint;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, child) => TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint ?? context.l10n.searchHint,
        prefixIcon: const Padding(
          padding: EdgeInsets.all(12),
          child: MeloopIcon(MeloopIcons.search),
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
