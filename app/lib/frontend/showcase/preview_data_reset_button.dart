import 'dart:async';

import 'package:flutter/material.dart';

import '../components/meloop_ui.dart';

class PreviewDataResetButton extends StatelessWidget {
  const PreviewDataResetButton({super.key, required this.onReset});

  final VoidCallback onReset;

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showMeloopConfirm(
      context,
      title: 'Bắt đầu lại từ màn chào?',
      message:
          'Toàn bộ hồ sơ và dữ liệu thử trong bản UI sẽ được xóa. '
          'Ứng dụng sẽ trở về màn hình chào để bạn test lại từ đầu.',
      confirmLabel: 'Xóa và bắt đầu lại',
      cancelLabel: 'Giữ dữ liệu',
      destructive: true,
    );
    if (confirmed && context.mounted) onReset();
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
