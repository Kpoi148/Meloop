import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../application/startup_controller.dart';
import '../components/meloop_ui.dart';
import '../showcase/preview_copy.dart';
import 'practice_session.dart';
import 'practice_session_copy.dart';

/// Read-only details for UC-06. Editing and audio playback belong to other flows.
class PracticeSessionDetailPage extends StatelessWidget {
  const PracticeSessionDetailPage({
    super.key,
    required this.session,
    required this.profile,
    required this.now,
  });

  final PracticeSession session;
  final PreviewInstrumentProfile profile;
  final DateTime now;
  static const _artSize = 200.0;

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    return MeloopPage(
      topBar: MeloopTopBar(
        title: strings.practiceSessionDetails,
        onBack: () => Navigator.of(context).pop(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: TempoSpace.page,
        children: [
          Text(
            practiceDayLabel(strings, session.date, now),
            style: TempoType.caption.copyWith(color: TempoColors.muted),
          ),
          Text(session.title, style: TempoType.heading),
          Text(profileDisplayName(strings, profile), style: TempoType.label),
          Wrap(
            spacing: TempoSpace.md,
            children: [
              Text(practiceDuration(strings, session.duration)),
              if (session.bpm != null) Text(strings.practiceBpm(session.bpm!)),
            ],
          ),
          Center(
            child: profile.instrument == MeloopInstrument.guitar
                ? const MeloopArt.scene(MeloopScene.guitar, size: _artSize)
                : MeloopArt.instrument(profile.instrument, size: _artSize),
          ),
          MeloopResponsiveRow(
            children: [
              _Rating(label: strings.mood, value: session.mood),
              _Rating(label: strings.focusLevel, value: session.focus),
            ],
          ),
          _Note(
            title: strings.practiceWhatWasPracticed,
            text: session.practiced,
            icon: MeloopIcons.book,
          ),
          _Note(
            title: strings.difficulty,
            text: session.difficulty,
            icon: MeloopIcons.music,
          ),
          MeloopCard(
            color: TempoColors.selection,
            child: _Note(
              title: strings.nextPractice,
              text: session.nextPractice,
              icon: MeloopIcons.arrow,
            ),
          ),
          if (session.recordingCount > 0)
            MeloopCard(
              child: Row(
                children: [
                  const MeloopArt.tool(
                    MeloopTool.recordings,
                    size: TempoSize.touchTarget,
                  ),
                  const SizedBox(width: TempoSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.practiceSessionRecordings,
                          style: TempoType.label,
                        ),
                        Text(
                          strings.practiceRecordingCount(
                            session.recordingCount,
                          ),
                          style: TempoType.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Rating extends StatelessWidget {
  const _Rating({required this.label, required this.value});
  final String label;
  final int? value;

  @override
  Widget build(BuildContext context) => MeloopCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TempoType.caption),
        const SizedBox(height: TempoSpace.sm),
        Text(
          value == null
              ? context.l10n.practiceNotRated
              : context.l10n.practiceRatingValue(value!),
          style: TempoType.section,
        ),
      ],
    ),
  );
}

class _Note extends StatelessWidget {
  const _Note({required this.title, required this.text, required this.icon});
  final String title, text;
  final MeloopIcons icon;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MeloopIcon(icon),
          const SizedBox(width: TempoSpace.sm),
          Expanded(child: Text(title, style: TempoType.title)),
        ],
      ),
      const SizedBox(height: TempoSpace.sm),
      Text(
        text.isEmpty ? context.l10n.practiceNoNotes : text,
        style: TempoType.body.copyWith(color: TempoColors.muted),
      ),
    ],
  );
}
