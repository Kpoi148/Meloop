import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../theme/tokens/tempo_tokens.dart';
import '../buttons/meloop_button.dart';
import '../layout/meloop_icon.dart';

enum MeloopNoticeKind { info, success, error }

class MeloopNotice extends StatelessWidget {
  const MeloopNotice({
    super.key,
    required this.message,
    this.kind = MeloopNoticeKind.info,
  });
  final String message;
  final MeloopNoticeKind kind;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      padding: const EdgeInsets.all(TempoSpace.md),
      decoration: BoxDecoration(
        color: kind == MeloopNoticeKind.error
            ? TempoColors.errorSurface
            : TempoColors.soft,
        borderRadius: BorderRadius.circular(TempoRadius.field),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MeloopIcon(
            switch (kind) {
              MeloopNoticeKind.success => MeloopIcons.check,
              MeloopNoticeKind.error => MeloopIcons.help,
              _ => MeloopIcons.shield,
            },
            color: kind == MeloopNoticeKind.error
                ? TempoColors.error
                : TempoColors.teal,
          ),
          const SizedBox(width: TempoSpace.md),
          Expanded(
            child: Text(
              message,
              style: TempoType.caption.copyWith(
                color: kind == MeloopNoticeKind.error
                    ? TempoColors.error
                    : TempoColors.ink,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

abstract final class MeloopNotifications {
  static void show(
    BuildContext context,
    String message, {
    MeloopNoticeKind kind = MeloopNoticeKind.info,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: TempoColors.paper,
        behavior: SnackBarBehavior.floating,
        padding: EdgeInsets.zero,
        duration: const Duration(seconds: 5),
        content: MeloopNotice(message: message, kind: kind),
        showCloseIcon: true,
        closeIconColor: TempoColors.ink,
      ),
    );
  }
}

enum MeloopViewState { loading, empty, error }

class MeloopStateView extends StatelessWidget {
  const MeloopStateView({
    super.key,
    required this.state,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });
  final MeloopViewState state;
  final String title;
  final String? message;
  final String? actionLabel;
  final FutureOr<void> Function()? onAction;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TempoSpace.xl),
      decoration: BoxDecoration(
        border: Border.all(color: TempoColors.line),
        borderRadius: BorderRadius.circular(TempoRadius.card),
      ),
      child: Column(
        children: [
          if (state == MeloopViewState.loading)
            const CircularProgressIndicator()
          else
            MeloopIcon(
              state == MeloopViewState.error
                  ? MeloopIcons.help
                  : MeloopIcons.book,
              size: 40,
            ),
          const SizedBox(height: TempoSpace.lg),
          Text(title, style: TempoType.title, textAlign: TextAlign.center),
          if (message != null) ...[
            const SizedBox(height: TempoSpace.sm),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: TempoType.body.copyWith(color: TempoColors.muted),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: TempoSpace.lg),
            MeloopButton(
              label: actionLabel!,
              onPressed: onAction,
              style: MeloopButtonStyle.outline,
              loadingLabel: context.l10n.retrying,
            ),
          ],
        ],
      ),
    ),
  );
}
