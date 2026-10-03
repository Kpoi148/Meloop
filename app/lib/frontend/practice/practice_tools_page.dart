import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../application/practice_review_provider.dart';
import '../components/meloop_ui.dart';
import '../theme/tokens/practice_tokens.dart';

/// Accessible from Home or practice without changing the active timer.
class PracticeToolsPage extends ConsumerWidget {
  const PracticeToolsPage({
    super.key,
    this.sessionId,
    this.onOpenMetronome,
    this.onOpenRecording,
  });
  final String? sessionId;
  final Future<void> Function()? onOpenMetronome;
  final Future<void> Function()? onOpenRecording;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = context.l10n;
    final tools = [
      (MeloopTool.metro, strings.metronomeTool, strings.metronomeToolHint),
      (MeloopTool.tuner, strings.pitchTool, strings.pitchToolHint),
      (MeloopTool.recorder, strings.recordTool, strings.recordToolHint),
      (
        MeloopTool.recordings,
        strings.recordingsTool,
        strings.recordingsToolHint,
      ),
    ];
    return MeloopPage(
      topBar: MeloopTopBar(
        title: strings.practiceTools,
        onBack: () => Navigator.of(context).pop(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: TempoSpace.page,
        children: [
          Text(strings.practiceToolsHeading, style: TempoType.heading),
          Text(strings.practiceToolsSubtitle),
          LayoutBuilder(
            builder: (context, constraints) {
              final large = MediaQuery.textScalerOf(context).scale(16) > 20;
              final width = large
                  ? constraints.maxWidth
                  : (constraints.maxWidth - TempoSpace.md) / 2;
              return Wrap(
                spacing: TempoSpace.md,
                runSpacing: TempoSpace.md,
                children: [
                  for (var index = 0; index < tools.length; index++)
                    SizedBox(
                      width: width,
                      child: _ToolCard(
                        tool: tools[index].$1,
                        title: tools[index].$2,
                        description: tools[index].$3,
                        number: index + 1,
                        largeText: large,
                        onOpen: () async {
                          if (tools[index].$1 == MeloopTool.metro &&
                              onOpenMetronome != null) {
                            await onOpenMetronome!();
                            return;
                          }
                          if (tools[index].$1 == MeloopTool.recorder &&
                              onOpenRecording != null) {
                            await onOpenRecording!();
                            return;
                          }
                          final id = sessionId;
                          final open = ref.read(practiceToolOpenProvider);
                          if (open == null || id == null) {
                            MeloopNotifications.show(
                              context,
                              strings.practiceToolUnavailable,
                            );
                          } else {
                            await open(context, id, tools[index].$1);
                          }
                        },
                      ),
                    ),
                ],
              );
            },
          ),
          const Divider(),
          Text(strings.practiceToolsFree, style: TempoType.label),
          Text(
            sessionId == null
                ? strings.practiceToolsStandaloneHint
                : strings.practiceToolsTimingHint,
            style: TempoType.caption,
          ),
        ],
      ),
    );
  }
}

class _ToolCard extends StatefulWidget {
  const _ToolCard({
    required this.tool,
    required this.title,
    required this.description,
    required this.number,
    required this.largeText,
    required this.onOpen,
  });
  final MeloopTool tool;
  final String title, description;
  final int number;
  final bool largeText;
  final Future<void> Function() onOpen;
  @override
  State<_ToolCard> createState() => _ToolCardState();
}

class _ToolCardState extends State<_ToolCard> {
  bool _opening = false;
  Future<void> _open() async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      await widget.onOpen();
    } catch (_) {
      if (mounted) {
        MeloopNotifications.show(
          context,
          context.l10n.practiceToolUnavailable,
          kind: MeloopNoticeKind.error,
        );
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sage =
        widget.tool == MeloopTool.tuner || widget.tool == MeloopTool.recorder;
    final footer = Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        minHeight: PracticeTempo.toolFooterMinHeight,
      ),
      padding: const EdgeInsets.all(TempoSpace.md),
      color: sage
          ? PracticeTempo.toolSageFooter
          : PracticeTempo.toolYellowFooter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: TempoSpace.sm,
        children: [
          Text(widget.title, style: PracticeTempo.toolTitle),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  widget.description,
                  style: PracticeTempo.toolCaption,
                ),
              ),
              const SizedBox(width: TempoSpace.xs),
              Container(
                width: PracticeTempo.toolArrowSize,
                height: PracticeTempo.toolArrowSize,
                decoration: const BoxDecoration(
                  color: TempoColors.teal,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: _opening
                    ? const CircularProgressIndicator(color: TempoColors.white)
                    : const MeloopIcon(
                        MeloopIcons.arrow,
                        size: TempoSize.smallIcon,
                        color: TempoColors.white,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
    final art = Center(
      child: MeloopArt.tool(widget.tool, size: PracticeTempo.toolArtSize),
    );
    return Semantics(
      button: true,
      child: Material(
        color: sage ? PracticeTempo.toolSage : PracticeTempo.toolYellow,
        borderRadius: BorderRadius.circular(PracticeTempo.toolCardRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _opening ? null : _open,
          child: widget.largeText
              ? Column(children: [art, footer])
              : SizedBox(
                  height: PracticeTempo.toolCardHeight,
                  child: Stack(
                    children: [
                      art,
                      Positioned(
                        left: TempoSpace.md,
                        top: TempoSpace.sm,
                        child: Text(
                          widget.number.toString().padLeft(2, '0'),
                          style: TempoType.caption,
                        ),
                      ),
                      Positioned(left: 0, right: 0, bottom: 0, child: footer),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
