import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../application/startup_controller.dart';
import '../components/meloop_ui.dart';
import '../showcase/preview_copy.dart';
import '../showcase/session_form_example.dart';
import 'practice_session.dart';
import 'practice_session_actions.dart';
import 'practice_session_copy.dart';
import 'practice_session_delete_dialog.dart';
import 'practice_session_detail_tokens.dart';
import 'practice_session_recordings_sheet.dart';
import 'practice_session_top_bar.dart';

/// UC-06/07 presentation. Actions are supplied by the app, with no storage here.
class PracticeSessionDetailPage extends ConsumerStatefulWidget {
  const PracticeSessionDetailPage({
    super.key,
    required this.session,
    required this.profile,
    required this.now,
    this.onHome,
  });
  final PracticeSession session;
  final PreviewInstrumentProfile profile;
  final DateTime now;
  final VoidCallback? onHome;
  @override
  ConsumerState<PracticeSessionDetailPage> createState() =>
      _PracticeSessionDetailPageState();
}

class _PracticeSessionDetailPageState
    extends ConsumerState<PracticeSessionDetailPage> {
  late PracticeSession _session = widget.session;
  bool _acting = false;

  Future<void> _edit() async {
    if (_acting) return;
    setState(() => _acting = true);
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => SessionFormExample(
            editing: true,
            onHome: widget.onHome,
            sessionId: _session.id,
            initialValues: SessionFormValues(
              title: _session.title,
              date: _session.date,
              durationSeconds: _session.duration.inSeconds,
              practiced: _session.practiced,
              difficulty: _session.difficulty,
              next: _session.nextPractice,
              mood: _session.mood,
              focus: _session.focus,
              bpm: _session.bpm,
            ),
            onSave: (values) async {
              final updated = await ref.read(practiceSessionUpdateProvider)(
                _session,
                values,
              );
              if (mounted) setState(() => _session = updated);
            },
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _delete() async {
    if (_acting) return;
    setState(() => _acting = true);
    try {
      final deleted = await showPracticeSessionDeleteConfirm(
        context,
        onDelete: () => ref.read(practiceSessionDeleteProvider)(_session),
      );
      if (deleted && mounted) {
        MeloopNotifications.show(context, context.l10n.sessionDeleted);
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final metadata = [
      profileDisplayName(strings, widget.profile),
      practiceDuration(strings, _session.duration),
      if (_session.bpm != null) strings.practiceBpm(_session.bpm!),
    ].join(' · ');
    return MeloopPage(
      topBar: PracticeSessionTopBar(
        title: strings.practiceSessionDetails,
        onBack: _acting ? null : () => Navigator.of(context).pop(),
        onHome: _acting
            ? null
            : widget.onHome ?? () => Navigator.of(context).pop(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            practiceGroupDayLabel(strings, _session.date, widget.now),
            textAlign: TextAlign.center,
            style: PracticeSessionDetailTokens.meta,
          ),
          Padding(
            padding: PracticeSessionDetailTokens.titleMargin,
            child: Text(
              _session.title,
              textAlign: TextAlign.center,
              style: PracticeSessionDetailTokens.heading,
            ),
          ),
          Text(
            metadata,
            textAlign: TextAlign.center,
            style: PracticeSessionDetailTokens.meta,
          ),
          Center(
            child: widget.profile.instrument == MeloopInstrument.guitar
                ? const MeloopArt.scene(
                    MeloopScene.guitar,
                    size: PracticeSessionDetailTokens.artSize,
                  )
                : MeloopArt.instrument(
                    widget.profile.instrument,
                    size: PracticeSessionDetailTokens.instrumentArtSize,
                    backgroundColor: TempoColors.paper,
                  ),
          ),
          Padding(
            padding: PracticeSessionDetailTokens.ratingsMargin,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: TempoSpace.md,
              children: [
                Expanded(
                  child: _Rating(
                    label: strings.mood.toUpperCase(),
                    value: _session.mood,
                  ),
                ),
                Expanded(
                  child: _Rating(
                    label: strings.practiceFocusLabel.toUpperCase(),
                    value: _session.focus,
                  ),
                ),
              ],
            ),
          ),
          _Note(
            title: strings.practiceWhatWasPracticed,
            text: _session.practiced,
            icon: MeloopIcons.book,
          ),
          _Note(
            title: strings.difficulty,
            text: _session.difficulty,
            icon: MeloopIcons.music,
          ),
          const SizedBox(height: PracticeSessionDetailTokens.nextMargin),
          Container(
            padding: PracticeSessionDetailTokens.nextPadding,
            decoration: BoxDecoration(
              color: PracticeSessionDetailTokens.nextFill,
              border: Border.all(color: PracticeSessionDetailTokens.nextBorder),
              borderRadius: BorderRadius.circular(TempoRadius.card),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _NoteHeading(
                  title: strings.nextPractice,
                  icon: MeloopIcons.arrow,
                  style: TempoType.title,
                ),
                const SizedBox(height: 6),
                Text(
                  _session.nextPractice.isEmpty
                      ? strings.practiceNextEmpty
                      : _session.nextPractice,
                  style: PracticeSessionDetailTokens.nextBody,
                ),
              ],
            ),
          ),
          Padding(
            padding: PracticeSessionDetailTokens.recordingsMargin,
            child: Material(
              color: PracticeSessionDetailTokens.cardFill,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(TempoRadius.action),
                side: const BorderSide(color: TempoColors.line),
              ),
              child: InkWell(
                onTap: _acting
                    ? null
                    : () => showPracticeSessionRecordings(
                        context,
                        session: _session,
                        onChanged: (session) =>
                            setState(() => _session = session),
                      ),
                borderRadius: BorderRadius.circular(TempoRadius.action),
                child: Padding(
                  padding: PracticeSessionDetailTokens.recordingsPadding,
                  child: Row(
                    children: [
                      const MeloopArt.tool(
                        MeloopTool.recordings,
                        size: PracticeSessionDetailTokens.recordingsArtSize,
                      ),
                      const SizedBox(
                        width: PracticeSessionDetailTokens.recordingsGap,
                      ),
                      Expanded(
                        child: Text(
                          strings.practiceSessionRecordings,
                          style: PracticeSessionDetailTokens.recordingsLabel,
                        ),
                      ),
                      const MeloopIcon(MeloopIcons.arrow),
                    ],
                  ),
                ),
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final actions = [
                MeloopButton(
                  label: strings.editSessionJournal,
                  icon: MeloopIcons.edit,
                  iconGap: PracticeSessionDetailTokens.actionIconGap,
                  style: MeloopButtonStyle.outline,
                  borderColor: PracticeSessionDetailTokens.outlineBorder,
                  borderRadius: TempoRadius.action,
                  onPressed: _acting ? null : () => unawaited(_edit()),
                ),
                MeloopButton(
                  label: strings.deleteSession,
                  icon: MeloopIcons.trash,
                  iconGap: PracticeSessionDetailTokens.actionIconGap,
                  style: MeloopButtonStyle.soft,
                  borderRadius: TempoRadius.action,
                  onPressed: _acting ? null : () => unawaited(_delete()),
                ),
              ];
              if (constraints.maxWidth <
                      PracticeSessionDetailTokens.compactActionsWidth ||
                  MediaQuery.textScalerOf(context)
                          .scale(TempoType.body.fontSize!) >
                      PracticeSessionDetailTokens.largeActionTextSize) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: PracticeSessionDetailTokens.actionsGap,
                  children: actions,
                );
              }
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: PracticeSessionDetailTokens.actionsGap,
                  children: actions
                      .map((action) => Expanded(child: action))
                      .toList(),
                ),
              );
            },
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
    color: PracticeSessionDetailTokens.cardFill,
    padding: PracticeSessionDetailTokens.ratingPadding,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: PracticeSessionDetailTokens.ratingLabel),
        Padding(
          padding: PracticeSessionDetailTokens.ratingValueMargin,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: value?.toString() ?? context.l10n.practiceEmptyRating,
                ),
                TextSpan(
                  text: context.l10n.practiceRatingSuffix,
                  style: PracticeSessionDetailTokens.ratingSuffix,
                ),
              ],
            ),
            style: PracticeSessionDetailTokens.ratingValue,
          ),
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
  Widget build(BuildContext context) => Container(
    padding: PracticeSessionDetailTokens.notePadding,
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: TempoColors.line)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _NoteHeading(
          title: title,
          icon: icon,
          style: PracticeSessionDetailTokens.noteHeading,
        ),
        const SizedBox(height: TempoSpace.sm),
        Text(
          text.isEmpty ? context.l10n.practiceNoNotes : text,
          style: PracticeSessionDetailTokens.noteBody,
        ),
      ],
    ),
  );
}

class _NoteHeading extends StatelessWidget {
  const _NoteHeading({
    required this.title,
    required this.icon,
    required this.style,
  });
  final String title;
  final MeloopIcons icon;
  final TextStyle style;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      MeloopIcon(icon),
      const SizedBox(width: TempoSpace.xs),
      Expanded(child: Text(title, style: style)),
    ],
  );
}
