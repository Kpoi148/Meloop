import 'package:flutter/material.dart';

import '../components/meloop_ui.dart';

class ComponentCatalog extends StatefulWidget {
  const ComponentCatalog({super.key});
  @override
  State<ComponentCatalog> createState() => _ComponentCatalogState();
}

class _ComponentCatalogState extends State<ComponentCatalog> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _bpm = TextEditingController(text: '80');
  bool _reminder = false, _diagnostics = false;
  int _tab = 7;
  int? _rating;
  @override
  void dispose() {
    _name.dispose();
    _bpm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MeloopPage(
    topBar: MeloopTopBar(
      title: 'Thành phần dùng chung',
      onBack: () => Navigator.of(context).pop(),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: TempoSpace.page,
      children: [
        const Text('Cùng một nhịp\nthiết kế.', style: TempoType.heading),
        const Text(
          'Mẫu UI Tempo · dữ liệu minh họa chỉ nằm trong bộ nhớ.',
          style: TempoType.caption,
        ),
        const Text('Nút & trạng thái đang lưu', style: TempoType.section),
        for (final style in MeloopButtonStyle.values)
          MeloopButton(
            label: switch (style) {
              MeloopButtonStyle.primary => 'Lưu buổi luyện',
              MeloopButtonStyle.yellow => 'Tạo buổi luyện',
              MeloopButtonStyle.outline => 'Thêm nhạc cụ',
              MeloopButtonStyle.soft => 'Công cụ',
              MeloopButtonStyle.orange => 'Kết thúc',
              MeloopButtonStyle.danger => 'Xóa buổi luyện',
            },
            style: style,
            icon: MeloopIcons.check,
            onPressed: () async {
              await Future<void>.delayed(const Duration(milliseconds: 800));
            },
          ),
        const MeloopButton(label: 'Không khả dụng', onPressed: null),
        const MeloopButton(label: 'Lưu', onPressed: null, isLoading: true),
        const Text('Ô nhập & lỗi tại trường', style: TempoType.section),
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: TempoSpace.lg,
            children: [
              MeloopField(
                label: 'Tên hồ sơ',
                controller: _name,
                requirement: MeloopFieldRequirement.required,
                validator: MeloopValidation.profileName,
                helper: '1–50 ký tự. Giữ nội dung nếu lưu thất bại.',
              ),
              MeloopField(
                label: 'Tốc độ (BPM)',
                controller: _bpm,
                type: MeloopInputType.integer,
                requirement: MeloopFieldRequirement.required,
                validator: (value) => MeloopValidation.integer(
                  value,
                  label: 'BPM',
                  min: 40,
                  max: 240,
                ),
              ),
              MeloopButton(
                label: 'Kiểm tra dữ liệu',
                onPressed: () {
                  _form.currentState!.validate();
                },
              ),
            ],
          ),
        ),
        const Text('Lựa chọn & tab', style: TempoType.section),
        MeloopChoiceGroup<int>(
          label: 'Khoảng thời gian',
          initialValue: _tab,
          requirement: MeloopFieldRequirement.required,
          choices: const [
            MeloopChoice(value: 7, label: '7 ngày'),
            MeloopChoice(value: 30, label: '30 ngày'),
            MeloopChoice(value: 0, label: 'Tất cả'),
          ],
          onChanged: (value) => setState(() => _tab = value!),
        ),
        MeloopSelect<int>(
          label: 'Số phách mỗi ô nhịp',
          initialValue: 4,
          requirement: MeloopFieldRequirement.required,
          choices: [
            for (var i = 1; i <= 12; i++)
              MeloopChoice(value: i, label: '$i phách'),
          ],
          onChanged: (_) {},
        ),
        MeloopChoiceGroup<int>(
          label: 'Cảm xúc',
          initialValue: _rating,
          clearable: true,
          choices: [
            for (var i = 1; i <= 5; i++)
              MeloopChoice(value: i, label: '$i / 5'),
          ],
          onChanged: (value) => setState(() => _rating = value),
        ),
        MeloopToggle(
          label: 'Nhắc lịch luyện',
          description: 'Nhắc một chút âm nhạc mỗi ngày.',
          value: _reminder,
          onChanged: (value) => setState(() => _reminder = value),
        ),
        MeloopToggle(
          label: 'Đính kèm thông tin chẩn đoán',
          description: 'Chỉ khi bạn chủ động chọn.',
          checkbox: true,
          value: _diagnostics,
          onChanged: (value) => setState(() => _diagnostics = value),
        ),
        const Text('Hộp thoại & thông báo', style: TempoType.section),
        MeloopButton(
          label: 'Mở hộp thoại xác nhận',
          style: MeloopButtonStyle.outline,
          onPressed: () async {
            await showMeloopConfirm(
              context,
              title: 'Xóa buổi luyện?',
              message: 'Nhật ký và bản ghi âm của buổi này sẽ bị xóa.',
              destructive: true,
              confirmLabel: 'Xóa buổi luyện',
            );
          },
        ),
        MeloopButton(
          label: 'Mở bảng lựa chọn',
          style: MeloopButtonStyle.soft,
          onPressed: () async {
            await showMeloopSheet<void>(
              context,
              title: 'Bộ thành phần Tempo',
              child: const MeloopNotice(
                message: 'Các màn hình dùng cùng theme, font, màu và icon.',
              ),
            );
          },
        ),
        MeloopButton(
          label: 'Hiện thông báo',
          style: MeloopButtonStyle.outline,
          onPressed: () => MeloopNotifications.show(
            context,
            'Đã hoàn tất thao tác mẫu.',
            kind: MeloopNoticeKind.success,
          ),
        ),
        const MeloopNotice(message: 'Nhật ký lưu trên thiết bị.'),
        const MeloopNotice(
          message: 'Đã lưu buổi luyện.',
          kind: MeloopNoticeKind.success,
        ),
        const MeloopNotice(
          message: 'Chưa thể lưu. Nội dung vẫn ở đây.',
          kind: MeloopNoticeKind.error,
        ),
        const Text('Tải / trống / lỗi', style: TempoType.section),
        const MeloopStateView(
          state: MeloopViewState.loading,
          title: 'Đang tải buổi luyện…',
        ),
        MeloopStateView(
          state: MeloopViewState.empty,
          title: 'Hành trình bắt đầu từ hôm nay.',
          message: 'Lưu buổi luyện đầu tiên của bạn.',
          actionLabel: 'Tạo buổi luyện',
          onAction: () {},
        ),
        MeloopStateView(
          state: MeloopViewState.error,
          title: 'Chưa thể tải buổi luyện.',
          message: 'Vui lòng thử lại. Dữ liệu của bạn vẫn được giữ.',
          actionLabel: 'Thử lại',
          onAction: () {},
        ),
      ],
    ),
  );
}
