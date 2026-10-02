import 'dart:ui';

import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../components/meloop_ui.dart';
import 'practice_session_detail_tokens.dart';

Future<bool> showPracticeSessionDeleteConfirm(
  BuildContext context, {
  required Future<void> Function() onDelete,
  bool recording = false,
}) async =>
    await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: context.l10n.cancel,
      barrierColor: Colors.transparent,
      pageBuilder: (_, _, _) =>
          _DeleteDialog(onDelete: onDelete, recording: recording),
    ) ??
    false;

class _DeleteDialog extends StatefulWidget {
  const _DeleteDialog({required this.onDelete, required this.recording});
  final Future<void> Function() onDelete;
  final bool recording;
  @override
  State<_DeleteDialog> createState() => _DeleteDialogState();
}

class _DeleteDialogState extends State<_DeleteDialog> {
  bool _busy = false;
  bool _failed = false;

  Future<void> _delete() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      await widget.onDelete();
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    return PopScope(
      canPop: !_busy,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: PracticeSessionDetailTokens.dialogBlur,
          sigmaY: PracticeSessionDetailTokens.dialogBlur,
        ),
        child: ColoredBox(
          color: PracticeSessionDetailTokens.dialogBarrier,
          child: Dialog(
            insetPadding: const EdgeInsets.all(
              PracticeSessionDetailTokens.dialogInset,
            ),
            constraints: const BoxConstraints(
              maxWidth: PracticeSessionDetailTokens.dialogMaxWidth,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                PracticeSessionDetailTokens.dialogRadius,
              ),
              side: const BorderSide(color: TempoColors.line),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(
                PracticeSessionDetailTokens.dialogPadding,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    namesRoute: true,
                    child: Text(
                      widget.recording
                          ? strings.deleteRecordingTitle
                          : strings.deleteSessionTitle,
                      style: PracticeSessionDetailTokens.dialogHeading,
                    ),
                  ),
                  const SizedBox(
                    height: PracticeSessionDetailTokens.dialogMessageTop,
                  ),
                  Text(
                    widget.recording
                        ? strings.deleteRecordingMessage
                        : strings.deleteSessionMessage,
                    style: PracticeSessionDetailTokens.dialogMessage,
                  ),
                  if (_failed) ...[
                    const SizedBox(height: TempoSpace.lg),
                    MeloopNotice(
                      message: strings.deleteSessionFailed,
                      kind: MeloopNoticeKind.error,
                    ),
                  ],
                  const SizedBox(
                    height: PracticeSessionDetailTokens.dialogActionsTop,
                  ),
                  MeloopResponsiveRow(
                    children: [
                      _DialogButton(
                        label: strings.cancel,
                        onPressed: _busy
                            ? null
                            : () => Navigator.of(context).pop(false),
                      ),
                      _DialogButton(
                        label: _failed
                            ? strings.retry
                            : widget.recording
                            ? strings.deleteRecording
                            : strings.deleteSession,
                        onPressed: _busy ? null : _delete,
                        destructive: true,
                        busy: _busy,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.onPressed,
    this.destructive = false,
    this.busy = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool destructive, busy;
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      minimumSize: const Size(TempoSize.touchTarget, TempoSize.buttonMinHeight),
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
      backgroundColor: destructive
          ? PracticeSessionDetailTokens.destructiveFill
          : Colors.transparent,
      foregroundColor: destructive ? TempoColors.white : TempoColors.ink,
      textStyle: PracticeSessionDetailTokens.dialogAction,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TempoRadius.button),
        side: destructive
            ? BorderSide.none
            : const BorderSide(
                color: PracticeSessionDetailTokens.outlineBorder,
              ),
      ),
    ),
    child: busy
        ? const SizedBox.square(
            dimension: TempoSize.smallIcon,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: TempoColors.white,
            ),
          )
        : Text(label, textAlign: TextAlign.center),
  );
}
