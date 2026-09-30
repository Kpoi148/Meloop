import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../application/startup_controller.dart';
import '../components/meloop_ui.dart';
import 'preview_copy.dart';

class InstrumentPickerExample extends StatelessWidget {
  const InstrumentPickerExample({
    super.key,
    required this.profiles,
    required this.selectedProfileId,
    required this.onSelect,
    required this.onAdd,
    this.onBack,
  });

  final List<PreviewInstrumentProfile> profiles;
  final String? selectedProfileId;
  final bool Function(String id) onSelect;
  final VoidCallback onAdd;
  final VoidCallback? onBack;

  Future<void> _select(
    BuildContext context,
    PreviewInstrumentProfile profile,
  ) async {
    if (onSelect(profile.id)) return;
    final strings = context.l10n;
    await showMeloopSheet<void>(
      context,
      title: strings.unfinishedSessionTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(strings.unfinishedSessionMessage),
          const SizedBox(height: TempoSpace.lg),
          MeloopButton(
            label: strings.understood,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    return PopScope(
      canPop: onBack == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) onBack?.call();
      },
      child: MeloopPage(
        topBar: Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Semantics(
                  button: onBack != null,
                  child: InkWell(
                    onTap: onBack,
                    borderRadius: BorderRadius.circular(TempoRadius.field),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: TempoSpace.xs),
                      child: MeloopWordmark(),
                    ),
                  ),
                ),
              ),
            ),
            Semantics(
              label: strings.manageInstruments,
              child: const SizedBox.square(
                dimension: TempoSize.touchTarget,
                child: Center(child: MeloopIcon(MeloopIcons.settings)),
              ),
            ),
          ],
        ),
        topBarGap: TempoSpace.lg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(strings.instrumentPickerTitle, style: TempoType.heading),
            const SizedBox(height: TempoSpace.sm),
            Text(
              strings.instrumentPickerSubtitle,
              style: TempoType.body.copyWith(color: TempoColors.muted),
            ),
            const SizedBox(height: TempoSpace.xl),
            Column(
              spacing: 13,
              children: [
                for (final profile in profiles)
                  _ProfileCard(
                    profile: profile,
                    selected: profile.id == selectedProfileId,
                    onTap: () => _select(context, profile),
                  ),
              ],
            ),
            const SizedBox(height: TempoSpace.page),
            MeloopButton(
              label: strings.addInstrument,
              icon: MeloopIcons.plus,
              style: MeloopButtonStyle.outline,
              onPressed: onAdd,
            ),
            const SizedBox(height: 13),
            Text(
              strings.freeProfileLimit,
              textAlign: TextAlign.center,
              style: TempoType.caption,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.selected,
    required this.onTap,
  });

  final PreviewInstrumentProfile profile;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    return Material(
      color: const Color(0xFFF4F0E3),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TempoRadius.card),
        side: BorderSide(
          color: selected ? TempoColors.teal : TempoColors.line,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TempoRadius.card),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 230,
              child: Stack(
                children: [
                  Center(
                    child: profile.instrument == MeloopInstrument.guitar
                        ? const MeloopArt.scene(MeloopScene.guitar, size: 230)
                        : ColorFiltered(
                            colorFilter: const ColorFilter.mode(
                              Color(0xFFF4F0E3),
                              BlendMode.darken,
                            ),
                            child: MeloopArt.instrument(
                              profile.instrument,
                              size: 230,
                            ),
                          ),
                  ),
                  if (selected)
                    Positioned(
                      top: 13,
                      right: 12,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: TempoColors.yellow,
                          borderRadius: BorderRadius.circular(TempoRadius.pill),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const MeloopIcon(MeloopIcons.check, size: 13),
                              const SizedBox(width: TempoSpace.xs),
                              Text(
                                strings.selected,
                                style: TempoType.caption.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            DecoratedBox(
              decoration: const BoxDecoration(
                color: TempoColors.paper,
                border: Border(top: BorderSide(color: TempoColors.line)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            profileDisplayName(strings, profile),
                            style: TempoType.section.copyWith(fontSize: 25),
                          ),
                        ),
                        const MeloopIcon(MeloopIcons.arrow),
                      ],
                    ),
                    const SizedBox(height: TempoSpace.xs),
                    Text(
                      '${instrumentLabel(strings, profile.instrument)} · '
                      '${profile.savedSessionCount == 0 ? strings.noPracticeSessions : strings.savedSessions(profile.savedSessionCount)}',
                      style: TempoType.caption.copyWith(
                        color: TempoColors.muted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
