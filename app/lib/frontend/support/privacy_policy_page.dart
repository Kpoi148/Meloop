import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../application/contact_support_controller.dart';
import '../components/meloop_ui.dart';
import '../showcase/language_selector.dart';
import 'contact_tokens.dart';
import 'contact_widgets.dart';

class PrivacyPolicyPage extends ConsumerStatefulWidget {
  const PrivacyPolicyPage({super.key, this.onHome});
  final VoidCallback? onHome;

  @override
  ConsumerState<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends ConsumerState<PrivacyPolicyPage> {
  bool _opening = false;
  bool _failed = false;

  Future<void> _open(Uri uri) async {
    if (_opening) return;
    setState(() {
      _opening = true;
      _failed = false;
    });
    var opened = false;
    try {
      opened = await ref.read(contactPlatformProvider).openPrivacyPolicy(uri);
    } catch (_) {
      // External app errors never replace the readable information on this page.
    }
    if (!mounted) return;
    setState(() {
      _opening = false;
      _failed = !opened;
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final uri = ref
        .watch(contactConfigurationProvider)
        .privacyUri(Localizations.localeOf(context).languageCode);
    return MeloopPage(
      topBar: ContactTopBar(title: strings.privacyTitle, onHome: widget.onHome),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(strings.privacyHeading, style: TempoType.heading),
          const SizedBox(height: TempoSpace.md),
          Text(
            strings.privacySubtitle,
            style: TempoType.body.copyWith(color: TempoColors.muted),
          ),
          const SizedBox(height: TempoSpace.md),
          SizedBox(
            height: ContactTokens.privacyArtHeight,
            child: ClipRect(
              child: OverflowBox(
                minWidth: ContactTokens.privacyArtSize,
                maxWidth: ContactTokens.privacyArtSize,
                minHeight: ContactTokens.privacyArtSize,
                maxHeight: ContactTokens.privacyArtSize,
                alignment: Alignment.center,
                child: const MeloopArt.scene(
                  MeloopScene.privacy,
                  size: ContactTokens.privacyArtSize,
                ),
              ),
            ),
          ),
          _PrivacySection(
            title: strings.privacyLocalTitle,
            body: strings.privacyLocalBody,
            initiallyExpanded: true,
          ),
          _PrivacySection(
            title: strings.privacyPermissionsTitle,
            body: strings.privacyPermissionsBody,
          ),
          _PrivacySection(
            title: strings.privacyPurchasesTitle,
            body: strings.privacyPurchasesBody,
          ),
          _PrivacySection(
            title: strings.privacyDiagnosticsTitle,
            body: strings.privacyDiagnosticsBody,
          ),
          _PrivacySection(
            title: strings.privacyChoicesTitle,
            body: strings.privacyChoicesBody,
          ),
          const SizedBox(height: TempoSpace.xl),
          Text(
            strings.privacySummaryFootnote,
            style: TempoType.caption.copyWith(color: TempoColors.muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: TempoSpace.xl),
          TextButton.icon(
            onPressed: _opening
                ? null
                : () => showLanguageSelector(context, ref),
            icon: const MeloopIcon(MeloopIcons.globe),
            label: Text(strings.language),
          ),
          if (uri == null)
            MeloopNotice(message: strings.privacyNotPublished)
          else ...[
            SelectableText(uri.toString(), style: TempoType.caption),
            const SizedBox(height: TempoSpace.md),
            MeloopButton(
              label: strings.privacyOpenPublished,
              icon: MeloopIcons.globe,
              isLoading: _opening,
              onPressed: () => _open(uri),
            ),
            if (_failed) ...[
              const SizedBox(height: TempoSpace.md),
              MeloopNotice(
                message: strings.privacyOpenFailed,
                kind: MeloopNoticeKind.error,
              ),
            ],
            const SizedBox(height: TempoSpace.md),
            ContactCopyButton(
              label: strings.privacyCopyLink,
              copy: () =>
                  ref.read(contactPlatformProvider).copyText(uri.toString()),
            ),
          ],
        ],
      ),
    );
  }
}

class _PrivacySection extends StatefulWidget {
  const _PrivacySection({
    required this.title,
    required this.body,
    this.initiallyExpanded = false,
  });
  final String title, body;
  final bool initiallyExpanded;

  @override
  State<_PrivacySection> createState() => _PrivacySectionState();
}

class _PrivacySectionState extends State<_PrivacySection> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: TempoColors.line)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          expanded: _expanded,
          button: true,
          child: InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: ContactTokens.expansionPadding,
              ),
              child: Row(
                children: [
                  SizedBox.square(
                    dimension: TempoSize.smallIcon,
                    child: CustomPaint(painter: _DisclosurePainter(_expanded)),
                  ),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: ContactTokens.sectionTitle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.only(
              bottom: ContactTokens.expansionPadding,
            ),
            child: Text(widget.body, style: ContactTokens.sectionBody),
          ),
      ],
    ),
  );
}

class _DisclosurePainter extends CustomPainter {
  const _DisclosurePainter(this.expanded);
  final bool expanded;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    if (expanded) {
      path.moveTo(0, size.height / 3);
      path.lineTo(size.width * 2 / 3, size.height / 3);
      path.lineTo(size.width / 3, size.height * 2 / 3);
    } else {
      path.moveTo(size.width / 6, size.height / 6);
      path.lineTo(size.width / 6, size.height * 5 / 6);
      path.lineTo(size.width / 2, size.height / 2);
    }
    canvas.drawPath(path..close(), Paint()..color = TempoColors.ink);
  }

  @override
  bool shouldRepaint(_DisclosurePainter oldDelegate) =>
      oldDelegate.expanded != expanded;
}
