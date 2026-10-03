import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../components/meloop_ui.dart';
import 'contact_tokens.dart';

class ContactTopBar extends StatelessWidget {
  const ContactTopBar({super.key, required this.title, this.onHome});
  final String title;
  final VoidCallback? onHome;

  @override
  Widget build(BuildContext context) => MeloopTopBar(
    title: title,
    onBack: () => Navigator.of(context).pop(),
    trailing: onHome == null
        ? null
        : IconButton(
            tooltip: context.l10n.navHome,
            icon: const MeloopIcon(MeloopIcons.home),
            onPressed: onHome,
          ),
  );
}

class SupportIntro extends StatelessWidget {
  const SupportIntro({super.key});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final strings = context.l10n;
      final largeText = MediaQuery.textScalerOf(context).scale(16) > 20;
      final copy = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.supportHeading,
            style: TempoType.heading.copyWith(
              fontSize: ContactTokens.supportHeadingSize,
            ),
          ),
          const SizedBox(height: TempoSpace.md),
          Text(
            strings.supportSubtitle,
            style: TempoType.body.copyWith(color: TempoColors.muted),
          ),
        ],
      );
      if (largeText) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            copy,
            const Center(
              child: MeloopArt.scene(
                MeloopScene.envelope,
                size: ContactTokens.supportArtSize,
              ),
            ),
          ],
        );
      }
      return ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: ContactTokens.supportIntroHeight,
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            const Positioned(
              right: ContactTokens.supportArtRight,
              top: ContactTokens.supportArtTop,
              child: MeloopArt.scene(
                MeloopScene.envelope,
                size: ContactTokens.supportArtSize,
              ),
            ),
            SizedBox(
              width:
                  constraints.maxWidth * ContactTokens.supportHeadingFraction,
              child: copy,
            ),
          ],
        ),
      );
    },
  );
}

class ContactCopyButton extends StatelessWidget {
  const ContactCopyButton({super.key, required this.label, required this.copy});
  final String label;
  final Future<void> Function() copy;

  @override
  Widget build(BuildContext context) => MeloopButton(
    label: label,
    style: MeloopButtonStyle.outline,
    onPressed: () async {
      await copy();
      if (context.mounted) {
        MeloopNotifications.show(context, context.l10n.supportCopied);
      }
    },
    onError: (_, _) {
      if (context.mounted) {
        MeloopNotifications.show(
          context,
          context.l10n.supportCopyFailed,
          kind: MeloopNoticeKind.error,
        );
      }
    },
  );
}
