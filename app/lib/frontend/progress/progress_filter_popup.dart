import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n.dart';
import '../../shared/journal/practice_date.dart';
import '../application/startup_controller.dart';
import '../components/meloop_ui.dart';
import '../showcase/preview_copy.dart';
import 'progress_filter_header.dart';
import 'progress_filter_options.dart';
import 'progress_filter_tokens.dart';
import 'progress_range_calendar.dart';
import 'progress_tokens.dart';

Future<DateTimeRange?> showProgressFilter(
  BuildContext context, {
  required PreviewInstrumentProfile profile,
  required DateTime today,
  required DateTimeRange initialRange,
}) => showDialog<DateTimeRange>(
  context: context,
  builder: (context) => _progressDialog(
    context,
    ProgressFilterPopup(
      profile: profile,
      today: today,
      initialRange: initialRange,
    ),
  ),
);

Widget _progressDialog(BuildContext context, Widget child) => Dialog(
  key: const Key('progress-filter-popup'),
  backgroundColor: TempoColors.paper,
  surfaceTintColor: TempoColors.paper,
  insetPadding: ProgressFilterTokens.popupInsetPadding,
  constraints: const BoxConstraints(maxWidth: TempoSize.contentMaxWidth),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(TempoRadius.button),
  ),
  clipBehavior: Clip.antiAlias,
  child: ConstrainedBox(
    constraints: BoxConstraints(
      maxHeight:
          MediaQuery.sizeOf(context).height *
          ProgressFilterTokens.popupHeightFraction,
    ),
    child: child,
  ),
);

class ProgressFilterPopup extends StatefulWidget {
  const ProgressFilterPopup({
    super.key,
    required this.profile,
    required this.today,
    required this.initialRange,
  });
  final PreviewInstrumentProfile profile;
  final DateTime today;
  final DateTimeRange initialRange;
  @override
  State<ProgressFilterPopup> createState() => _ProgressFilterPopupState();
}

class _ProgressFilterPopupState extends State<ProgressFilterPopup> {
  late DateTimeRange _range = widget.initialRange;
  late DateTime _month = DateTime(_range.end.year, _range.end.month);
  final _earliest = DateTime.parse(PracticeDate.earliest);
  late ProgressFilterPreset _preset = ProgressFilterPreset.matching(
    _range,
    widget.today,
    _earliest,
  );
  bool _editingStart = true;

  void _choosePreset(ProgressFilterPreset preset) => setState(() {
    _preset = preset;
    final next = preset.range(widget.today, _earliest);
    if (next != null) {
      _range = next;
      _month = DateTime(next.end.year, next.end.month);
    }
    _editingStart = true;
  });

  void _chooseDay(DateTime date) => setState(() {
    _preset = ProgressFilterPreset.custom;
    _range = _editingStart
        ? DateTimeRange(
            start: date,
            end: _range.end.isBefore(date) ? date : _range.end,
          )
        : DateTimeRange(
            start: _range.start.isAfter(date) ? date : _range.start,
            end: date,
          );
    _editingStart = !_editingStart;
  });

