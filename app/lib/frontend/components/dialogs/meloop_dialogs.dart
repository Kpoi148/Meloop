import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/tokens/tempo_tokens.dart';
import '../buttons/meloop_button.dart';
import '../feedback/meloop_feedback.dart';
import '../layout/meloop_page.dart';

Future<bool> showMeloopConfirm(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Xác nhận',
  String cancelLabel = 'Hủy',
  bool destructive = false,
  FutureOr<void> Function()? onConfirm,
  String failureMessage = 'Chưa thể hoàn tất. Vui lòng thử lại.',
}) async =>
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _MeloopConfirm(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        destructive: destructive,
        onConfirm: onConfirm,
        failureMessage: failureMessage,
      ),
    ) ??
    false;

class _MeloopConfirm extends StatefulWidget {
  const _MeloopConfirm({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.destructive,
    required this.onConfirm,
    required this.failureMessage,
  });
  final String title, message, confirmLabel, cancelLabel, failureMessage;
  final bool destructive;
  final FutureOr<void> Function()? onConfirm;
  @override
  State<_MeloopConfirm> createState() => _MeloopConfirmState();
}

class _MeloopConfirmState extends State<_MeloopConfirm> {
  bool _busy = false;
  String? _error;
  Future<void> _confirm() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onConfirm?.call();
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) setState(() => _error = widget.failureMessage);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Dialog(
      insetPadding: const EdgeInsets.all(TempoSpace.page),
      constraints: const BoxConstraints(maxWidth: TempoSize.contentMaxWidth),
      // Scroll the actions together with the message. AlertDialog's fixed action
      // region can exceed the available height with large text and a keyboard.
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(TempoSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: TempoSpace.lg,
          children: [
            Semantics(
              namesRoute: true,
              child: Text(widget.title, style: TempoType.section),
            ),
            Text(widget.message),
            if (_error != null)
              MeloopNotice(message: _error!, kind: MeloopNoticeKind.error),
            MeloopResponsiveRow(
              children: [
                MeloopButton(
                  label: widget.cancelLabel,
                  onPressed: _busy
                      ? null
                      : () => Navigator.of(context).pop(false),
                  style: MeloopButtonStyle.outline,
                ),
                MeloopButton(
                  label: widget.confirmLabel,
                  onPressed: _confirm,
                  isLoading: _busy,
                  loadingLabel: 'Đang xử lý…',
                  style: widget.destructive
                      ? MeloopButtonStyle.danger
                      : MeloopButtonStyle.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

Future<T?> showMeloopSheet<T>(
  BuildContext context, {
  required String title,
  required Widget child,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: TempoColors.paper,
  showDragHandle: true,
  builder: (context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(TempoSpace.page),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: TempoType.section),
            const SizedBox(height: TempoSpace.lg),
            child,
          ],
        ),
      ),
    ),
  ),
);
