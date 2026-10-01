import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../application/app_settings_controller.dart';
import '../components/meloop_ui.dart';

Future<void> showLanguageSelector(BuildContext context, WidgetRef ref) async {
  final strings = context.l10n;
  final selected = ref.read(appLocaleProvider).value?.languageCode ?? 'vi';
  await showMeloopSheet<void>(
    context,
    title: strings.chooseLanguage,
    child: Column(
      children: [
        _LanguageChoice(
          label: strings.languageVietnamese,
          code: 'vi',
          selectedCode: selected,
          onSelected: (code) => _select(context, ref, code),
        ),
        const Divider(),
        _LanguageChoice(
          label: strings.languageEnglish,
          code: 'en',
          selectedCode: selected,
          onSelected: (code) => _select(context, ref, code),
        ),
      ],
    ),
  );
}

Future<void> _select(
  BuildContext context,
  WidgetRef ref,
  String languageCode,
) async {
  try {
    await ref.read(appLocaleProvider.notifier).select(Locale(languageCode));
    if (context.mounted) Navigator.of(context).pop();
  } catch (_) {
    if (context.mounted) {
      MeloopNotifications.show(
        context,
        context.l10n.languageSaveFailed,
        kind: MeloopNoticeKind.error,
      );
    }
  }
}

class _LanguageChoice extends StatelessWidget {
  const _LanguageChoice({
    required this.label,
    required this.code,
    required this.selectedCode,
    required this.onSelected,
  });

  final String label;
  final String code;
  final String selectedCode;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: code == selectedCode,
    button: true,
    child: ListTile(
      onTap: () => onSelected(code),
      title: Text(label),
      leading: const MeloopIcon(MeloopIcons.globe),
      trailing: code == selectedCode
          ? const MeloopIcon(MeloopIcons.check)
          : const SizedBox(width: TempoSize.icon),
      contentPadding: EdgeInsets.zero,
    ),
  );
}
