import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/l10n.dart';
import '../application/startup_controller.dart';
import '../components/meloop_ui.dart';
import 'preview_copy.dart';

enum InstrumentProfileStatus { selected, inUse, archived }

class InstrumentProfilesExample extends StatelessWidget {
  const InstrumentProfilesExample({
    super.key,
    required this.profiles,
    required this.selectedProfileId,
    required this.onBack,
    required this.onHome,
    this.archivedProfileIds = const {},
    this.onAdd,
    this.onEdit,
    this.onArchive,
  });

  final List<PreviewInstrumentProfile> profiles;
  final String? selectedProfileId;
  final Set<String> archivedProfileIds;
  final VoidCallback onBack;
  final VoidCallback onHome;
  final VoidCallback? onAdd;
  final ValueChanged<PreviewInstrumentProfile>? onEdit;
  final ValueChanged<PreviewInstrumentProfile>? onArchive;

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    return MeloopPage(
      topBarGap: TempoSpace.lg,
      topBar: MeloopTopBar(
        title: strings.instrumentProfilesTitle,
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
          Text(strings.instrumentProfilesHeading, style: TempoType.heading),
          const SizedBox(height: 9),
          Text(
            strings.instrumentProfilesSubtitle,
            style: TempoType.body.copyWith(
              color: TempoColors.muted,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 22),
          Column(
            spacing: 13,
            children: [
              for (final profile in profiles)
                _InstrumentProfileRow(
                  profile: profile,
                  status: archivedProfileIds.contains(profile.id)
                      ? InstrumentProfileStatus.archived
                      : profile.id == selectedProfileId
                      ? InstrumentProfileStatus.selected
                      : InstrumentProfileStatus.inUse,
                  onEdit: onEdit == null ? null : () => onEdit!(profile),
                  onArchive: onArchive == null
                      ? null
                      : () => onArchive!(profile),
                ),
            ],
          ),
          const SizedBox(height: TempoSpace.page),
          MeloopButton(
            label: strings.addProfile,
            icon: MeloopIcons.plus,
            onPressed: onAdd,
          ),
          const SizedBox(height: 15),
          MeloopCard(
            padding: const EdgeInsets.all(18),
            child: Text(
              strings.freeProfilesNote,
              style: TempoType.body.copyWith(
                color: TempoColors.muted,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InstrumentProfileRow extends StatelessWidget {
  const _InstrumentProfileRow({
    required this.profile,
    required this.status,
    this.onEdit,
    this.onArchive,
  });

  final PreviewInstrumentProfile profile;
  final InstrumentProfileStatus status;
  final VoidCallback? onEdit;
  final VoidCallback? onArchive;

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final content = LayoutBuilder(
      builder: (context, constraints) {
        final vertical =
            constraints.maxWidth < 280 ||
            MediaQuery.textScalerOf(context).scale(16) > 20;
        final art = _ProfileArtwork(instrument: profile.instrument);
        final info = _ProfileInfo(
          profile: profile,
          status: status,
          onEdit: onEdit,
          onArchive: onArchive,
        );
        return vertical
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(child: art),
                  const SizedBox(height: TempoSpace.md),
                  info,
                ],
              )
            : Row(
                children: [
                  art,
                  const SizedBox(width: 10),
                  Expanded(child: info),
                ],
              );
      },
    );
    return Opacity(
      opacity: status == InstrumentProfileStatus.archived ? .68 : 1,
      child: Semantics(
        label:
            '${profileDisplayName(strings, profile)}. '
            '${instrumentLabel(strings, profile.instrument)}. '
            '${_statusLabel(strings)}',
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: TempoColors.fieldFill,
            border: Border.all(color: TempoColors.line),
            borderRadius: BorderRadius.circular(18),
          ),
          child: content,
        ),
      ),
    );
  }

  String _statusLabel(AppLocalizations strings) => switch (status) {
    InstrumentProfileStatus.selected => strings.selected,
    InstrumentProfileStatus.inUse => strings.profileInUse,
    InstrumentProfileStatus.archived => strings.profileArchived,
  };
}

class _ProfileArtwork extends StatelessWidget {
  const _ProfileArtwork({required this.instrument});

  final MeloopInstrument instrument;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 118,
    height: 133,
    child: FittedBox(
      fit: BoxFit.fill,
      child: MeloopArt.instrument(instrument, size: 118),
    ),
  );
}

class _ProfileInfo extends StatelessWidget {
  const _ProfileInfo({
    required this.profile,
    required this.status,
    this.onEdit,
    this.onArchive,
  });

  final PreviewInstrumentProfile profile;
  final InstrumentProfileStatus status;
  final VoidCallback? onEdit;
  final VoidCallback? onArchive;

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final selected = status == InstrumentProfileStatus.selected;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: selected ? TempoColors.yellow : const Color(0xFFE7EBDD),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            child: Text(
              switch (status) {
                InstrumentProfileStatus.selected => strings.selected,
                InstrumentProfileStatus.inUse => strings.profileInUse,
                InstrumentProfileStatus.archived => strings.profileArchived,
              },
              style: TempoType.caption.copyWith(
                fontSize: 11,
                height: 1,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: TempoSpace.xs),
        Text(profileDisplayName(strings, profile), style: TempoType.title),
        const SizedBox(height: 5),
        Text(
          instrumentLabel(strings, profile.instrument),
          style: TempoType.caption.copyWith(color: TempoColors.muted),
        ),
        const SizedBox(height: 9),
        Wrap(
          spacing: 13,
          runSpacing: TempoSpace.xs,
          children: [
            _ProfileTextAction(label: strings.editProfile, onTap: onEdit),
            _ProfileTextAction(
              label: status == InstrumentProfileStatus.archived
                  ? strings.reactivateProfile
                  : strings.archiveProfile,
              onTap: onArchive,
            ),
          ],
        ),
      ],
    );
  }
}

class _ProfileTextAction extends StatelessWidget {
  const _ProfileTextAction({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap != null,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          label,
          style: TempoType.caption.copyWith(
            color: TempoColors.ink,
            fontSize: 12,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    ),
  );
}
