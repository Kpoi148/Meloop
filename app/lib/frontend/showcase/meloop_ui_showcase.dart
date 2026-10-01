import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/meloop_ui.dart';
import 'component_catalog.dart';
import 'home_example.dart';
import 'instrument_profile_preview.dart';
import 'preview_data_reset_button.dart';
import 'session_form_example.dart';
import 'showcase_controller.dart';
import 'setup_example.dart';
import 'welcome_example.dart';

/// Development entry point; sample records are never written to storage.
class MeloopUiShowcase extends ConsumerStatefulWidget {
  const MeloopUiShowcase({super.key});
  @override
  ConsumerState<MeloopUiShowcase> createState() => _MeloopUiShowcaseState();
}

class _MeloopUiShowcaseState extends ConsumerState<MeloopUiShowcase> {
  final _search = TextEditingController();
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _catalog() => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => const ComponentCatalog()));
  void _setup() =>
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => const SetupExample()));

  void _resetData() {
    ref.invalidate(showcaseControllerProvider);
    Navigator.of(context).pushAndRemoveUntil<void>(
      MaterialPageRoute(builder: (_) => const InstrumentProfilePreview()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(showcaseControllerProvider);
    final controller = ref.read(showcaseControllerProvider.notifier);
    // Keep the editing controller aligned when providers are reset or overridden.
    if (_search.text != state.query) {
      _search.value = TextEditingValue(
        text: state.query,
        selection: TextSelection.collapsed(offset: state.query.length),
      );
    }
    return MeloopPage(
      bottomNavigation: MeloopBottomNavigation(
        selectedIndex: state.selectedTab,
        onSelected: controller.selectTab,
      ),
      child: switch (state.selectedTab) {
        0 => HomeExample(
          onCreate: _setup,
          onHistory: () => controller.selectTab(1),
          onCatalog: _catalog,
        ),
        1 => _history(state, controller),
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
        _ => _settings(state, controller),
      },
    );
  }

  Widget _history(ShowcaseState state, ShowcaseController controller) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: TempoSpace.page,
    children: [
      const MeloopTopBar(),
      const Text('Buổi luyện', style: TempoType.heading),
      const Text('Những nốt nhạc làm nên hành trình.'),
      MeloopSearch(controller: _search, onChanged: controller.search),
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
      if (state.query.isNotEmpty &&
          !'luyện gam c'.contains(state.query.toLowerCase()))
        MeloopStateView(
          state: MeloopViewState.empty,
          title: 'Không có buổi luyện phù hợp.',
          actionLabel: 'Xóa tìm kiếm',
          onAction: () {
            _search.clear();
            controller.search('');
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
        'Mẫu UI · ${state.saveCount} lần lưu mẫu hoàn tất. Không ghi dữ liệu lên thiết bị.',
        style: TempoType.caption,
      ),
    ],
  );
  Widget _settings(ShowcaseState state, ShowcaseController controller) =>
      Column(
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
                builder: (_) => const SessionFormExample(),
              ),
            ),
          ),
          MeloopToggle(
            label: 'Mô phỏng lỗi ở lần lưu tiếp',
            value: state.failNextSave,
            onChanged: controller.simulateFailure,
          ),
          PreviewDataResetButton(onReset: _resetData),
          const MeloopNotice(
            message: 'Đây là màn mẫu phát triển UI. Các thao tác không lưu nhật ký thật.',
          ),
        ],
      );
}
