import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/instrument_profile_service.dart';
import '../components/meloop_ui.dart';
import '../profiles/instrument_profiles_feature.dart';
import 'preview_data_reset_button.dart';
import 'profile_preview_service.dart';

/// Interactive FE preview with its own temporary profile state.
class InstrumentProfilePreview extends StatefulWidget {
  const InstrumentProfilePreview({super.key});

  @override
  State<InstrumentProfilePreview> createState() =>
      _InstrumentProfilePreviewState();
}

class _InstrumentProfilePreviewState extends State<InstrumentProfilePreview> {
  ProfilePreviewService _service = ProfilePreviewService();
  int _generation = 0;

  void _reset() {
    setState(() {
      _service = ProfilePreviewService();
      _generation++;
    });
  }

  @override
  Widget build(BuildContext context) => ProviderScope(
    key: ValueKey(_generation),
    overrides: [instrumentProfileServiceProvider.overrideWithValue(_service)],
    child: _ProfilePreview(onReset: _reset),
  );
}

enum _PreviewPage { profiles, home, pro }

class _ProfilePreview extends StatefulWidget {
  const _ProfilePreview({required this.onReset});

  final VoidCallback onReset;

  @override
  State<_ProfilePreview> createState() => _ProfilePreviewState();
}

class _ProfilePreviewState extends State<_ProfilePreview> {
  _PreviewPage _page = _PreviewPage.profiles;
  ProfileEntryPage _entryPage = ProfileEntryPage.automatic;
  InstrumentProfile? _selected;

  void _showProfiles(ProfileEntryPage entry) {
    setState(() {
      _entryPage = entry;
      _page = _PreviewPage.profiles;
    });
  }

  @override
  Widget build(BuildContext context) => switch (_page) {
    _PreviewPage.profiles => InstrumentProfilesFeature(
      key: ValueKey(_entryPage),
      entryPage: _entryPage,
      onOpenHome: (profile) => setState(() {
        _selected = profile;
        _page = _PreviewPage.home;
      }),
      onViewPro: () => setState(() => _page = _PreviewPage.pro),
    ),
    _PreviewPage.home => MeloopPage(
      topBar: const MeloopTopBar(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: TempoSpace.xl),
          Text('Tổng quan', style: TempoType.heading),
          const SizedBox(height: TempoSpace.sm),
          Text(_selected!.name, style: TempoType.section),
          Text(
            _selected!.instrumentLabel,
            style: TempoType.body.copyWith(color: TempoColors.muted),
          ),
          const SizedBox(height: TempoSpace.xl),
          MeloopArt.instrument(
            MeloopInstrument.values[_selected!.instrumentType.index],
            size: 220,
          ),
          const SizedBox(height: TempoSpace.xl),
          const MeloopNotice(
            message: 'Bản xem thử giao diện: hồ sơ chỉ nằm trong bộ nhớ và sẽ mất khi đóng ứng dụng.',
          ),
          const SizedBox(height: TempoSpace.xl),
          MeloopButton(
            label: 'Đổi nhạc cụ',
            onPressed: () => _showProfiles(ProfileEntryPage.picker),
            style: MeloopButtonStyle.outline,
          ),
          const SizedBox(height: TempoSpace.md),
          MeloopButton(
            label: 'Quản lý hồ sơ',
            onPressed: () => _showProfiles(ProfileEntryPage.manager),
          ),
          const SizedBox(height: TempoSpace.md),
          PreviewDataResetButton(onReset: widget.onReset),
        ],
      ),
    ),
    _PreviewPage.pro => MeloopPage(
      topBar: MeloopTopBar(
        title: 'Meloop Pro',
        onBack: () => _showProfiles(ProfileEntryPage.manager),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Thêm không gian\ncho âm nhạc.', style: TempoType.heading),
          const SizedBox(height: TempoSpace.lg),
          const MeloopNotice(
            message: 'Đây là bản xem thử giao diện. Tính năng mua Pro sẽ được kết nối ở task thanh toán.',
          ),
          const SizedBox(height: TempoSpace.xl),
          MeloopButton(
            label: 'Quản lý hồ sơ',
            onPressed: () => _showProfiles(ProfileEntryPage.manager),
          ),
        ],
      ),
    ),
  };
}
