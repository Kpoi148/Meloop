import 'package:flutter/material.dart';

import '../components/meloop_ui.dart';

class WelcomeExample extends StatelessWidget {
  const WelcomeExample({super.key, this.onCreateProfile});
  final VoidCallback? onCreateProfile;
  @override
  Widget build(BuildContext context) => MeloopPage(
    padding: const EdgeInsets.fromLTRB(20, 25, 20, 30),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MeloopTopBar(
          centerWordmark: true,
          trailing: SizedBox(
            width: 48,
            child: Text(
              'VI ⌄',
              textAlign: TextAlign.right,
              style: TempoType.caption,
            ),
          ),
        ),
        const SizedBox(height: 36),
        const Text('Một chút âm nhạc.\nMỗi ngày.', style: TempoType.welcome),
        const SizedBox(height: 17),
        Text(
          'Luyện tập, ghi lại và nhìn thấy\nhành trình của chính bạn.',
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
                children: [Positioned(top: -36, left: 0, right: 0, child: art)],
              ),
            );
          },
        ),
        const MeloopNotice(
          message: 'Không cần tài khoản. Nhật ký lưu trên thiết bị.',
        ),
        const SizedBox(height: 10),
        MeloopButton(label: 'Tạo hồ sơ đầu tiên', onPressed: onCreateProfile),
      ],
    ),
  );
}
