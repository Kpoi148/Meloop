import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../components/meloop_ui.dart';
import 'practice_sessions_controller.dart';
import 'practice_sessions_tokens.dart';

Future<PracticeSessionFilters?> showPracticeSessionsFilters(
  BuildContext context, {
  required PracticeSessionFilters current,
}) => showMeloopSheet<PracticeSessionFilters>(
  context,
  title: context.l10n.practiceFilters,
  child: _SessionFilters(current: current),
);

class _SessionFilters extends StatefulWidget {
  const _SessionFilters({required this.current});

  final PracticeSessionFilters current;

  @override
  State<_SessionFilters> createState() => _SessionFiltersState();
}

class _SessionFiltersState extends State<_SessionFilters> {
  late PracticeSessionFilters _filters = widget.current;

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(strings.timeRange, style: TempoType.label),
        const SizedBox(height: TempoSpace.sm),
        _FilterChoices<PracticePeriod>(
          value: _filters.period,
          choices: [
            MeloopChoice(value: PracticePeriod.all, label: strings.all),
            MeloopChoice(value: PracticePeriod.week, label: strings.sevenDays),
            MeloopChoice(
              value: PracticePeriod.month,
              label: strings.thirtyDays,
            ),
          ],
          onChanged: (period) =>
              setState(() => _filters = _filters.copyWith(period: period)),
        ),
        const SizedBox(height: TempoSpace.xl),
        Text(strings.practiceSort, style: TempoType.label),
        const SizedBox(height: TempoSpace.sm),
        _FilterChoices<PracticeOrder>(
          value: _filters.order,
          choices: [
            MeloopChoice(
              value: PracticeOrder.newest,
              label: strings.practiceNewest,
            ),
            MeloopChoice(
              value: PracticeOrder.oldest,
              label: strings.practiceOldest,
            ),
          ],
          onChanged: (order) =>
              setState(() => _filters = _filters.copyWith(order: order)),
        ),
        const SizedBox(height: TempoSpace.xl),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: TempoSpace.md,
            children: [
              Expanded(
                child: MeloopButton(
                  label: strings.practiceApplyFilters,
                  onPressed: () => Navigator.of(context).pop(_filters),
                ),
              ),
              Expanded(
                child: MeloopButton(
                  label: strings.practiceClearFilters,
                  style: MeloopButtonStyle.outline,
                  onPressed: () =>
                      Navigator.of(context).pop(const PracticeSessionFilters()),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterChoices<T> extends StatelessWidget {
  const _FilterChoices({
    required this.value,
    required this.choices,
    required this.onChanged,
  });

  final T value;
  final List<MeloopChoice<T>> choices;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: PracticeSessionsTokens.filterChoiceGap,
    runSpacing: PracticeSessionsTokens.filterChoiceGap,
    children: [
      for (final choice in choices)
        MergeSemantics(
          child: Semantics(
            selected: value == choice.value,
            inMutuallyExclusiveGroup: true,
            child: TextButton(
              onPressed: () => onChanged(choice.value),
              style: TextButton.styleFrom(
                foregroundColor: value == choice.value
                    ? TempoColors.white
                    : TempoColors.ink,
                backgroundColor: value == choice.value
                    ? TempoColors.teal
                    : Colors.transparent,
                textStyle: PracticeSessionsTokens.filterChoiceLabel,
                padding: PracticeSessionsTokens.filterChoicePadding,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(TempoRadius.chip),
                  side: BorderSide(
                    color: value == choice.value
                        ? TempoColors.teal
                        : TempoColors.line,
                  ),
                ),
              ),
              child: Text(choice.label),
            ),
          ),
        ),
    ],
  );
}
