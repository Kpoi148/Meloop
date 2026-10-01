import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/instrument_profile_service.dart';
import '../application/session_form_controller.dart';
import '../components/meloop_ui.dart';
import '../profiles/instrument_profiles_feature.dart';
import 'preview_data_reset_button.dart';
import 'profile_preview_service.dart';
import 'meloop_ui_showcase.dart';
import 'showcase_controller.dart';

/// Interactive FE flow with a replaceable local prototype service.
class InstrumentProfilePreview extends StatefulWidget {
  const InstrumentProfilePreview({super.key, this.service});

  final ProfilePreviewService? service;

  @override
  State<InstrumentProfilePreview> createState() =>
      _InstrumentProfilePreviewState();
}

class _InstrumentProfilePreviewState extends State<InstrumentProfilePreview> {
  late final ProfilePreviewService _service =
      widget.service ?? ProfilePreviewService();
  int _generation = 0;

  Future<void> _reset() async {
    await _service.reset();
    if (!mounted) return;
    setState(() {
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

enum _PreviewPage { loading, loadError, profiles, home, pro }

class _ProfilePreview extends ConsumerStatefulWidget {
  const _ProfilePreview({required this.onReset});

  final Future<void> Function() onReset;

  @override
  ConsumerState<_ProfilePreview> createState() => _ProfilePreviewState();
}

class _ProfilePreviewState extends ConsumerState<_ProfilePreview> {
  _PreviewPage _page = _PreviewPage.loading;
  ProfileEntryPage _entryPage = ProfileEntryPage.automatic;
  InstrumentProfile? _selected;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_load);
  }

  Future<void> _load() async {
    setState(() => _page = _PreviewPage.loading);
    try {
      final service = ref.read(instrumentProfileServiceProvider);
      var directory = await service.load();
      // Reopen Home using the last profile, including when there are several.
      if (directory.profiles.isNotEmpty && directory.selectedProfile == null) {
        directory = await service.select(directory.profiles.first.id);
      }
      if (!mounted) return;
      setState(() {
        _selected = directory.selectedProfile;
        _page = _selected == null ? _PreviewPage.profiles : _PreviewPage.home;
      });
    } catch (_) {
      if (mounted) setState(() => _page = _PreviewPage.loadError);
    }
  }

  void _showProfiles(ProfileEntryPage entry) {
    setState(() {
      _entryPage = entry;
      _page = _PreviewPage.profiles;
    });
  }

  @override
  Widget build(BuildContext context) => switch (_page) {
    _PreviewPage.loading => const MeloopPage(
      child: MeloopStateView(
        state: MeloopViewState.loading,
        title: 'Đang mở hồ sơ…',
      ),
    ),
    _PreviewPage.loadError => MeloopPage(
      child: Column(
        children: [
          MeloopStateView(
            state: MeloopViewState.error,
            title: 'Chưa thể mở hồ sơ trên thiết bị.',
            actionLabel: 'Thử lại',
            onAction: _load,
          ),
          const SizedBox(height: TempoSpace.lg),
          PreviewDataResetButton(onReset: widget.onReset),
        ],
      ),
    ),
    _PreviewPage.profiles => InstrumentProfilesFeature(
      key: ValueKey(_entryPage),
      entryPage: _entryPage,
      onOpenHome: (profile) => setState(() {
        _selected = profile;
        _page = _PreviewPage.home;
      }),
      onViewPro: () => setState(() => _page = _PreviewPage.pro),
    ),
    _PreviewPage.home => ProviderScope(
      key: ValueKey(_selected!.id),
      overrides: [
        showcaseControllerProvider.overrideWith(ShowcaseController.new),
        sessionFormSaveProvider.overrideWith(
          (ref) =>
              (values) => ref
                  .read(showcaseControllerProvider.notifier)
                  .simulateSave(values),
        ),
      ],
      child: MeloopUiShowcase(
        profile: _selected,
        onChooseProfile: () => _showProfiles(ProfileEntryPage.picker),
        onManageProfiles: () => _showProfiles(ProfileEntryPage.manager),
        onResetData: widget.onReset,
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
