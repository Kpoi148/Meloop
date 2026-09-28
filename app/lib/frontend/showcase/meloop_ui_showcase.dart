import 'package:flutter/material.dart';

import '../components/meloop_ui.dart';
import 'component_catalog.dart';
import 'home_example.dart';
import 'session_form_example.dart';
import 'setup_example.dart';
import 'welcome_example.dart';

/// Development entry point; sample records are never written to storage.
class MeloopUiShowcase extends StatefulWidget {
  const MeloopUiShowcase({super.key});
  @override
  State<MeloopUiShowcase> createState() => _MeloopUiShowcaseState();
}

class _MeloopUiShowcaseState extends State<MeloopUiShowcase> {
  int _tab = 0;
  final _search = TextEditingController();
  String _query = '';
  bool _failNextSave = false;
  int _saveCount = 0;
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _catalog() => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => const ComponentCatalog()));
  void _setup() => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => SetupExample(onSave: _save)));
  Future<void> _save(SessionFormValues values) async {
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    if (_failNextSave) {
      _failNextSave = false;
      throw StateError('Synthetic preview failure');
    }
    if (mounted) setState(() => _saveCount++);
  }

  @override
  Widget build(BuildContext context) => MeloopPage(
    bottomNavigation: MeloopBottomNavigation(
      selectedIndex: _tab,
      onSelected: (value) => setState(() => _tab = value),
    ),
    child: switch (_tab) {
      0 => HomeExample(
        onCreate: _setup,
        onHistory: () => setState(() => _tab = 1),
        onCatalog: _catalog,
      ),
      1 => _history(),
      2 => const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: TempoSpace.page,
        children: [
          MeloopTopBar(title: 'Tiến độ'),
          Text('Mỗi ngày,\nmột bước tiến.', style: TempoType.heading),
          MeloopStateView(
            state: MeloopViewState.empty,
            title: 'Chưa có dữ liệu tiến độ.',
            message: 'Hoàn tất một buổi luyện để nhìn lại hành trình.',
          ),
        ],
      ),
      _ => _settings(),
    },
  );
  Widget _history() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: TempoSpace.page,
    children: [
      const MeloopTopBar(),
      const Text('Buổi luyện', style: TempoType.heading),
      const Text('Những nốt nhạc làm nên hành trình.'),
      MeloopSearch(
        controller: _search,
        onChanged: (value) => setState(() => _query = value),
      ),
      MeloopChoiceGroup<int>(
        label: 'Khoảng thời gian',
        initialValue: 0,
        requirement: MeloopFieldRequirement.required,
        choices: const [
          MeloopChoice(value: 0, label: 'Tất cả'),
          MeloopChoice(value: 7, label: '7 ngày'),
          MeloopChoice(value: 30, label: '30 ngày'),
        ],
        onChanged: (_) {},
      ),
      if (_query.isNotEmpty && !'luyện gam c'.contains(_query.toLowerCase()))
        MeloopStateView(
          state: MeloopViewState.empty,
          title: 'Không có buổi luyện phù hợp.',
          actionLabel: 'Xóa tìm kiếm',
          onAction: () {
            _search.clear();
            setState(() => _query = '');
          },
        )
      else
        const MeloopCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Luyện gam C', style: TempoType.title),
              Text('23/09/2026 · 30 phút'),
            ],
          ),
        ),
      MeloopButton(
        label: 'Tạo buổi luyện',
        icon: MeloopIcons.plus,
        onPressed: _setup,
      ),
      Text(
        'Mẫu UI · $_saveCount lần lưu mẫu hoàn tất. Không ghi dữ liệu lên thiết bị.',
        style: TempoType.caption,
      ),
    ],
  );
  Widget _settings() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: TempoSpace.page,
    children: [
      const MeloopTopBar(title: 'Cài đặt'),
      const Text('Theo cách\ncủa bạn.', style: TempoType.heading),
      MeloopButton(
        label: 'Bộ thành phần cho Wei',
        style: MeloopButtonStyle.yellow,
        onPressed: _catalog,
      ),
      MeloopButton(
        label: 'Xem màn chào Tempo',
        style: MeloopButtonStyle.outline,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => WelcomeExample(onCreateProfile: _catalog),
          ),
        ),
      ),
      MeloopButton(
        label: 'Xem form lưu buổi luyện',
        style: MeloopButtonStyle.outline,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => SessionFormExample(onSave: _save),
          ),
        ),
      ),
      MeloopToggle(
        label: 'Mô phỏng lỗi ở lần lưu tiếp',
        value: _failNextSave,
        onChanged: (value) => setState(() => _failNextSave = value),
      ),
      const MeloopNotice(
        message: 'Đây là màn mẫu phát triển UI. Các thao tác không lưu nhật ký thật.',
      ),
    ],
  );
}
