import 'dart:async';

import 'package:flutter/material.dart';

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
    final confirmed = await showMeloopConfirm(
      context,
      title: 'Bắt đầu lại từ màn chào?',
      message:
          'Toàn bộ hồ sơ, lựa chọn nhạc cụ và dữ liệu thử trong bản UI trên thiết bị sẽ được xóa. '
          'Ứng dụng sẽ trở về màn hình chào để bạn test lại từ đầu.',
      confirmLabel: 'Xóa và bắt đầu lại',
      cancelLabel: 'Giữ dữ liệu',
      destructive: true,
      onConfirm: onReset,
      failureMessage:
          'Chưa thể xóa dữ liệu. Hồ sơ của bạn vẫn được giữ. Hãy thử lại.',
    );
    if (confirmed && context.mounted) onComplete?.call();
  }

  @override
  Widget build(BuildContext context) => MeloopButton(
    key: const Key('reset-preview-data'),
    label: 'Xóa dữ liệu và bắt đầu lại',
    style: MeloopButtonStyle.danger,
    onPressed: () {
      unawaited(_confirmReset(context));
    },
  );
}
