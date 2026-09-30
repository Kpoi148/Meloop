import 'package:flutter/material.dart';

import 'app/meloop_app.dart';
import 'frontend/application/instrument_profile_service.dart';
import 'frontend/components/meloop_ui.dart';
import 'frontend/profiles/instrument_profiles_feature.dart';
import 'frontend/showcase/profile_preview_service.dart';

void main() {
  final service = ProfilePreviewService();
  runApp(
    MeloopApp(
      overrides: [instrumentProfileServiceProvider.overrideWithValue(service)],
      home: const _ProfilePreview(),
    ),
  );
}

enum _PreviewPage { profiles, home, pro }

class _ProfilePreview extends StatefulWidget {
  const _ProfilePreview();

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
