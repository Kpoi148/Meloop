import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../components/meloop_ui.dart';
import 'recording_tokens.dart';
import 'recording_visuals.dart';

/// The prototype's recorder entry when no practice session is in progress.
class RecordingEmptyPage extends StatelessWidget {
  const RecordingEmptyPage({
    super.key,
    required this.onBack,
    required this.onHome,
    required this.onCreatePractice,
  });

  final VoidCallback onBack, onHome;
  final Future<void> Function() onCreatePractice;

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    return MeloopPage(
      topBar: RecordingTopBar(onBack: onBack, onHome: onHome),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: RecordingTokens.introInset,
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: RecordingTokens.introMaxWidth,
                ),
                child: Text(
                  strings.recordingEmptyHeading,
                  style: TempoType.heading,
                ),
              ),
            ),
          ),
          const RecordingArtwork(),
          MeloopCard(
            color: RecordingTokens.cardFill,
            padding: const EdgeInsets.all(RecordingTokens.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  strings.recordingEmptyTitle,
                  style: RecordingTokens.reviewTitle,
                ),
                const SizedBox(height: RecordingTokens.quotaGap),
                Text(
                  strings.recordingEmptyDescription,
                  style: RecordingTokens.emptyDescription,
                ),
              ],
            ),
          ),
          const SizedBox(height: TempoSpace.page),
          MeloopButton(
            label: strings.createPractice,
            icon: MeloopIcons.plus,
            iconGap: RecordingTokens.createIconGap,
            onPressed: onCreatePractice,
          ),
        ],
      ),
    );
  }
}
