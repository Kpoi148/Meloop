import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../components/meloop_ui.dart';
import 'practice_session_form_tokens.dart';

/// The shared save/edit composition from Tempo's session form.
class PracticeSessionFormFields extends StatelessWidget {
  const PracticeSessionFormFields({
    super.key,
    required this.heading,
    required this.title,
    required this.minutes,
    required this.practiced,
    required this.difficulty,
    required this.next,
    required this.bpm,
    required this.date,
    required this.onDate,
    required this.onMood,
    required this.onFocus,
    required this.titleFocus,
    this.minimumMinutes = PracticeSessionFormLimits.minimumNewMinutes,
    this.mood,
    this.focus,
    this.saving = false,
    this.error,
    this.durationError,
  });
  final TextEditingController title, minutes, practiced, difficulty, next, bpm;
  final String heading;
  final int minimumMinutes;
  final FocusNode titleFocus;
  final DateTime date;
  final int? mood, focus;
  final ValueChanged<DateTime> onDate;
  final ValueChanged<int?> onMood, onFocus;
  final bool saving;
  final String? error, durationError;

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: PracticeSessionFormTokens.introInset,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final showArt = _introArtFits(context, constraints.maxWidth);
              return ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: showArt
                      ? PracticeSessionFormTokens.introHeight
                      : 0,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (showArt)
                      const Positioned(
                        right: PracticeSessionFormTokens.artRight,
                        top: PracticeSessionFormTokens.artTop,
                        child: Opacity(
                          opacity: PracticeSessionFormTokens.artOpacity,
                          child: MeloopArt.scene(
                            MeloopScene.journal,
                            size: PracticeSessionFormTokens.artSize,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(
                        top: PracticeSessionFormTokens.headingTop,
                      ),
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: showArt
                              ? PracticeSessionFormTokens.artSize +
                                    PracticeSessionFormTokens.artRight
                              : 0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              heading,
                              style: PracticeSessionFormTokens.heading,
                            ),
                            const SizedBox(
                              height: PracticeSessionFormTokens.subtitleGap,
                            ),
                            Text(
                              strings.sessionFormSubtitle,
                              style: PracticeSessionFormTokens.subtitle,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        _field(
          context,
          strings.sessionTitle,
          title,
          focusNode: titleFocus,
          validator: (value) => MeloopValidation.titleFor(value, strings),
          hint: strings.sessionFormTitleHint,
          bottom: PracticeSessionFormTokens.dateRowGap,
        ),
        MeloopResponsiveRow(
          children: [
            MeloopDateField(
              label: strings.practiceDate,
              value: date,
              enabled: !saving,
              onChanged: onDate,
              compact: true,
            ),
            _field(
              context,
              strings.sessionDurationMinutes,
              minutes,
              required: true,
              integer: true,
              bottom: 0,
              validator: (value) => MeloopValidation.integer(
                value,
                label: strings.sessionDurationMinutes,
                min: minimumMinutes,
                max: PracticeSessionFormLimits.maximumMinutes,
                strings: strings,
              ),
            ),
          ],
        ),
        if (durationError != null)
          Text(
            durationError!,
            style: TempoType.caption.copyWith(color: TempoColors.error),
          ),
        const SizedBox(height: PracticeSessionFormTokens.dateRowGap),
        MeloopRating(
          label: strings.mood,
          initialValue: mood,
          onChanged: onMood,
          enabled: !saving,
          compact: true,
        ),
        const SizedBox(height: PracticeSessionFormTokens.fieldGap),
        MeloopRating(
          label: strings.focusLevel,
          initialValue: focus,
          onChanged: onFocus,
          enabled: !saving,
          mood: false,
          compact: true,
        ),
        const Divider(height: PracticeSessionFormTokens.dividerGap),
        _field(
          context,
          strings.practicedWhat,
          practiced,
          multiline: true,
          hint: strings.practicedHint,
          validator: (value) => MeloopValidation.noteFor(value, strings),
        ),
        _field(
          context,
          strings.difficulty,
          difficulty,
          multiline: true,
          hint: strings.difficultyHint,
          validator: (value) => MeloopValidation.noteFor(value, strings),
        ),
        _field(
          context,
          strings.nextPractice,
          next,
          multiline: true,
          hint: strings.nextPracticeHint,
          validator: (value) => MeloopValidation.noteFor(value, strings),
        ),
        _field(
          context,
          strings.sessionPracticeBpm,
          bpm,
          integer: true,
          hint: strings.notRequired,
          validator: (value) => (value ?? '').trim().isEmpty
              ? null
              : MeloopValidation.integer(
                  value,
                  label: strings.sessionPracticeBpm,
                  min: PracticeSessionFormLimits.minimumBpm,
                  max: PracticeSessionFormLimits.maximumBpm,
                  strings: strings,
                ),
        ),
        if (error != null)
          MeloopNotice(message: error!, kind: MeloopNoticeKind.error),
      ],
    );
  }

  bool _introArtFits(BuildContext context, double width) {
    final painter = TextPainter(
      text: TextSpan(text: heading, style: PracticeSessionFormTokens.heading),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final available =
        width -
        PracticeSessionFormTokens.artSize -
        PracticeSessionFormTokens.artRight;
    final fits = painter.width <= available;
    painter.dispose();
    return fits;
  }

  Widget _field(
    BuildContext context,
    String label,
    TextEditingController controller, {
    bool required = false,
    bool integer = false,
    bool multiline = false,
    String? hint,
    FormFieldValidator<String>? validator,
    FocusNode? focusNode,
    double bottom = PracticeSessionFormTokens.fieldGap,
  }) => Padding(
    padding: EdgeInsets.only(bottom: bottom),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          required ? '$label${context.l10n.requiredSuffix}' : label,
          style: PracticeSessionFormTokens.label,
        ),
        const SizedBox(height: PracticeSessionFormTokens.labelGap),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          enabled: !saving,
          style: multiline
              ? PracticeSessionFormTokens.note
              : PracticeSessionFormTokens.input,
          minLines: multiline ? 4 : 1,
          maxLines: multiline ? null : 1,
          keyboardType: multiline
              ? TextInputType.multiline
              : integer
              ? TextInputType.number
              : TextInputType.text,
          textInputAction: multiline
              ? TextInputAction.newline
              : TextInputAction.next,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(hintText: hint),
          errorBuilder: (_, message) => Text(
            message,
            style: TempoType.caption.copyWith(color: TempoColors.error),
          ),
        ),
      ],
    ),
  );
}
