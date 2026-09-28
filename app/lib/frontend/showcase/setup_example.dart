import 'package:flutter/material.dart';

import '../components/meloop_ui.dart';
import 'session_form_example.dart';

class SetupExample extends StatefulWidget {
  const SetupExample({super.key, required this.onSave});
  final Future<void> Function(SessionFormValues) onSave;
  @override
  State<SetupExample> createState() => _SetupExampleState();
}

class _SetupExampleState extends State<SetupExample> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MeloopPage(
    topBarGap: 7,
    topBar: MeloopTopBar(
      title: 'Tạo buổi luyện',
      onBack: () => Navigator.of(context).pop(),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final large = MediaQuery.textScalerOf(context).scale(16) > 20;
            const heading = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('BUỔI LUYỆN MỚI', style: TempoType.caption),
                SizedBox(height: TempoSpace.sm),
                Text('Hôm nay bạn\nmuốn tập gì?', style: TempoType.setup),
              ],
            );
            final height = constraints.maxWidth >= 400 ? 430.0 : 370.0;
            final art = MeloopIllustration(
              asset: 'fidelity-setup.png',
              height: height,
            );
            if (large) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [heading, art],
              );
            }
            // Artwork extends under the following profile card, as in Tempo.
            return SizedBox(
              height: height - 32,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(top: 0, left: 0, right: 0, child: art),
                  const Positioned(top: 21, left: 0, right: 0, child: heading),
                ],
              ),
            );
          },
        ),
        const MeloopCard(
          color: TempoColors.soft,
          padding: EdgeInsets.symmetric(horizontal: 17, vertical: 13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Guitar của tôi', style: TempoType.section),
              Text('Guitar'),
            ],
          ),
        ),
        const SizedBox(height: 17),
        Form(
          key: _form,
          child: MeloopField(
            label: 'Tên buổi luyện',
            controller: _title,
            requirement: MeloopFieldRequirement.required,
            hint: 'Ví dụ: Luyện gam C',
            helper: 'Đặt tên để dễ tìm lại. Có thể đổi khi xem lại.',
            validator: MeloopValidation.title,
          ),
        ),
        const SizedBox(height: 17),
        const MeloopNotice(
          message: 'Bộ đếm bắt đầu khi bạn bấm Bắt đầu luyện.',
        ),
        const SizedBox(height: TempoSpace.lg),
        MeloopButton(
          label: 'Bắt đầu luyện',
          icon: MeloopIcons.play,
          onPressed: () {
            if (!_form.currentState!.validate()) return;
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SessionFormExample(
                  initialTitle: _title.text.trim(),
                  onSave: widget.onSave,
                ),
              ),
            );
          },
        ),
      ],
    ),
  );
}
