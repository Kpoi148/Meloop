import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../application/startup_controller.dart';
import '../components/meloop_ui.dart';
import 'preview_copy.dart';

/// Settings composition mirrored from the Tempo prototype.
///
/// Rows without an implemented destination intentionally remain presentational.
class SettingsExample extends StatelessWidget {
  const SettingsExample({
    super.key,
    required this.profile,
    required this.language,
    required this.onLanguage,
    this.onProfiles,
    this.isPro = false,
    this.onPro,
    this.onRestorePro,
    this.onPrivacy,
    this.onSupport,
  });

  final PreviewInstrumentProfile profile;
  final String language;
  final VoidCallback onLanguage;
  final VoidCallback? onProfiles;
  final bool isPro;
  final VoidCallback? onPro, onRestorePro;
  final VoidCallback? onPrivacy, onSupport;

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SettingsTop(
          plan: isPro ? strings.proPreviewPlan : strings.settingsFreePlan,
        ),
        const SizedBox(height: 22),
        const _SettingsHeading(),
        _ProfileBanner(profile: profile, onTap: onProfiles),
        const SizedBox(height: 10),
        _ProBanner(onTap: onPro),
        _SettingsGroupTitle(strings.settingsPersonalGroup),
        _SettingsList(
          children: [
            _SettingsRow(
              icon: MeloopIcons.globe,
              label: strings.language,
              detail: language,
              onTap: onLanguage,
            ),
            _SettingsRow(
              icon: MeloopIcons.clock,
              label: strings.reminder,
              detail: strings.settingsReminderOff,
            ),
            _SettingsRow(
              icon: MeloopIcons.folder,
              label: strings.settingsDeviceData,
            ),
          ],
        ),
        _SettingsGroupTitle(strings.settingsInformationGroup),
        _SettingsList(
          children: [
            _SettingsRow(
              icon: MeloopIcons.shield,
              label: strings.settingsPrivacy,
              onTap: onPrivacy,
            ),
            _SettingsRow(
              icon: MeloopIcons.help,
              label: strings.settingsContactSupport,
              onTap: onSupport,
            ),
            _SettingsRow(
              icon: MeloopIcons.refresh,
              label: strings.settingsRestorePro,
              onTap: onRestorePro,
            ),
          ],
        ),
        const SizedBox(height: 29),
        Text(
          '${strings.settingsVersion('0.1.0')}\n${strings.settingsStudioCredit}',
          textAlign: TextAlign.center,
          style: TempoType.caption.copyWith(
            color: TempoColors.muted,
            height: 1.7,
          ),
        ),
        const SizedBox(height: 17),
      ],
    );
  }
}

class _SettingsTop extends StatelessWidget {
  const _SettingsTop({required this.plan});

