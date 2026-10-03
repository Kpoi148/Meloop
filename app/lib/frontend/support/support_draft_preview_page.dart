import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../shared/support/contact_platform.dart';
import '../application/contact_support_controller.dart';
import '../components/meloop_ui.dart';
import 'contact_widgets.dart';

class SupportDraftPreviewPage extends ConsumerStatefulWidget {
  const SupportDraftPreviewPage({super.key, required this.draft});
  final SupportEmailDraft draft;

  @override
  ConsumerState<SupportDraftPreviewPage> createState() =>
      _SupportDraftPreviewPageState();
}

class _SupportDraftPreviewPageState
    extends ConsumerState<SupportDraftPreviewPage> {
  bool _opening = false;
  bool _failed = false;

  Future<void> _compose() async {
    if (_opening) return;
    setState(() {
      _opening = true;
      _failed = false;
    });
    var opened = false;
    try {
      opened = await ref
          .read(contactPlatformProvider)
          .openEmailDraft(widget.draft);
    } catch (_) {
      // Keep the exact reviewed draft available for copying or retrying.
    }
    if (!mounted) return;
    setState(() {
      _opening = false;
      _failed = !opened;
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final draft = widget.draft;
    final platform = ref.watch(contactPlatformProvider);
    return MeloopPage(
      topBar: ContactTopBar(title: strings.supportPreview),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: TempoSpace.lg,
        children: [
          Text(strings.supportDraftHeading, style: TempoType.heading),
          Text(strings.supportReviewNote, style: TempoType.body),
          MeloopCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: TempoSpace.md,
              children: [
                Text(strings.supportAddress, style: TempoType.label),
                if (draft.recipient != null)
                  SelectableText(draft.recipient!, style: TempoType.body)
                else
                  Text(strings.supportNotPublished, style: TempoType.body),
                Text(strings.supportSubject, style: TempoType.label),
                SelectableText(draft.subject, style: TempoType.body),
                Text(strings.supportDescription, style: TempoType.label),
                SelectableText(
                  draft.body.isEmpty ? strings.supportEmptyBody : draft.body,
                  style: TempoType.body,
                ),
              ],
            ),
          ),
          Text(
            strings.supportPrivacyNote,
            style: TempoType.caption.copyWith(color: TempoColors.muted),
          ),
          if (_failed)
            MeloopNotice(
              message: strings.supportEmailUnavailable,
              kind: MeloopNoticeKind.error,
            ),
          MeloopButton(
            label: strings.supportCompose,
            icon: MeloopIcons.mail,
            isLoading: _opening,
            onPressed: draft.recipient == null ? null : _compose,
          ),
          if (draft.recipient != null)
            ContactCopyButton(
              label: strings.supportCopyAddress,
              copy: () => platform.copyText(draft.recipient!),
            ),
          ContactCopyButton(
            label: strings.supportCopyDetails,
            copy: () => platform.copyText('${draft.subject}\n\n${draft.body}'),
          ),
          MeloopButton(
            label: strings.supportEditDraft,
            style: MeloopButtonStyle.soft,
            onPressed: _opening ? null : () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
