import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/practice/practice_session_service.dart';
import '../application/startup_controller.dart';
import '../components/meloop_ui.dart';
import '../showcase/preview_copy.dart';
import '../theme/tokens/practice_tokens.dart';
import 'practice_duration.dart';

class SavedPracticePage extends StatelessWidget {
  const SavedPracticePage({
    super.key,
    required this.session,
    required this.profile,
  });

  final SavedPracticeSession session;
  final PreviewInstrumentProfile profile;

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final values = session.values;
    return MeloopPage(
      topBar: MeloopTopBar(
        title: strings.savedPracticeDetails,
        onBack: () => Navigator.of(context).pop(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: TempoSpace.page,
        children: [
          Text(
            MaterialLocalizations.of(context).formatMediumDate(values.date),
            textAlign: TextAlign.center,
          ),
          Text(
            values.title,
            style: TempoType.heading,
            textAlign: TextAlign.center,
          ),
          Text(
            '${profileDisplayName(strings, profile)} · ${formatPracticeDuration(Duration(seconds: values.durationSeconds))}',
            textAlign: TextAlign.center,
          ),
          Center(
            child: MeloopArt.instrument(
              profile.instrument,
              size: PracticeTempo.detailArtSize,
            ),
          ),
          MeloopResponsiveRow(
            children: [
              _rating(strings.mood, values.mood, strings),
              _rating(strings.focusLevel, values.focus, strings),
            ],
          ),
          _note(strings.practicedWhat, values.practiced, strings),
          _note(strings.difficulty, values.difficulty, strings),
          MeloopCard(
            color: TempoColors.selection,
            child: _note(strings.nextPractice, values.next, strings),
          ),
        ],
      ),
    );
  }

  Widget _rating(String label, int? value, AppLocalizations strings) =>
      MeloopCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TempoType.caption),
            Text(
              value == null
                  ? strings.practiceNotRated
                  : strings.practiceRating(value),
              style: TempoType.section,
            ),
          ],
        ),
      );

  Widget _note(String label, String value, AppLocalizations strings) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: TempoSpace.sm,
    children: [
      Text(label, style: TempoType.title),
      Text(value.isEmpty ? strings.noPracticeNotes : value),
    ],
  );
}
