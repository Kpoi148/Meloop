import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../components/meloop_ui.dart';

class PreviewDataResetButton extends StatelessWidget {
  const PreviewDataResetButton({
    super.key,
    required this.onReset,
    this.onComplete,
  });

  final FutureOr<void> Function() onReset;
  final VoidCallback? onComplete;

  Future<void> _confirmReset(BuildContext context) async {
    final strings = context.l10n;
    final confirmed = await showMeloopConfirm(
      context,
      title: strings.previewResetTitle,
      message: strings.previewResetMessage,
      confirmLabel: strings.previewResetConfirm,
      cancelLabel: strings.previewResetCancel,
      destructive: true,
      onConfirm: onReset,
      failureMessage: strings.previewResetFailed,
    );
    if (confirmed && context.mounted) onComplete?.call();
  }

  @override
  Widget build(BuildContext context) => MeloopButton(
    key: const Key('reset-preview-data'),
    label: context.l10n.previewResetAction,
    style: MeloopButtonStyle.danger,
    onPressed: () {
      unawaited(_confirmReset(context));
    },
  );
}
