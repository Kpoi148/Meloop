import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../shared/journal/journal_text.dart';
import '../components/meloop_ui.dart';
import 'practice_session_form_tokens.dart';

/// The shared save/edit composition from Tempo's session form.
class PracticeSessionFormFields extends StatelessWidget {
  const PracticeSessionFormFields({
    super.key,
    required this.heading,
    required this.title,
    required this.minutes,
    required this.hours,
    required this.seconds,
    required this.practiced,
    required this.difficulty,
    required this.next,
    required this.bpm,
    required this.date,
    required this.onDate,
    required this.onMood,
    required this.onFocus,
    required this.titleFocus,
    this.instrumentName,
    this.onRetry,
    this.mood,
    this.focus,
    this.saving = false,
    this.error,
    this.durationError,
  });
  final TextEditingController title,
      hours,
      minutes,
      seconds,
      practiced,
      difficulty,
      next,
      bpm;
  final String heading;
  final String? instrumentName;
  final VoidCallback? onRetry;
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
          required: true,
          codePointLimit: PracticeRules.titleMaxCodePoints,
          focusNode: titleFocus,
          validator: (value) => MeloopValidation.titleFor(value, strings),
          hint: strings.sessionFormTitleHint,
          bottom: PracticeSessionFormTokens.dateRowGap,
        ),
        if (instrumentName != null) ...[
          Text(
            '${strings.instrumentLabel}: $instrumentName',
            style: PracticeSessionFormTokens.label,
          ),
          const SizedBox(height: PracticeSessionFormTokens.fieldGap),
        ],
        MeloopDateField(
          label: strings.practiceDate,
          value: date,
          enabled: !saving,
          onChanged: onDate,
          compact: true,
        ),
        const SizedBox(height: PracticeSessionFormTokens.dateRowGap),
        Text(
          '${strings.sessionDuration}${strings.requiredSuffix}',
          style: PracticeSessionFormTokens.label,
        ),
        const SizedBox(height: PracticeSessionFormTokens.labelGap),
        MeloopResponsiveRow(
          children: [
            _durationPart(
              context,
              strings.hours,
              hours,
              PracticeSessionFormLimits.maximumHours,
              const Key('session-duration-hours'),
            ),
            _durationPart(
              context,
              strings.minutes,
              minutes,
              PracticeSessionFormLimits.maximumMinuteSecond,
              const Key('session-duration-minutes'),
            ),
            _durationPart(
              context,
              strings.seconds,
              seconds,
              PracticeSessionFormLimits.maximumMinuteSecond,
              const Key('session-duration-seconds'),
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
          codePointLimit: PracticeRules.noteMaxCodePoints,
          hint: strings.practicedHint,
          validator: (value) => MeloopValidation.noteFor(value, strings),
        ),
        _field(
          context,
          strings.difficulty,
          difficulty,
          multiline: true,
          codePointLimit: PracticeRules.noteMaxCodePoints,
          hint: strings.difficultyHint,
          validator: (value) => MeloopValidation.noteFor(value, strings),
        ),
        _field(
          context,
          strings.nextPractice,
          next,
          multiline: true,
          codePointLimit: PracticeRules.noteMaxCodePoints,
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
        if (error != null && onRetry != null)
          MeloopButton(
            label: strings.retry,
            onPressed: onRetry,
            isLoading: saving,
          ),
      ],
    );
  }

  Widget _durationPart(
    BuildContext context,
    String label,
    TextEditingController controller,
    int max,
    Key inputKey,
  ) => _field(
    context,
    label,
    controller,
    inputKey: inputKey,
    required: true,
    integer: true,
    bottom: 0,
    validator: (value) => MeloopValidation.integer(
      value,
      label: label,
      min: PracticeSessionFormLimits.minimumComponent,
      max: max,
      strings: context.l10n,
    ),
  );

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
    int? codePointLimit,
    Key? inputKey,
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
          required
              ? '$label${context.l10n.requiredSuffix}'
              : '$label${context.l10n.sessionOptionalSuffix}',
          style: PracticeSessionFormTokens.label,
        ),
        const SizedBox(height: PracticeSessionFormTokens.labelGap),
        TextFormField(
          key: inputKey,
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
        if (codePointLimit != null)
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, value, _) => Text(
              '${value.text.runes.length}/$codePointLimit',
              textAlign: TextAlign.end,
              style: TempoType.caption.copyWith(color: TempoColors.muted),
            ),
          ),
      ],
    ),
  );
}
