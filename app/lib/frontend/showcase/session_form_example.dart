import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/session_form_controller.dart';
import '../application/session_form_values.dart';
import '../components/meloop_ui.dart';

export '../application/session_form_values.dart';

class SessionFormExample extends ConsumerStatefulWidget {
  const SessionFormExample({
    super.key,
    this.onSave,
    this.initialTitle = '',
    this.initialDurationSeconds = 60,
  });
  final SessionFormSave? onSave;
  final String initialTitle;
  final int initialDurationSeconds;
  @override
  ConsumerState<SessionFormExample> createState() => _SessionFormExampleState();
}

class _SessionFormExampleState extends ConsumerState<SessionFormExample> {
  final _saveId = Object();
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.initialTitle);
  late final _hours = TextEditingController(
    text: '${widget.initialDurationSeconds ~/ 3600}',
  );
  late final _minutes = TextEditingController(
    text: '${widget.initialDurationSeconds % 3600 ~/ 60}',
  );
  late final _seconds = TextEditingController(
    text: '${widget.initialDurationSeconds % 60}',
  );
  final _practiced = TextEditingController();
  final _difficulty = TextEditingController();
  final _next = TextEditingController();
  final _titleFocus = FocusNode();
  DateTime _date = DateUtils.dateOnly(DateTime.now());
  int? _mood, _focus;
  String? _durationError;
  bool _confirmingBack = false;

  bool get _saving =>
      ref.read(sessionFormControllerProvider(_saveId)).isLoading;

  bool get _dirty =>
      _title.text != widget.initialTitle ||
      _practiced.text.isNotEmpty ||
      _difficulty.text.isNotEmpty ||
      _next.text.isNotEmpty ||
      _mood != null ||
      _focus != null ||
      _date != DateUtils.dateOnly(DateTime.now()) ||
      _hours.text != '${widget.initialDurationSeconds ~/ 3600}' ||
      _minutes.text != '${widget.initialDurationSeconds % 3600 ~/ 60}' ||
      _seconds.text != '${widget.initialDurationSeconds % 60}';
  @override
  void dispose() {
    for (final controller in [
      _title,
      _hours,
      _minutes,
      _seconds,
      _practiced,
      _difficulty,
      _next,
    ]) {
      controller.dispose();
    }
    _titleFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final controller = ref.read(
      sessionFormControllerProvider(_saveId).notifier,
    );
    controller.clearError();
    final valid = _form.currentState!.validate();
    final h = int.tryParse(_hours.text.trim()),
        m = int.tryParse(_minutes.text.trim()),
        s = int.tryParse(_seconds.text.trim());
    final total = h == null || m == null || s == null
        ? 0
        : h * 3600 + m * 60 + s;
    setState(() {
      _durationError = total < 1 || total > 86400
          ? 'Thời lượng phải từ 1 giây đến 24 giờ.'
          : null;
    });
    if (!valid || _durationError != null) {
      if (MeloopValidation.title(_title.text) != null) {
        _titleFocus.requestFocus();
      }
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    final saved = await controller.save(
      SessionFormValues(
        title: _title.text.trim(),
        date: _date,
        durationSeconds: total,
        practiced: _practiced.text.trim().isEmpty ? '' : _practiced.text,
        difficulty: _difficulty.text.trim().isEmpty ? '' : _difficulty.text,
        next: _next.text.trim().isEmpty ? '' : _next.text,
        mood: _mood,
        focus: _focus,
      ),
      onSave: widget.onSave,
    );
    if (saved && mounted) Navigator.of(context).pop();
  }

  Future<void> _back() async {
    if (_saving || _confirmingBack) return;
    _confirmingBack = true;
    try {
      if (!_dirty ||
          await showMeloopConfirm(
            context,
            title: 'Bỏ thay đổi?',
            message: 'Những thay đổi chưa lưu sẽ bị bỏ.',
            confirmLabel: 'Bỏ thay đổi',
            cancelLabel: 'Tiếp tục sửa',
            destructive: true,
          )) {
        if (mounted) Navigator.of(context).pop();
      }
    } finally {
      _confirmingBack = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final saveState = ref.watch(sessionFormControllerProvider(_saveId));
    final saving = saveState.isLoading;
    final saveError = saveState.hasError
        ? 'Chưa thể lưu buổi luyện. Nội dung của bạn vẫn ở đây. Vui lòng thử lại.'
        : null;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_back());
      },
      child: MeloopPage(
        topBar: MeloopTopBar(
          title: 'Lưu buổi luyện',
          onBack: saving ? null : _back,
        ),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: TempoSpace.page,
            children: [
              const Text(
                'Một buổi luyện,\nmột bước tiến.',
                style: TempoType.heading,
              ),
              const Text('Ghi lại điều bạn muốn nhớ.'),
              MeloopField(
                label: 'Tên buổi luyện',
                controller: _title,
                focusNode: _titleFocus,
                requirement: MeloopFieldRequirement.required,
                hint: 'Ví dụ: Luyện gam C',
                validator: MeloopValidation.title,
                enabled: !saving,
              ),
              MeloopDateField(
                label: 'Ngày luyện',
                value: _date,
                enabled: !saving,
                onChanged: (date) => setState(() => _date = date),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MeloopResponsiveRow(
                    children: [
                      _durationField('Giờ', _hours, 24),
                      _durationField('Phút', _minutes, 59),
                      _durationField('Giây', _seconds, 59),
                    ],
                  ),
                  if (_durationError != null)
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        _durationError!,
                        style: TempoType.caption.copyWith(
                          color: TempoColors.error,
                        ),
                      ),
                    ),
                ],
              ),
              _rating(
                'Cảm xúc',
                _mood,
                (value) => setState(() => _mood = value),
              ),
              _rating(
                'Mức độ tập trung',
                _focus,
                (value) => setState(() => _focus = value),
              ),
              const Divider(),
              MeloopField(
                label: 'Bạn đã luyện gì?',
                controller: _practiced,
                type: MeloopInputType.multiline,
                hint: 'Gam, hợp âm, bài nhạc…',
                validator: MeloopValidation.note,
                enabled: !saving,
              ),
              MeloopField(
                label: 'Điều còn vướng',
                controller: _difficulty,
                type: MeloopInputType.multiline,
                hint: 'Một đoạn khó, một điều muốn cải thiện…',
                validator: MeloopValidation.note,
                enabled: !saving,
              ),
              MeloopField(
                label: 'Cho lần luyện tiếp',
                controller: _next,
                type: MeloopInputType.multiline,
                validator: MeloopValidation.note,
                enabled: !saving,
              ),
              if (saveError != null)
                MeloopNotice(message: saveError, kind: MeloopNoticeKind.error),
              MeloopButton(
                label: 'Lưu buổi luyện',
                icon: MeloopIcons.check,
                onPressed: _save,
                isLoading: saving,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _durationField(
    String label,
    TextEditingController controller,
    int max,
  ) => MeloopField(
    label: label,
    controller: controller,
    type: MeloopInputType.integer,
    requirement: MeloopFieldRequirement.required,
    enabled: !_saving,
    validator: (value) =>
        MeloopValidation.integer(value, label: label, min: 0, max: max),
  );
  Widget _rating(String label, int? value, ValueChanged<int?> onChanged) =>
      MeloopRating(
        label: label,
        initialValue: value,
        mood: label == 'Cảm xúc',
        enabled: !_saving,
        onChanged: onChanged,
      );
}
