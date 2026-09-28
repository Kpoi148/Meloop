import 'package:flutter/material.dart';

import '../../theme/tokens/tempo_tokens.dart';
import '../inputs/meloop_field.dart';
import '../layout/meloop_icon.dart';

class MeloopChoice<T> {
  const MeloopChoice({required this.value, required this.label, this.leading});
  final T value;
  final String label;
  final Widget? leading;
}

/// Wrapping chip/radio group. Also used for tabs, bounded values and ratings.
class MeloopChoiceGroup<T> extends FormField<T> {
  MeloopChoiceGroup({
    super.key,
    required String label,
    required List<MeloopChoice<T>> choices,
    required ValueChanged<T?> onChanged,
    super.initialValue,
    MeloopFieldRequirement requirement = MeloopFieldRequirement.optional,
    bool clearable = false,
    super.enabled = true,
    FormFieldValidator<T>? validator,
  }) : super(
         validator: (value) =>
             requirement == MeloopFieldRequirement.required && value == null
             ? 'Vui lòng chọn ${label.toLowerCase()}.'
             : validator?.call(value),
         autovalidateMode: AutovalidateMode.onUserInteraction,
         builder: (field) => Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             MeloopFieldLabel(label: label, requirement: requirement),
             const SizedBox(height: TempoSpace.sm),
             LayoutBuilder(
               builder: (context, constraints) => Wrap(
                 spacing: 7,
                 runSpacing: 7,
                 children: [
                   for (final choice in choices)
                     Semantics(
                       selected: field.value == choice.value,
                       inMutuallyExclusiveGroup: true,
                       child: ChoiceChip(
                         showCheckmark: false,
                         selected: field.value == choice.value,
                         backgroundColor: TempoColors.fieldFill,
                         selectedColor: TempoColors.teal,
                         labelStyle: TempoType.caption.copyWith(
                           color: field.value == choice.value
                               ? TempoColors.white
                               : TempoColors.ink,
                           fontSize: 13,
                         ),
                         shape: RoundedRectangleBorder(
                           borderRadius: BorderRadius.circular(
                             TempoRadius.chip,
                           ),
                           side: const BorderSide(color: TempoColors.line),
                         ),
                         label: ConstrainedBox(
                           constraints: BoxConstraints(
                             maxWidth: (constraints.maxWidth - 40).clamp(
                               0,
                               double.infinity,
                             ),
                           ),
                           child: Text(choice.label),
                         ),
                         avatar: choice.leading,
                         onSelected: field.widget.enabled
                             ? (_) {
                                 final next =
                                     clearable && field.value == choice.value
                                     ? null
                                     : choice.value;
                                 field.didChange(next);
                                 onChanged(next);
                               }
                             : null,
                       ),
                     ),
                 ],
               ),
             ),
             if (field.hasError)
               Padding(
                 padding: const EdgeInsets.only(top: TempoSpace.sm),
                 child: Semantics(
                   liveRegion: true,
                   child: Text(
                     field.errorText!,
                     style: TempoType.caption.copyWith(
                       color: TempoColors.error,
                     ),
                   ),
                 ),
               ),
           ],
         ),
       );
}

class MeloopSelect<T> extends StatelessWidget {
  const MeloopSelect({
    super.key,
    required this.label,
    required this.choices,
    required this.onChanged,
    this.initialValue,
    this.validator,
    this.enabled = true,
    this.requirement = MeloopFieldRequirement.optional,
  });
  final String label;
  final List<MeloopChoice<T>> choices;
  final ValueChanged<T?> onChanged;
  final T? initialValue;
  final FormFieldValidator<T>? validator;
  final bool enabled;
  final MeloopFieldRequirement requirement;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      MeloopFieldLabel(label: label, requirement: requirement),
      const SizedBox(height: TempoSpace.sm),
      DropdownButtonFormField<T>(
        initialValue: initialValue,
        isExpanded: true,
        itemHeight: null,
        icon: const MeloopIcon(MeloopIcons.down, size: TempoSize.smallIcon),
        items: choices
            .map(
              (choice) => DropdownMenuItem(
                value: choice.value,
                child: Text(choice.label),
              ),
            )
            .toList(),
        onChanged: enabled ? onChanged : null,
        validator: (value) =>
            requirement == MeloopFieldRequirement.required && value == null
            ? 'Vui lòng chọn ${label.toLowerCase()}.'
            : validator?.call(value),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        errorBuilder: (context, error) => Semantics(
          liveRegion: true,
          child: Text(
            error,
            style: TempoType.caption.copyWith(color: TempoColors.error),
          ),
        ),
      ),
    ],
  );
}

class MeloopToggle extends StatelessWidget {
  const MeloopToggle({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.description,
    this.checkbox = false,
  });
  final String label;
  final String? description;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool checkbox;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TempoType.label),
            if (description != null)
              Text(
                description!,
                style: TempoType.caption.copyWith(color: TempoColors.muted),
              ),
          ],
        ),
      ),
      const SizedBox(width: TempoSpace.sm),
      Semantics(
        label: label,
        child: checkbox
            ? Checkbox(
                value: value,
                onChanged: onChanged == null
                    ? null
                    : (v) => onChanged!(v ?? false),
              )
            : Switch(
                value: value,
                onChanged: onChanged,
                activeTrackColor: TempoColors.teal,
              ),
      ),
    ],
  );
}
