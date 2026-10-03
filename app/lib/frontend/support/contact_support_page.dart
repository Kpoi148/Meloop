import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../application/contact_support_controller.dart';
import '../components/meloop_ui.dart';
import 'contact_widgets.dart';
import 'support_draft_preview_page.dart';

class ContactSupportPage extends ConsumerStatefulWidget {
  const ContactSupportPage({super.key, this.onHome});
  final VoidCallback? onHome;

  @override
  ConsumerState<ContactSupportPage> createState() => _ContactSupportPageState();
}

class _ContactSupportPageState extends ConsumerState<ContactSupportPage> {
  final _form = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _description = TextEditingController();
  bool _includeDetails = false;
  bool _preparing = false;
  bool _failed = false;

  @override
  void dispose() {
    _subject.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _preview() async {
    if (_preparing || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _preparing = true;
      _failed = false;
    });
    try {
      final draft = await ref
          .read(contactSupportControllerProvider)
          .prepareDraft(
            subject: _subject.text,
            description: _description.text,
            includeTechnicalDetails: _includeDetails,
            strings: context.l10n,
          );
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => SupportDraftPreviewPage(draft: draft),
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _preparing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final controller = ref.watch(contactSupportControllerProvider);
    final email = controller.configuration.emailAddress;
    return MeloopPage(
      topBar: ContactTopBar(
        title: strings.settingsContactSupport,
        onHome: widget.onHome,
      ),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SupportIntro(),
            const SizedBox(height: TempoSpace.md),
            MeloopCard(
              child: email == null
                  ? Text(strings.supportNotPublished, style: TempoType.body)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(strings.supportAddress, style: TempoType.label),
                        SelectableText(email, style: TempoType.body),
                        const SizedBox(height: TempoSpace.md),
                        ContactCopyButton(
                          label: strings.supportCopyAddress,
                          copy: () => controller.platform.copyText(email),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: TempoSpace.xl),
            MeloopField(
              key: const Key('support-subject'),
              label: strings.supportSubject,
              controller: _subject,
              hint: strings.supportSubjectHint,
              requirement: MeloopFieldRequirement.required,
              enabled: !_preparing,
              validator: (value) =>
                  controller.validateSubject(value ?? '', strings),
            ),
            const SizedBox(height: TempoSpace.xl),
            MeloopField(
              key: const Key('support-description'),
              label: strings.supportDescription,
              controller: _description,
              hint: strings.supportDescriptionHint,
              type: MeloopInputType.multiline,
              enabled: !_preparing,
              helper: strings.supportDescriptionLimit(
                SupportInputLimits.descriptionCodePoints,
              ),
              validator: (value) =>
                  controller.validateDescription(value ?? '', strings),
            ),
            const SizedBox(height: TempoSpace.xl),
            MeloopToggle(
              checkbox: true,
              label: strings.supportIncludeDiagnostics,
              description: strings.supportDiagnosticsExplanation,
              value: _includeDetails,
              onChanged: _preparing
                  ? null
                  : (value) => setState(() {
                      _includeDetails = value;
                      _failed = false;
                    }),
            ),
            const SizedBox(height: TempoSpace.lg),
            Text(
              strings.supportPrivacyNote,
              style: TempoType.caption.copyWith(color: TempoColors.muted),
            ),
            if (_failed) ...[
              const SizedBox(height: TempoSpace.md),
              MeloopNotice(
                message: strings.supportPreviewFailed,
                kind: MeloopNoticeKind.error,
              ),
            ],
            const SizedBox(height: TempoSpace.xl),
            MeloopButton(
              label: strings.supportPreview,
              icon: MeloopIcons.mail,
              isLoading: _preparing,
              onPressed: _preview,
            ),
          ],
        ),
      ),
    );
  }
}
