import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/l10n.dart';
import '../components/meloop_ui.dart';
import '../pitch/pitch_route.dart';
import 'pitch_preview_scenario.dart';
import 'pitch_preview_service.dart';

/// Separate manual review flow. Does not open the journal app or its storage.
class PitchPreviewLauncher extends StatelessWidget {
  const PitchPreviewLauncher({super.key});

  @override
  Widget build(BuildContext context) => MeloopPage(
    topBar: MeloopTopBar(title: context.l10n.pitchPreviewTitle),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: TempoSpace.page,
      children: [
        Text(context.l10n.pitchTool, style: TempoType.heading),
        Text(context.l10n.pitchPreviewExplanation, style: TempoType.body),
        MeloopButton(
          label: context.l10n.pitchPreviewOpen,
          icon: MeloopIcons.music,
          onPressed: () => Navigator.of(context).push<void>(
            MaterialPageRoute(builder: (_) => const PitchPreviewRoute()),
          ),
        ),
      ],
    ),
  );
}

/// Wraps the actual UC-09 route with an explicitly labeled scenario selector.
class PitchPreviewRoute extends StatefulWidget {
  const PitchPreviewRoute({super.key});

  @override
  State<PitchPreviewRoute> createState() => _PitchPreviewRouteState();
}

class _PitchPreviewRouteState extends State<PitchPreviewRoute> {
  final _service = PitchPreviewService();
  PitchPreviewScenario _scenario = PitchPreviewScenario.listening;

  void _select(PitchPreviewScenario? next) {
    if (next == null) return;
    _service.prepare(next.phase, reading: next.reading);
    setState(() => _scenario = next);
  }

  @override
  void dispose() {
    unawaited(_service.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    return ProviderScope(
      overrides: [pitchServiceProvider.overrideWithValue(_service)],
      child: Scaffold(
        body: PitchRoute(onHome: () {}),
        bottomNavigationBar: SafeArea(
          top: false,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: TempoColors.soft,
              border: Border(top: BorderSide(color: TempoColors.line)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(TempoSpace.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(strings.pitchPreviewBadge, style: TempoType.caption),
                  const SizedBox(height: TempoSpace.xs),
                  DropdownButtonFormField<PitchPreviewScenario>(
                    initialValue: _scenario,
                    isExpanded: true,
                    itemHeight: null,
                    isDense: false,
                    decoration: InputDecoration(
                      labelText: strings.pitchPreviewScenario,
                    ),
                    items: [
                      for (final scenario in PitchPreviewScenario.values)
                        DropdownMenuItem(
                          value: scenario,
                          child: Text(_label(strings, scenario)),
                        ),
                    ],
                    onChanged: _select,
                  ),
                  const SizedBox(height: TempoSpace.xs),
                  Text(strings.pitchPreviewStartHint, style: TempoType.caption),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _label(AppLocalizations strings, PitchPreviewScenario scenario) =>
    switch (scenario) {
      PitchPreviewScenario.listening => strings.pitchPreviewListening,
      PitchPreviewScenario.inTune => strings.pitchPreviewInTune,
      PitchPreviewScenario.low => strings.pitchPreviewLow,
      PitchPreviewScenario.high => strings.pitchPreviewHigh,
      PitchPreviewScenario.weakSignal => strings.pitchPreviewWeakSignal,
      PitchPreviewScenario.permissionDenied => strings.pitchPreviewDenied,
      PitchPreviewScenario.permissionBlocked => strings.pitchPreviewBlocked,
    };
