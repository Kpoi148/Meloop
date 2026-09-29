import 'package:flutter/material.dart';

import '../../theme/tokens/tempo_tokens.dart';
import '../layout/meloop_icon.dart';
import 'meloop_field.dart';

class MeloopDateField extends StatelessWidget {
  const MeloopDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final bool enabled;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      MeloopFieldLabel(
        label: label,
        requirement: MeloopFieldRequirement.required,
      ),
      const SizedBox(height: TempoSpace.sm),
      FormField<DateTime>(
        initialValue: DateUtils.dateOnly(value),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (_) {
          final day = DateUtils.dateOnly(value);
          return day.isBefore(DateTime(2000)) ||
                  day.isAfter(DateUtils.dateOnly(DateTime.now()))
              ? 'Chọn ngày từ 01/01/2000 đến hôm nay.'
              : null;
        },
        builder: (field) => InkWell(
          onTap: !enabled
              ? null
              : () async {
                  final today = DateUtils.dateOnly(DateTime.now());
                  final first = DateTime(2000);
                  final current = DateUtils.dateOnly(value);
                  final selected = await showDatePicker(
                    context: context,
                    initialDate: current.isBefore(first)
                        ? first
                        : current.isAfter(today)
                        ? today
                        : current,
                    firstDate: first,
                    lastDate: today,
                    initialEntryMode: DatePickerEntryMode.calendarOnly,
                  );
                  if (selected != null && context.mounted) {
                    field.didChange(selected);
                    onChanged(selected);
                  }
                },
          borderRadius: BorderRadius.circular(TempoRadius.field),
          child: InputDecorator(
            decoration: InputDecoration(
              enabled: enabled,
              error: field.hasError
                  ? Text(
                      field.errorText!,
                      style: TempoType.caption.copyWith(
                        color: TempoColors.error,
                      ),
                    )
                  : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    MaterialLocalizations.of(context).formatMediumDate(value),
                  ),
                ),
                const MeloopIcon(MeloopIcons.down, size: TempoSize.smallIcon),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}
