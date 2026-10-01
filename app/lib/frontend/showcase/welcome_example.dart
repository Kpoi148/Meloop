import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../application/app_settings_controller.dart';
import '../components/meloop_ui.dart';
import 'language_selector.dart';

class WelcomeExample extends ConsumerWidget {
  const WelcomeExample({super.key, this.onCreateProfile});
  final VoidCallback? onCreateProfile;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = context.l10n;
    final languageCode =
        ref.watch(appLocaleProvider).value?.languageCode ?? 'vi';
    return MeloopPage(
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MeloopTopBar(
            centerWordmark: true,
            trailing: TextButton.icon(
              onPressed: () => showLanguageSelector(context, ref),
              icon: const MeloopIcon(MeloopIcons.globe, size: 18),
              iconAlignment: IconAlignment.end,
              label: Text(
                languageCode == 'en'
                    ? strings.languageEnCode
                    : strings.languageViCode,
                style: TempoType.caption,
              ),
            ),
          ),
          const SizedBox(height: 36),
          Text(strings.welcomeTitle, style: TempoType.welcome),
          const SizedBox(height: 17),
          Text(
            strings.welcomeSubtitle,
            style: TempoType.body.copyWith(fontSize: 18, height: 1.38),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final height = constraints.maxWidth >= 400 ? 510.0 : 447.0;
              final art = MeloopIllustration(
                asset: 'fidelity-welcome.png',
                height: height,
              );
              if (MediaQuery.textScalerOf(context).scale(16) > 20) return art;
              return SizedBox(
                height: height - 36,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(top: -36, left: 0, right: 0, child: art),
                  ],
                ),
              );
            },
          ),
          MeloopNotice(message: strings.welcomePrivacy),
          const SizedBox(height: 10),
          MeloopButton(
            label: strings.createFirstProfile,
            onPressed: onCreateProfile,
          ),
        ],
      ),
    );
  }
}