  final String plan;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 10,
    runSpacing: TempoSpace.xs,
    children: [
      Text(
        context.l10n.navSettings,
        style: TempoType.section.copyWith(fontSize: 22, letterSpacing: -.5),
      ),
      DecoratedBox(
        decoration: BoxDecoration(
          color: TempoColors.yellow,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Text(
            plan,
            style: TempoType.caption.copyWith(
              color: TempoColors.ink,
              fontSize: 11,
              height: 1,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    ],
  );
}

class _SettingsHeading extends StatelessWidget {
  const _SettingsHeading();

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final largeText = MediaQuery.textScalerOf(context).scale(16) > 20;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: largeText ? 150 : 106),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            right: -120,
            top: -17,
            child: const MeloopArt.scene(MeloopScene.guitar, size: 206),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.settingsEyebrow,
                  style: TempoType.caption.copyWith(
                    color: const Color(0xFF426570),
                    fontSize: 10,
                    height: 1.5,
                    letterSpacing: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  strings.settingsHeading,
                  style: TempoType.heading.copyWith(fontSize: 33, height: 1.15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileBanner extends StatelessWidget {
  const _ProfileBanner({required this.profile, this.onTap});

  static const _surface = Color(0xFFF1EFDF);

  final PreviewInstrumentProfile profile;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final largeText = MediaQuery.textScalerOf(context).scale(16) > 20;
    return LayoutBuilder(
      builder: (context, constraints) {
        final expanded = constraints.maxWidth >= 410;
        final minimumHeight = largeText ? 260.0 : (expanded ? 212.0 : 180.0);
        return Semantics(
          button: onTap != null,
          label:
              '${profileDisplayName(strings, profile)}. '
              '${strings.settingsManageProfiles}',
          child: Material(
            color: _surface,
            borderRadius: BorderRadius.circular(19),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minimumHeight),
                child: Stack(
                  children: [
                    if (profile.instrument == MeloopInstrument.guitar)
                      Positioned(
                        right: -32,
                        top: -40,
                        child: Image.asset(
                          'assets/illustrations/fidelity-setup.png',
                          width: expanded ? 318 : 276,
                          height: expanded ? 318 : 276,
                          fit: BoxFit.contain,
                          excludeFromSemantics: true,
                        ),
                      )
                    else
                      Positioned(
                        right: -32,
                        top: -40,
                        child: Transform.rotate(
                          angle: .122,
                          child: MeloopArt.instrument(
                            profile.instrument,
                            size: expanded ? 318 : 276,
                          ),
                        ),
                      ),
                    const Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _surface,
                              Color(0xEDF1EFDF),
                              Color(0x00F1EFDF),
                            ],
                            stops: [0, .29, .68],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(17, 20, 48, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: constraints.maxWidth * .75,
                            ),
                            child: Text(
                              profileDisplayName(strings, profile),
                              style: TempoType.section.copyWith(
                                fontSize: 24,
                                height: 1.25,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            strings.settingsManageProfiles,
                            style: TempoType.caption.copyWith(
                              color: TempoColors.ink,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 12,
                      top: 26,
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          color: TempoColors.paper,
                          shape: BoxShape.circle,
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(3),
                          child: MeloopIcon(MeloopIcons.arrow, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProBanner extends StatelessWidget {
  const _ProBanner({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final largeText = MediaQuery.textScalerOf(context).scale(16) > 20;
    return LayoutBuilder(
      builder: (context, constraints) {
        final expanded = constraints.maxWidth >= 410;
        final minimumHeight = largeText ? 250.0 : 180.0;
        return Semantics(
          button: onTap != null,
          label: strings.settingsExplorePro,
          child: Material(
            color: TempoColors.teal,
            borderRadius: BorderRadius.circular(TempoRadius.card),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: const Key('explore-pro'),
              onTap: onTap,
              child: Container(
                constraints: BoxConstraints(minHeight: minimumHeight),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: TempoColors.teal,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      bottom: -41,
                      child: MeloopArt.scene(
                        MeloopScene.pro,
                        size: expanded ? 210 : 178,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(17),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(
                              children: [
                                const TextSpan(text: 'Meloop '),
                                TextSpan(
                                  text: 'Pro',
                                  style: TempoType.section.copyWith(
                                    color: TempoColors.yellow,
                                    fontSize: 28,
                                    letterSpacing: -1.1,
                                  ),
                                ),
                              ],
                            ),
                            style: TempoType.section.copyWith(
                              color: TempoColors.white,
                              fontSize: 28,
                              letterSpacing: -1.1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 240),
                            child: Text(
                              strings.settingsProDescription,
                              style: TempoType.caption.copyWith(
                                color: TempoColors.white,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: TempoColors.yellow,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 9,
                              ),
                              child: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: TempoSpace.xs,
                                children: [
                                  Text(
                                    strings.settingsExplorePro,
                                    style: TempoType.caption.copyWith(
                                      color: TempoColors.ink,
                                      fontSize: 14,
                                      height: 1.3,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const MeloopIcon(MeloopIcons.arrow, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SettingsGroupTitle extends StatelessWidget {
  const _SettingsGroupTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 8),
    child: Text(
      label,
      style: TempoType.section.copyWith(fontSize: 22, letterSpacing: -.75),
    ),
  );
}

class _SettingsList extends StatelessWidget {
  const _SettingsList({required this.children});

  final List<_SettingsRow> children;

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: const Color(0x22FFFFFF),
      border: Border.all(color: TempoColors.line),
      borderRadius: BorderRadius.circular(14),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 13),
    child: Column(
      children: [
        for (var index = 0; index < children.length; index++) ...[
          children[index],
          if (index != children.length - 1)
            const Divider(height: 1, thickness: 1),
        ],
      ],
    ),
  );
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    this.detail,
    this.onTap,
  });

  final MeloopIcons icon;
  final String label;
  final String? detail;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 65),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            MeloopIcon(icon, size: 27),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                label,
                style: TempoType.label.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
            if (detail case final detail?) ...[
              const SizedBox(width: TempoSpace.sm),
              Flexible(
                child: Text(
                  detail,
                  textAlign: TextAlign.end,
                  style: TempoType.caption.copyWith(
                    color: TempoColors.muted,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
            const SizedBox(width: TempoSpace.sm),
            const MeloopIcon(MeloopIcons.arrow, size: 17),
          ],
        ),
      ),
    );
    return Material(
      type: MaterialType.transparency,
      child: InkWell(onTap: onTap, child: content),
    );
  }
}
