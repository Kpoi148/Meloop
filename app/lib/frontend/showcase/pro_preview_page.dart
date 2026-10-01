import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../components/meloop_ui.dart';

/// Tempo's Pro page. The injected callback enables only the local UI preview.
class ProPreviewPage extends StatefulWidget {
  const ProPreviewPage({
    super.key,
    required this.isPro,
    required this.onEnablePreview,
  });

  final bool isPro;
  final Future<void> Function() onEnablePreview;

  @override
  State<ProPreviewPage> createState() => _ProPreviewPageState();
}

class _ProPreviewPageState extends State<ProPreviewPage> {
  late bool _isPro = widget.isPro;
  bool _dialogOpen = false;

  Future<void> _enable() async {
    if (_dialogOpen) return;
    _dialogOpen = true;
    try {
      await _confirmEnable();
    } finally {
      _dialogOpen = false;
    }
  }

  Future<void> _confirmEnable() async {
    final strings = context.l10n;
    if (_isPro) {
      await _showProInfo(
        context,
        title: strings.proPreviewActiveTitle,
        message: strings.proPreviewActiveMessage,
      );
      return;
    }
    final enabled = await showMeloopConfirm(
      context,
      title: strings.proPreviewConfirmTitle,
      message: strings.proPreviewConfirmMessage,
      confirmLabel: strings.proPreviewEnable,
      onConfirm: widget.onEnablePreview,
      failureMessage: strings.proPreviewFailed,
    );
    if (!mounted || !enabled) return;
    setState(() => _isPro = true);
    MeloopNotifications.show(
      context,
      strings.proPreviewEnabled,
      kind: MeloopNoticeKind.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    return MeloopPage(
      topBar: MeloopTopBar(
        title: strings.proTitle,
        onBack: () => Navigator.of(context).pop(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: TempoColors.yellow,
                borderRadius: BorderRadius.circular(TempoRadius.pill),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: TempoSpace.md,
                  vertical: TempoSpace.xs,
                ),
                child: Text(
                  strings.proOneTimeBadge,
                  style: TempoType.caption.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: TempoSpace.xl),
          Text(strings.proHeading, style: TempoType.heading),
          const SizedBox(height: TempoSpace.sm),
          Text(
            strings.proSubtitle,
            style: TempoType.body.copyWith(color: TempoColors.muted),
          ),
          const SizedBox(height: TempoSpace.lg),
          LayoutBuilder(
            builder: (context, constraints) => Center(
              child: MeloopArt.scene(
                MeloopScene.pro,
                size: constraints.maxWidth.clamp(0, 290),
                backgroundColor: TempoColors.paper,
              ),
            ),
          ),
          const SizedBox(height: TempoSpace.md),
          MeloopCard(
            color: TempoColors.teal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        strings.proTitle,
                        style: TempoType.section.copyWith(
                          color: TempoColors.white,
                        ),
                      ),
                    ),
                    const MeloopIcon(
                      MeloopIcons.star,
                      color: TempoColors.white,
                    ),
                  ],
                ),
                const SizedBox(height: TempoSpace.md),
                Text(
                  strings.proIllustrativePrice,
                  style: TempoType.metric.copyWith(
                    color: TempoColors.yellow,
                    fontSize: 40,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: TempoSpace.sm),
                Text(
                  strings.proPriceCaption,
                  style: TempoType.caption.copyWith(color: TempoColors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: TempoSpace.lg),
          _ProBenefit(
            title: strings.proProfilesBenefit,
            message: strings.proProfilesDescription,
          ),
          _ProBenefit(
            title: strings.proFiltersBenefit,
            message: strings.proFiltersDescription,
          ),
          _ProBenefit(message: strings.proFreeFeatures),
          const SizedBox(height: TempoSpace.lg),
          MeloopButton(
            key: const Key('try-pro'),
            label: _isPro ? strings.proPreviewActive : strings.proPreviewTry,
            icon: MeloopIcons.star,
            style: MeloopButtonStyle.yellow,
            onPressed: () => unawaited(_enable()),
          ),
          const SizedBox(height: TempoSpace.lg),
          Text(
            strings.proPreviewFootnote,
            textAlign: TextAlign.center,
            style: TempoType.caption.copyWith(color: TempoColors.muted),
          ),
          const SizedBox(height: TempoSpace.sm),
          TextButton(
            key: const Key('restore-pro'),
            onPressed: () => showProRestoreNotice(context),
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: TempoSpace.xs,
              children: [
                Text(strings.proRestoreTransaction),
                const MeloopIcon(
                  MeloopIcons.refresh,
                  size: TempoSize.smallIcon,
                ),
              ],
            ),
          ),
          Text(
            strings.proRestoreFootnote,
            textAlign: TextAlign.center,
            style: TempoType.caption.copyWith(color: TempoColors.muted),
          ),
        ],
      ),
    );
  }
}

class _ProBenefit extends StatelessWidget {
  const _ProBenefit({this.title, required this.message});

  final String? title;
  final String message;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: TempoColors.line)),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: TempoSpace.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: TempoSpace.xs),
            child: MeloopIcon(
              MeloopIcons.check,
              size: TempoSize.smallIcon,
              color: TempoColors.muted,
            ),
          ),
          const SizedBox(width: TempoSpace.md),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  if (title != null)
                    TextSpan(
                      text: '$title\n',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  TextSpan(text: message),
                ],
              ),
              style: TempoType.body.copyWith(fontSize: 14),
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> showProRestoreNotice(BuildContext context) => _showProInfo(
  context,
  title: context.l10n.proRestoreTitle,
  message: context.l10n.proRestoreMessage,
);

Future<void> _showProInfo(
  BuildContext context, {
  required String title,
  required String message,
}) => showDialog<void>(
  context: context,
  builder: (dialogContext) => Dialog(
    insetPadding: const EdgeInsets.all(TempoSpace.page),
    constraints: const BoxConstraints(maxWidth: TempoSize.contentMaxWidth),
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(TempoSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: TempoSpace.lg,
        children: [
          Text(title, style: TempoType.section),
          Text(message),
          MeloopButton(
            label: dialogContext.l10n.proClose,
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
        ],
      ),
    ),
  ),
);