  void _editBoundary(bool start) => setState(() {
    _editingStart = start;
    _preset = ProgressFilterPreset.custom;
    final date = start ? _range.start : _range.end;
    _month = DateTime(date.year, date.month);
  });

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: SingleChildScrollView(
            padding: ProgressFilterTokens.scrollPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProgressFilterHeader(title: strings.progressFilterTitle),
                Row(
                  children: [
                    const MeloopIcon(
                      MeloopIcons.chart,
                      size: TempoSize.smallIcon,
                    ),
                    const SizedBox(width: TempoSpace.md),
                    Expanded(
                      child: Text(
                        profileDisplayName(strings, widget.profile),
                        style: ProgressFilterTokens.profile,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: TempoSpace.sm),
                Wrap(
                  spacing: TempoSpace.sm,
                  runSpacing: TempoSpace.sm,
                  children: [
                    for (final preset in ProgressFilterPreset.values)
                      ChoiceChip(
                        key: ValueKey('progress-preset-${preset.name}'),
                        label: Text(preset.label(strings)),
                        selected: _preset == preset,
                        showCheckmark: false,
                        padding: ProgressFilterTokens.presetPadding,
                        labelPadding: ProgressFilterTokens.presetLabelPadding,
                        backgroundColor: TempoColors.fieldFill,
                        selectedColor: TempoColors.teal,
                        labelStyle: TempoType.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _preset == preset
                              ? TempoColors.white
                              : TempoColors.ink,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(TempoRadius.chip),
                          side: BorderSide(
                            color: _preset == preset
                                ? TempoColors.teal
                                : TempoColors.line,
                          ),
                        ),
                        onSelected: (_) => _choosePreset(preset),
                      ),
                  ],
                ),
                const SizedBox(height: TempoSpace.md),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final fields = [
                      _ProgressDateBoundary(
                        key: const Key('progress-range-start'),
                        label: strings.progressFilterFrom,
                        value: _range.start,
                        active: _editingStart,
                        onPressed: () => _editBoundary(true),
                      ),
                      _ProgressDateBoundary(
                        key: const Key('progress-range-end'),
                        label: strings.progressFilterTo,
                        value: _range.end,
                        active: !_editingStart,
                        onPressed: () => _editBoundary(false),
                      ),
                    ];
                    return MediaQuery.textScalerOf(context).scale(16) / 16 >
                            ProgressTokens.largeTextThreshold
                        ? Column(spacing: TempoSpace.sm, children: fields)
                        : Row(
                            spacing: TempoSpace.sm,
                            children: fields
                                .map((field) => Expanded(child: field))
                                .toList(),
                          );
                  },
                ),
                if (_preset == ProgressFilterPreset.custom) ...[
                  const SizedBox(height: TempoSpace.md),
                  ProgressRangeCalendar(
                    month: _month,
                    range: _range,
                    firstDate: _earliest,
                    lastDate: DateUtils.dateOnly(widget.today),
                    onDay: _chooseDay,
                    onMonth: (delta) => setState(
                      () =>
                          _month = DateTime(_month.year, _month.month + delta),
                    ),
                  ),
                  const SizedBox(height: TempoSpace.sm),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _editingStart
                          ? strings.progressFilterPickStart
                          : strings.progressFilterPickEnd,
                      style: ProgressFilterTokens.footerNote,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: ProgressFilterTokens.footerPadding,
          decoration: const BoxDecoration(
            color: TempoColors.paper,
            border: Border(top: BorderSide(color: TempoColors.line)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                strings.progressFilterSelectedDays(
                  progressRangeDayCount(_range),
                ),
                key: const Key('progress-filter-day-count'),
                style: ProgressFilterTokens.footerNote,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: TempoSpace.sm),
              MeloopButton(
                key: const Key('progress-filter-apply'),
                label: strings.progressApplyRange,
                icon: MeloopIcons.chart,
                style: MeloopButtonStyle.yellow,
                onPressed: () => Navigator.of(context).pop(_range),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProgressDateBoundary extends StatelessWidget {
  const _ProgressDateBoundary({
    super.key,
    required this.label,
    required this.value,
    required this.active,
    required this.onPressed,
  });
  final String label;
  final DateTime value;
  final bool active;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: active,
    child: Material(
      color: active ? TempoColors.selection : TempoColors.fieldFill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TempoRadius.field),
        side: BorderSide(color: active ? TempoColors.teal : TempoColors.line),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(TempoRadius.field),
        child: Padding(
          padding: const EdgeInsets.all(TempoSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(label, style: ProgressFilterTokens.dateLabel),
                  ),
                  const SizedBox(width: TempoSpace.xs),
                  const MeloopIcon(MeloopIcons.edit, size: TempoSize.smallIcon),
                ],
              ),
              const SizedBox(height: TempoSpace.xs),
              Text(
                DateFormat.yMd(context.l10n.localeName).format(value),
                style: ProgressFilterTokens.dateValue,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> showProgressProAccess(
  BuildContext context, {
  VoidCallback? onViewPro,
}) async {
  final explore = await showDialog<bool>(
    context: context,
    builder: (context) => _progressDialog(
      context,
      SingleChildScrollView(
        padding: const EdgeInsets.all(TempoSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProgressFilterHeader(
              title: context.l10n.progressFilterProTitle,
              subtitle: context.l10n.progressFilterProMessage,
            ),
            MeloopButton(
              key: const Key('progress-filter-upgrade'),
              label: context.l10n.progressFilterExplorePro,
              style: MeloopButtonStyle.yellow,
              icon: MeloopIcons.star,
              onPressed: onViewPro == null
                  ? null
                  : () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ),
    ),
  );
  if (explore == true && context.mounted) onViewPro?.call();
}
