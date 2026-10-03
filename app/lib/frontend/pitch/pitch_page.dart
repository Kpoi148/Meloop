import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n.dart';
import '../../shared/pitch/pitch_service.dart';
import '../components/meloop_ui.dart';
import 'pitch_gauge.dart';
import 'pitch_tokens.dart';

/// UC-09 presentation: all readings and microphone actions come from its caller.
class PitchPage extends StatelessWidget {
  const PitchPage({
    super.key,
    required this.snapshot,
    required this.onToggle,
    required this.onBack,
    required this.onHome,
    required this.onOpenSettings,
    this.stopping = false,
    this.settingsBusy = false,
    this.settingsFailed = false,
  });

  final PitchSnapshot snapshot;
  final VoidCallback onToggle, onBack, onHome;
  final Future<void> Function() onOpenSettings;
  final bool stopping, settingsBusy, settingsFailed;

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final frequencyFormat = NumberFormat.decimalPatternDigits(
      locale: locale,
      decimalDigits: PitchTokens.measurementDigits,
    );
    final centsFormat = NumberFormat.decimalPatternDigits(
      locale: locale,
      decimalDigits: PitchTokens.centsDigits,
    );
    final reading = snapshot.reading;
    final denied =
        snapshot.phase == PitchPhase.permissionDenied ||
        snapshot.phase == PitchPhase.permissionBlocked;
    final error = switch (snapshot.phase) {
      PitchPhase.permissionDenied => strings.pitchPermissionDenied,
      PitchPhase.permissionBlocked => strings.pitchPermissionBlocked,
      PitchPhase.unavailable => strings.pitchUnavailable,
      PitchPhase.audioBusy => strings.pitchAudioBusy,
      PitchPhase.failed => strings.pitchFailed,
      PitchPhase.stopFailed => strings.pitchStopFailed,
      _ => null,
    };
    final status = switch (snapshot.phase) {
      PitchPhase.requestingPermission => strings.pitchRequestingPermission,
      PitchPhase.listening => strings.pitchListening,
      PitchPhase.weakSignal => strings.pitchWeakSignal,
      PitchPhase.detected when reading != null => strings.pitchMeasurement(
        frequencyFormat.format(reading.frequencyHz),
        '${reading.cents.round() >= 0 ? '+' : ''}${centsFormat.format(reading.cents.round())}',
      ),
      PitchPhase.detected => strings.pitchWeakSignal,
      _ => strings.pitchNoSignal,
    };
    final hint = reading == null
        ? snapshot.phase == PitchPhase.weakSignal ||
                  snapshot.phase == PitchPhase.detected
              ? strings.pitchWeakSignalHint
              : strings.pitchInstruction
        : switch (reading.direction) {
            PitchDirection.low => strings.pitchLow,
            PitchDirection.inTune => strings.pitchInTune,
            PitchDirection.high => strings.pitchHigh,
          };
    final config = snapshot.configuration;
    final reference = NumberFormat.decimalPattern(locale)
        .format(config.referenceHz);
    return MeloopPage(
      padding: const EdgeInsets.fromLTRB(
        PitchTokens.pageInset,
        TempoSpace.xl,
        PitchTokens.pageInset,
        TempoSpace.xxl,
      ),
      topBarGap: PitchTokens.topBarGap,
      topBar: MeloopTopBar(
        title: strings.pitchTool,
        onBack: onBack,
        trailing: IconButton(
          tooltip: strings.navHome,
          onPressed: onHome,
          icon: const MeloopIcon(MeloopIcons.home),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: TempoSpace.sm,
            runSpacing: TempoSpace.sm,
            children: [
              _PitchPill(
                strings.pitchRange(config.lowestNote, config.highestNote),
              ),
              _PitchPill(
                strings.pitchReference(config.referenceNote, reference),
              ),
            ],
          ),
          const SizedBox(
            height: PitchTokens.heroHeight,
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.topCenter,
                minWidth: PitchTokens.artworkSize,
                maxWidth: PitchTokens.artworkSize,
                minHeight: PitchTokens.artworkSize,
                maxHeight: PitchTokens.artworkSize,
                child: MeloopArt.tool(
                  MeloopTool.tuner,
                  size: PitchTokens.artworkSize,
                ),
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: PitchTokens.cardFill,
              border: Border.all(color: TempoColors.line),
              borderRadius: BorderRadius.circular(TempoRadius.card),
            ),
            child: Padding(
              padding: const EdgeInsets.all(PitchTokens.cardInset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    liveRegion: true,
                    child: Column(
                      children: [
                        Text(
                          reading?.note ?? strings.pitchEmptyNote,
                          key: const ValueKey('pitch-note'),
                          style: PitchTokens.note,
                          textAlign: TextAlign.center,
                        ),
                        Padding(
                          padding: PitchTokens.footnoteInset,
                          child: Text(
                            status,
                            textAlign: TextAlign.center,
                            style: PitchTokens.footnote,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: PitchTokens.gaugeTopGap,
                      bottom: PitchTokens.gaugeBottomGap,
                    ),
                    child: PitchGauge(cents: reading?.cents),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          strings.pitchCentsNegative(
                            PitchTokens.gaugeRangeCents.toInt(),
                          ),
                          style: TempoType.caption,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          strings.pitchGaugeCenter,
                          style: TempoType.caption,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          strings.pitchCentsPositive(
                            PitchTokens.gaugeRangeCents.toInt(),
                          ),
                          style: TempoType.caption,
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: PitchTokens.footnoteInset,
            child: Semantics(
              liveRegion: true,
              child: Text(
                hint,
                textAlign: TextAlign.center,
                style: PitchTokens.footnote,
              ),
            ),
          ),
          if (error != null) ...[
            MeloopNotice(message: error, kind: MeloopNoticeKind.error),
            const SizedBox(height: TempoSpace.md),
          ],
          if (denied) ...[
            Text(strings.pitchSettingsGuide, style: PitchTokens.footnote),
            const SizedBox(height: TempoSpace.md),
            MeloopButton(
              label: strings.pitchOpenSettings,
              loadingLabel: strings.pitchOpeningSettings,
              isLoading: settingsBusy,
              icon: MeloopIcons.settings,
              onPressed: onOpenSettings,
              style: MeloopButtonStyle.outline,
            ),
            const SizedBox(height: TempoSpace.md),
          ],
          if (settingsFailed) ...[
            Text(strings.pitchSettingsFailed, style: PitchTokens.footnote),
            const SizedBox(height: TempoSpace.md),
          ],
          MeloopButton(
            label: stopping
                ? strings.pitchStopping
                : snapshot.listening || snapshot.phase == PitchPhase.stopFailed
                ? strings.pitchStop
                : strings.pitchStart,
            icon: snapshot.listening ? MeloopIcons.stop : MeloopIcons.mic,
            onPressed: stopping ? null : onToggle,
            minimumHeight: PitchTokens.buttonHeight,
            borderRadius: TempoRadius.action,
            textStyle: PitchTokens.action,
          ),
          Padding(
            padding: PitchTokens.footnoteInset,
            child: Text(
              strings.pitchPrivacy,
              style: PitchTokens.footnote,
              textAlign: TextAlign.center,
            ),
          ),
          Text(
            strings.pitchLimitations,
            style: PitchTokens.footnote,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PitchPill extends StatelessWidget {
  const _PitchPill(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: PitchTokens.pillFill,
      borderRadius: BorderRadius.circular(TempoRadius.pill),
    ),
    child: Padding(
      padding: PitchTokens.pillInset,
      child: Text(label, style: PitchTokens.pill),
    ),
  );
}
