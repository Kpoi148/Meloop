import 'package:flutter/material.dart';

import '../../theme/tokens/tempo_tokens.dart';

enum MeloopInputType { text, multiline, integer, decimal, email, phone }

enum MeloopFieldRequirement { required, optional }

class MeloopFieldLabel extends StatelessWidget {
  const MeloopFieldLabel({
    super.key,
    required this.label,
    required this.requirement,
  });
  final String label;
  final MeloopFieldRequirement requirement;

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: [
        TextSpan(text: label, style: TempoType.label),
        TextSpan(
          text: requirement == MeloopFieldRequirement.required
              ? ' *'
              : ' (tùy chọn)',
          style: TempoType.caption.copyWith(
            color: requirement == MeloopFieldRequirement.required
                ? TempoColors.error
                : TempoColors.muted,
          ),
        ),
      ],
    ),
    semanticsLabel:
        '$label, ${requirement == MeloopFieldRequirement.required ? 'bắt buộc' : 'tùy chọn'}',
  );
}

class MeloopField extends StatelessWidget {
  const MeloopField({
    super.key,
    required this.label,
    required this.controller,
    this.requirement = MeloopFieldRequirement.optional,
    this.type = MeloopInputType.text,
    this.hint,
    this.helper,
    this.validator,
    this.enabled = true,
    this.onChanged,
    this.focusNode,
    this.textInputAction,
    this.onFieldSubmitted,
  });
  final String label;
  final TextEditingController controller;
  final MeloopFieldRequirement requirement;
  final MeloopInputType type;
  final String? hint;
  final String? helper;
  final FormFieldValidator<String>? validator;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      MeloopFieldLabel(label: label, requirement: requirement),
      const SizedBox(height: TempoSpace.sm),
      TextFormField(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        style: TempoType.body,
        keyboardType: switch (type) {
          MeloopInputType.text => TextInputType.text,
          MeloopInputType.multiline => TextInputType.multiline,
          MeloopInputType.integer => TextInputType.number,
          MeloopInputType.decimal => const TextInputType.numberWithOptions(
            decimal: true,
          ),
          MeloopInputType.email => TextInputType.emailAddress,
          MeloopInputType.phone => TextInputType.phone,
        },
        textInputAction:
            textInputAction ??
            (type == MeloopInputType.multiline
                ? TextInputAction.newline
                : TextInputAction.next),
        minLines: type == MeloopInputType.multiline ? 3 : 1,
        maxLines: type == MeloopInputType.multiline ? null : 1,
        autocorrect:
            type == MeloopInputType.text || type == MeloopInputType.multiline,
        enableSuggestions:
            type == MeloopInputType.text || type == MeloopInputType.multiline,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (value) {
          if (requirement == MeloopFieldRequirement.required &&
              (value ?? '').trim().isEmpty) {
            return 'Vui lòng nhập ${label.toLowerCase()}.';
          }
          return validator?.call(value);
        },
        // A wrapped error widget has no line limit and grows with text scale.
        errorBuilder: (context, error) => Semantics(
          liveRegion: true,
          child: Text(
            error,
            style: TempoType.caption.copyWith(color: TempoColors.error),
          ),
        ),
        scrollPadding: const EdgeInsets.all(TempoSpace.xl),
        decoration: InputDecoration(hintText: hint),
        onChanged: onChanged,
        onFieldSubmitted: onFieldSubmitted,
      ),
      if (helper != null) ...[
        const SizedBox(height: TempoSpace.xs),
        Text(
          helper!,
          style: TempoType.caption.copyWith(color: TempoColors.muted),
        ),
      ],
    ],
  );
}
