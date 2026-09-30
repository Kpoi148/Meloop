import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/instrument_profile_service.dart';
import '../components/meloop_ui.dart';
import '../showcase/welcome_example.dart';
import 'profile_form.dart';
import 'profile_screens.dart';

enum ProfileEntryPage { automatic, picker, manager }

enum _ProfilePage { welcome, picker, manager, form }

/// UC-01/02/03/25 UI. Only the injected service can commit profile changes.
class InstrumentProfilesFeature extends ConsumerStatefulWidget {
  const InstrumentProfilesFeature({
    super.key,
    required this.onOpenHome,
    required this.onViewPro,
    this.onOpenUnfinishedSession,
    this.entryPage = ProfileEntryPage.automatic,
  });

  final ValueChanged<InstrumentProfile> onOpenHome;
  final VoidCallback onViewPro;
  final VoidCallback? onOpenUnfinishedSession;
  final ProfileEntryPage entryPage;

  @override
  ConsumerState<InstrumentProfilesFeature> createState() =>
      _InstrumentProfilesFeatureState();
}

class _InstrumentProfilesFeatureState
    extends ConsumerState<InstrumentProfilesFeature> {
  final _formKey = GlobalKey<ProfileFormState>();
  ProfileDirectory? _directory;
  _ProfilePage _page = _ProfilePage.welcome;
  _ProfilePage _formReturn = _ProfilePage.manager;
  String? _editingId;
  String? _loadError;
  bool _loading = true;
  bool _busy = false;

  InstrumentProfileService get _service =>
      ref.read(instrumentProfileServiceProvider);

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_load);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      var directory = await _service.load();
      if (widget.entryPage == ProfileEntryPage.automatic &&
          directory.profiles.length == 1 &&
          directory.selectedProfileId != directory.profiles.first.id) {
        directory = await _service.select(directory.profiles.first.id);
      }
      if (!mounted) return;
      setState(() {
        _directory = directory;
        _loading = false;
        _page = switch (widget.entryPage) {
          ProfileEntryPage.manager when directory.profiles.isNotEmpty =>
            _ProfilePage.manager,
          ProfileEntryPage.picker when directory.profiles.isNotEmpty =>
            _ProfilePage.picker,
          _ when directory.profiles.isEmpty => _ProfilePage.welcome,
          _ => _ProfilePage.picker,
        };
      });
      if (widget.entryPage == ProfileEntryPage.automatic &&
          directory.profiles.length == 1) {
        widget.onOpenHome(directory.profiles.first);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = 'Chưa thể tải hồ sơ trên thiết bị.';
        });
      }
    }
  }

  void _back() {
    if (_busy) return;
    final directory = _directory;
    if (directory == null) return;
    switch (_page) {
      case _ProfilePage.form:
        _formKey.currentState?.requestBack();
      case _ProfilePage.manager:
        if (directory.selectedProfile case final profile?) {
          widget.onOpenHome(profile);
        } else {
          setState(
            () => _page = directory.profiles.isEmpty
                ? _ProfilePage.welcome
                : _ProfilePage.picker,
          );
        }
      case _ProfilePage.picker:
        if (directory.selectedProfile case final profile?) {
          widget.onOpenHome(profile);
        } else {
          setState(() => _page = _ProfilePage.welcome);
        }
      case _ProfilePage.welcome:
        break;
    }
  }

  void _addProfile() {
    final directory = _directory;
    if (directory == null) return;
    if (!directory.canCreate) {
      _showLimit();
      return;
    }
    setState(() {
      _editingId = null;
      _formReturn = _page;
      _page = _ProfilePage.form;
    });
  }

  Future<void> _showLimit() async {
    final action = await showDialog<_LimitAction>(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(TempoSpace.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Đã đủ 3 hồ sơ', style: TempoType.section),
              const SizedBox(height: TempoSpace.sm),
              Text(
                'Miễn phí tối đa 3 hồ sơ nhạc cụ. Bạn vẫn có thể xem, sửa hoặc xóa hồ sơ hiện có.',
                style: TempoType.body,
              ),
              const SizedBox(height: TempoSpace.lg),
              MeloopButton(
                label: 'Quản lý hồ sơ',
                onPressed: () => Navigator.of(context).pop(_LimitAction.manage),
                style: MeloopButtonStyle.outline,
              ),
              const SizedBox(height: TempoSpace.sm),
              MeloopButton(
                label: 'Xem Meloop Pro',
                onPressed: () => Navigator.of(context).pop(_LimitAction.pro),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Để sau'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    if (action == _LimitAction.manage) {
      setState(() => _page = _ProfilePage.manager);
    } else if (action == _LimitAction.pro) {
      widget.onViewPro();
    }
  }

  void _edit(InstrumentProfile profile) {
    setState(() {
      _editingId = profile.id;
      _formReturn = _page;
      _page = _ProfilePage.form;
    });
  }

  Future<void> _create(
    String requestId,
    String name,
    InstrumentType instrumentType,
    String customType,
  ) async {
    if (_busy) return;
    _busy = true;
    try {
      final directory = await _service.create(
        requestId: requestId,
        name: name,
        instrumentType: instrumentType,
        customType: customType,
      );
      if (!mounted) return;
      setState(() => _directory = directory);
      final profile = directory.selectedProfile;
      if (profile == null) {
        throw const ProfileServiceException(ProfileServiceError.unknown);
      }
      widget.onOpenHome(profile);
    } finally {
      _busy = false;
    }
  }

  Future<void> _rename(String id, String name) async {
    if (_busy) return;
    _busy = true;
    try {
      final directory = await _service.rename(profileId: id, name: name);
      if (!mounted) return;
      setState(() {
        _directory = directory;
        _page = _ProfilePage.manager;
      });
      MeloopNotifications.show(
        context,
        'Đã đổi tên hồ sơ.',
        kind: MeloopNoticeKind.success,
      );
    } finally {
      _busy = false;
    }
  }

  Future<void> _select(InstrumentProfile profile) async {
    if (_busy) return;
    final directory = _directory!;
    if (directory.selectedProfileId == profile.id) {
      widget.onOpenHome(profile);
      return;
    }
    setState(() => _busy = true);
    try {
      final updated = await _service.select(profile.id);
      if (!mounted) return;
      setState(() => _directory = updated);
      if (updated.selectedProfile case final selected?) {
        widget.onOpenHome(selected);
      } else {
        throw const ProfileServiceException(ProfileServiceError.missingProfile);
      }
    } on ProfileServiceException catch (error) {
      if (!mounted) return;
      if (error.code == ProfileServiceError.missingProfile) {
        await _load();
      } else {
        _notice('Chưa thể chọn hồ sơ. Lựa chọn trước đó vẫn được giữ.');
      }
    } catch (_) {
      if (mounted) {
        _notice('Chưa thể chọn hồ sơ. Lựa chọn trước đó vẫn được giữ.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(InstrumentProfile profile) async {
    if (_busy) return;
    setState(() => _busy = true);
    ProfileDeletionImpact impact;
    try {
      impact = await _service.deletionImpact(profile.id);
    } on ProfileServiceException catch (error) {
      if (!mounted) return;
      if (error.code == ProfileServiceError.unfinishedSession) {
        await _unfinishedSessionDialog();
      } else {
        _notice('Chưa thể kiểm tra dữ liệu của hồ sơ. Vui lòng thử lại.');
      }
      return;
    } catch (_) {
      if (mounted) {
        _notice('Chưa thể kiểm tra dữ liệu của hồ sơ. Vui lòng thử lại.');
      }
      return;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted) return;
    final deleted = await showMeloopConfirm(
      context,
      title: 'Xóa hồ sơ "${profile.name}"?',
      message:
          'Thao tác này xóa vĩnh viễn ${impact.savedSessionCount} buổi luyện, mục tiêu tuần và ${impact.recordingCount} bản ghi âm trên thiết bị của hồ sơ này. Bản sao đã xuất ra ngoài ứng dụng không bị xóa.',
      confirmLabel: 'Xóa hồ sơ',
      cancelLabel: 'Giữ hồ sơ',
      destructive: true,
      failureMessage: 'Chưa thể xóa hồ sơ. Nếu có buổi luyện chưa hoàn tất, hãy xử lý buổi đó rồi thử lại.',
      onConfirm: () async {
        final updated = await _service.delete(profile.id);
        if (mounted) setState(() => _directory = updated);
      },
    );
    if (!mounted || !deleted) return;
    var directory = _directory!;
    if (directory.profiles.isEmpty) {
      setState(() => _page = _ProfilePage.welcome);
    } else if (directory.profiles.length == 1) {
      if (directory.selectedProfile == null) {
        try {
          directory = await _service.select(directory.profiles.first.id);
          if (!mounted) return;
          setState(() => _directory = directory);
        } catch (_) {
          if (mounted) {
            _notice('Hồ sơ đã xóa, nhưng chưa thể chọn hồ sơ còn lại.');
          }
          return;
        }
      }
      widget.onOpenHome(directory.selectedProfile!);
    } else {
      setState(() => _page = _ProfilePage.picker);
    }
  }

  Future<void> _unfinishedSessionDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buổi luyện chưa hoàn tất'),
        content: const Text(
          'Hãy lưu hoặc hủy buổi luyện của hồ sơ này trước khi xóa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
          if (widget.onOpenUnfinishedSession != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onOpenUnfinishedSession!();
              },
              child: const Text('Mở buổi luyện'),
            ),
        ],
      ),
    );
  }

  void _notice(String message) =>
      MeloopNotifications.show(context, message, kind: MeloopNoticeKind.error);

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) _back();
    },
    child: _buildPage(),
  );

  Widget _buildPage() {
    if (_loading) {
      return const MeloopPage(
        child: MeloopStateView(
          state: MeloopViewState.loading,
          title: 'Đang mở hồ sơ…',
        ),
      );
    }
    if (_loadError != null) {
      return MeloopPage(
        child: MeloopStateView(
          state: MeloopViewState.error,
          title: 'Chưa thể mở hồ sơ',
          message: _loadError,
          actionLabel: 'Thử lại',
          onAction: _load,
        ),
      );
    }
    final directory = _directory!;
    return switch (_page) {
      _ProfilePage.welcome => WelcomeExample(onCreateProfile: _addProfile),
      _ProfilePage.picker => ProfilePickerScreen(
        directory: directory,
        busy: _busy,
        onManage: () => setState(() => _page = _ProfilePage.manager),
        onAdd: _addProfile,
        onSelect: _select,
      ),
      _ProfilePage.manager => ProfileManagerScreen(
        directory: directory,
        onBack: _back,
        onAdd: _addProfile,
        onEdit: _edit,
        onDelete: _delete,
      ),
      _ProfilePage.form => ProfileForm(
        key: _formKey,
        profile: _editingId == null ? null : directory.byId(_editingId!),
        onBack: () => setState(() => _page = _formReturn),
        onCreate: _create,
        onRename: _rename,
      ),
    };
  }
}

enum _LimitAction { manage, pro }
