import 'dart:math';

import 'package:flutter/material.dart';

import '../application/instrument_profile_service.dart';
import '../components/meloop_ui.dart';

class ProfileForm extends StatefulWidget {
  const ProfileForm({
    super.key,
    required this.onBack,
    required this.onCreate,
    required this.onRename,
    this.profile,
  });

  final InstrumentProfile? profile;
  final VoidCallback onBack;
  final Future<void> Function(
    String requestId,
    String name,
    InstrumentType instrumentType,
    String customType,
  )
  onCreate;
  final Future<void> Function(String profileId, String name) onRename;

  @override
  State<ProfileForm> createState() => ProfileFormState();
}

class ProfileFormState extends State<ProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _customType;
  late final String _requestId;
  InstrumentType? _type;
  bool _suggestedName = true;
  bool _saving = false;
  String? _nameError;
  String? _typeError;
  String? _formError;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.profile?.name ?? '');
    _customType = TextEditingController(text: widget.profile?.customType ?? '');
    _type = widget.profile?.instrumentType;
    final random = Random.secure();
    _requestId = List<int>.generate(
      16,
      (_) => random.nextInt(256),
    ).map((value) => value.toRadixString(16).padLeft(2, '0')).join();
  }

  @override
  void dispose() {
    _name.dispose();
    _customType.dispose();
    super.dispose();
  }

  bool get _dirty => widget.profile == null
      ? _type != null || _name.text.isNotEmpty || _customType.text.isNotEmpty
      : _name.text != widget.profile!.name;

  Future<void> requestBack() async {
    if (_saving) return;
    if (!_dirty) {
      widget.onBack();
      return;
    }
    final discard = await showMeloopConfirm(
      context,
      title: 'Bỏ thay đổi?',
      message: 'Nội dung chưa lưu trong form sẽ bị bỏ.',
      confirmLabel: 'Bỏ thay đổi',
      cancelLabel: 'Tiếp tục sửa',
      destructive: true,
    );
    if (discard && mounted) widget.onBack();
  }

  void _chooseType(InstrumentType type) {
    if (_saving || widget.profile != null) return;
    setState(() {
      _type = type;
      _typeError = null;
      _formError = null;
      if (_suggestedName) {
        final label = type == InstrumentType.other
            ? _customType.text.trim()
            : type.label;
        _name.text = label.isEmpty ? 'Nhạc cụ của tôi' : '$label của tôi';
      }
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _nameError = null;
      _typeError = null;
      _formError = null;
    });
    final type = _type;
    if (widget.profile == null && type == null) {
      setState(() => _typeError = 'Vui lòng chọn nhạc cụ.');
    }
    if (!_formKey.currentState!.validate() || type == null) return;
    setState(() => _saving = true);
    try {
      final name = _name.text.trim();
      if (widget.profile == null) {
        await widget.onCreate(
          _requestId,
          name,
          type,
          type == InstrumentType.other ? _customType.text.trim() : '',
        );
      } else if (name == widget.profile!.name) {
        widget.onBack();
      } else {
        await widget.onRename(widget.profile!.id, name);
      }
    } on ProfileServiceException catch (error) {
      if (!mounted) return;
      setState(() {
        switch (error.code) {
          case ProfileServiceError.duplicateName:
            _nameError = 'Tên hồ sơ này đã được dùng. Hãy chọn tên khác.';
          case ProfileServiceError.invalidInput:
            _formError = 'Thông tin hồ sơ chưa hợp lệ. Vui lòng kiểm tra lại.';
          case ProfileServiceError.freeLimit:
            _formError = 'Miễn phí tối đa 3 hồ sơ nhạc cụ. Bạn vẫn có thể quản lý các hồ sơ hiện có.';
          case ProfileServiceError.missingProfile:
            _formError = 'Hồ sơ này không còn tồn tại. Hãy quay lại danh sách.';
          case ProfileServiceError.unfinishedSession:
            _formError = 'Hãy hoàn tất buổi luyện đang mở rồi thử lại.';
          case ProfileServiceError.storage || ProfileServiceError.unknown:
            _formError = 'Chưa thể lưu hồ sơ. Nội dung của bạn vẫn ở đây.';
        }
      });
      _formKey.currentState!.validate();
    } catch (_) {
      if (mounted) {
        setState(
          () => _formError = 'Chưa thể lưu hồ sơ. Nội dung của bạn vẫn ở đây.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.profile != null;
    return MeloopPage(
      topBar: MeloopTopBar(
        title: editing ? 'Sửa hồ sơ' : 'Nhạc cụ của bạn',
        onBack: requestBack,
      ),
      topBarGap: TempoSpace.lg,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    editing
                        ? 'Tên gọi của\nnhạc cụ này.'
                        : 'Bạn chơi nhạc cụ gì?',
                    style: TempoType.heading,
                  ),
                  const SizedBox(height: TempoSpace.sm),
                  Text(
                    editing
                        ? 'Bạn có thể đổi tên; loại nhạc cụ được giữ nguyên.'
                        : 'Chọn âm thanh thuộc về bạn.',
                    style: TempoType.body.copyWith(color: TempoColors.muted),
                  ),
                ],
              ),
            ),
            if (editing)
              _ReadOnlyInstrument(profile: widget.profile!)
            else ...[
              LayoutBuilder(
                builder: (context, constraints) {
                  final tileWidth = (constraints.maxWidth - 11) / 2;
                  return Wrap(
                    spacing: 11,
                    runSpacing: 11,
                    children: [
                      for (final type in InstrumentType.values.take(6))
                        SizedBox(
                          width: tileWidth,
                          child: _InstrumentChoice(
                            type: type,
                            selected: _type == type,
                            onTap: () => _chooseType(type),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: TempoSpace.md),
              InkWell(
                key: const Key('profile-type-other'),
                borderRadius: BorderRadius.circular(TempoRadius.card),
                onTap: () => _chooseType(InstrumentType.other),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(
                    minHeight: TempoSize.touchTarget,
                  ),
                  padding: const EdgeInsets.all(TempoSpace.lg),
                  decoration: BoxDecoration(
                    color: _type == InstrumentType.other
                        ? TempoColors.selection
                        : TempoColors.paper,
                    border: Border.all(
                      color: _type == InstrumentType.other
                          ? TempoColors.teal
                          : TempoColors.line,
                      width: _type == InstrumentType.other ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      const MeloopIcon(MeloopIcons.music),
                      const SizedBox(width: TempoSpace.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Khác', style: TempoType.label),
                            Text(
                              'Nhạc cụ mang âm sắc của riêng bạn',
                              style: TempoType.caption.copyWith(
                                color: TempoColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_typeError != null) ...[
                const SizedBox(height: TempoSpace.sm),
                MeloopNotice(
                  message: _typeError!,
                  kind: MeloopNoticeKind.error,
                ),
              ],
              if (_type == InstrumentType.other) ...[
                const SizedBox(height: TempoSpace.lg),
                MeloopField(
                  label: 'Tên nhạc cụ',
                  requirement: MeloopFieldRequirement.required,
                  controller: _customType,
                  hint: 'Ví dụ: Saxophone',
                  validator: MeloopValidation.customInstrument,
                  onChanged: (value) {
                    if (_suggestedName) {
                      final label = value.trim();
                      _name.text = label.isEmpty
                          ? 'Nhạc cụ của tôi'
                          : '$label của tôi';
                    }
                  },
                  enabled: !_saving,
                ),
              ],
            ],
            const SizedBox(height: TempoSpace.lg),
            MeloopField(
              label: 'Tên hồ sơ',
              requirement: MeloopFieldRequirement.required,
              controller: _name,
              validator: (value) =>
                  _nameError ?? MeloopValidation.profileName(value),
              onChanged: (_) {
                _suggestedName = false;
                if (_nameError != null || _formError != null) {
                  setState(() {
                    _nameError = null;
                    _formError = null;
                  });
                }
              },
              enabled: !_saving,
            ),
            if (_formError != null) ...[
              const SizedBox(height: TempoSpace.md),
              MeloopNotice(message: _formError!, kind: MeloopNoticeKind.error),
            ],
            const SizedBox(height: TempoSpace.xl),
            MeloopButton(
              key: const Key('save-profile'),
              label: editing ? 'Lưu thay đổi' : 'Tạo hồ sơ',
              icon: MeloopIcons.check,
              isLoading: _saving,
              onPressed: _save,
            ),
            const SizedBox(height: TempoSpace.md),
            Text(
              editing
                  ? 'Nhật ký và loại nhạc cụ của hồ sơ được giữ nguyên.'
                  : 'Có thể đổi tên sau. Không cần đăng nhập.',
              textAlign: TextAlign.center,
              style: TempoType.caption.copyWith(color: TempoColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadOnlyInstrument extends StatelessWidget {
  const _ReadOnlyInstrument({required this.profile});
  final InstrumentProfile profile;

  @override
  Widget build(BuildContext context) => MeloopCard(
    color: TempoColors.soft,
    child: Row(
      children: [
        MeloopArt.instrument(
          MeloopInstrument.values[profile.instrumentType.index],
          size: 70,
        ),
        const SizedBox(width: TempoSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Loại nhạc cụ', style: TempoType.caption),
              Text(profile.instrumentLabel, style: TempoType.title),
            ],
          ),
        ),
      ],
    ),
  );
}

class _InstrumentChoice extends StatelessWidget {
  const _InstrumentChoice({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final InstrumentType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: type.label,
    child: InkWell(
      key: Key('profile-type-${type.name}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(TempoRadius.action),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: selected ? TempoColors.selection : const Color(0xFFF6F2E5),
          border: Border.all(
            color: selected ? TempoColors.teal : TempoColors.line,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(TempoRadius.action),
        ),
        child: Column(
          children: [
            MeloopArt.instrument(
              MeloopInstrument.values[type.index],
              size: 118,
            ),
            Text(type.label, style: TempoType.label),
          ],
        ),
      ),
    ),
  );
}
