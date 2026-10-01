import 'package:flutter/material.dart';

import '../application/instrument_profile_service.dart';
import '../components/meloop_ui.dart';

const _profileArtworkBackground = Color(0xFFF4F0E3);

class ProfilePickerScreen extends StatelessWidget {
  const ProfilePickerScreen({
    super.key,
    required this.directory,
    required this.busy,
    required this.onManage,
    required this.onAdd,
    required this.onSelect,
  });

  final ProfileDirectory directory;
  final bool busy;
  final VoidCallback onManage;
  final VoidCallback onAdd;
  final ValueChanged<InstrumentProfile> onSelect;

  @override
  Widget build(BuildContext context) => MeloopPage(
    topBar: MeloopTopBar(
      trailing: IconButton(
        tooltip: 'Quản lý nhạc cụ',
        onPressed: onManage,
        icon: const MeloopIcon(MeloopIcons.settings),
      ),
    ),
    topBarGap: TempoSpace.lg,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _ProfileIntro(
          title: 'Hôm nay bạn chơi\nnhạc cụ nào?',
          subtitle: 'Chọn một nhạc cụ để tiếp tục hành trình.',
        ),
        for (final profile in directory.profiles) ...[
          _PickerCard(
            profile: profile,
            selected: directory.selectedProfileId == profile.id,
            onTap: busy ? null : () => onSelect(profile),
          ),
          const SizedBox(height: 13),
        ],
        const SizedBox(height: TempoSpace.lg),
        MeloopButton(
          label: 'Thêm nhạc cụ',
          icon: MeloopIcons.plus,
          style: MeloopButtonStyle.outline,
          onPressed: onAdd,
        ),
        const SizedBox(height: TempoSpace.md),
        Text(
          directory.isPro
              ? 'Meloop Pro · Thêm nhạc cụ theo cách của bạn.'
              : 'Miễn phí: tối đa 3 hồ sơ nhạc cụ.',
          textAlign: TextAlign.center,
          style: TempoType.caption.copyWith(color: TempoColors.muted),
        ),
      ],
    ),
  );
}

class _PickerCard extends StatelessWidget {
  const _PickerCard({
    required this.profile,
    required this.selected,
    required this.onTap,
  });

  final InstrumentProfile profile;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: '${profile.name}, ${profile.instrumentLabel}',
    child: InkWell(
      key: Key('select-profile-${profile.id}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(TempoRadius.button),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: _profileArtworkBackground,
          border: Border.all(
            color: selected ? TempoColors.teal : TempoColors.line,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(TempoRadius.button),
        ),
        child: Column(
          children: [
            SizedBox(
              height: 228,
              child: Stack(
                children: [
                  Center(
                    child: profile.instrumentType == InstrumentType.guitar
                        ? const MeloopArt.scene(
                            MeloopScene.guitar,
                            size: 230,
                            backgroundColor: _profileArtworkBackground,
                          )
                        : MeloopArt.instrument(
                            MeloopInstrument.values[profile
                                .instrumentType
                                .index],
                            size: 230,
                            backgroundColor: _profileArtworkBackground,
                          ),
                  ),
                  if (selected)
                    Positioned(
                      top: 13,
                      right: 12,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: TempoColors.yellow,
                          borderRadius: BorderRadius.circular(20),
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
                              const SizedBox(width: 4),
                              Text(
                                'Đang chọn',
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 17),
              decoration: const BoxDecoration(
                color: Color(0x66FFFFFF),
                border: Border(top: BorderSide(color: TempoColors.line)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          profile.name,
                          style: TempoType.section.copyWith(fontSize: 25),
                        ),
                      ),
                      const MeloopIcon(MeloopIcons.arrow),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${profile.instrumentLabel} · ${profile.savedSessionCount == 0 ? 'Chưa có' : profile.savedSessionCount} buổi luyện${profile.savedSessionCount == 0 ? '' : ' đã lưu'}',
                    style: TempoType.caption.copyWith(color: TempoColors.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class ProfileManagerScreen extends StatelessWidget {
  const ProfileManagerScreen({
    super.key,
    required this.directory,
    required this.onBack,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final ProfileDirectory directory;
  final VoidCallback onBack;
  final VoidCallback onAdd;
  final ValueChanged<InstrumentProfile> onEdit;
  final ValueChanged<InstrumentProfile> onDelete;

  @override
  Widget build(BuildContext context) => MeloopPage(
    topBar: MeloopTopBar(title: 'Hồ sơ nhạc cụ', onBack: onBack),
    topBarGap: TempoSpace.lg,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _ProfileIntro(
          title: 'Mỗi nhạc cụ,\nmột hành trình.',
          subtitle: 'Những âm thanh làm nên bạn.',
        ),
        for (final profile in directory.profiles) ...[
          _ManagerRow(
            profile: profile,
            selected: directory.selectedProfileId == profile.id,
            onEdit: () => onEdit(profile),
            onDelete: () => onDelete(profile),
          ),
          const SizedBox(height: 13),
        ],
        const SizedBox(height: TempoSpace.lg),
        MeloopButton(
          label: 'Thêm hồ sơ',
          icon: MeloopIcons.plus,
          onPressed: onAdd,
        ),
        const SizedBox(height: TempoSpace.md),
        MeloopCard(
          child: Text(
            directory.isPro
                ? 'Meloop Pro cho phép thêm nhạc cụ theo cách của bạn.'
                : 'Miễn phí có tối đa 3 hồ sơ. Xóa một hồ sơ sẽ xóa vĩnh viễn nhật ký và bản ghi âm của hồ sơ đó.',
            style: TempoType.caption,
          ),
        ),
      ],
    ),
  );
}

class _ManagerRow extends StatelessWidget {
  const _ManagerRow({
    required this.profile,
    required this.selected,
    required this.onEdit,
    required this.onDelete,
  });

  final InstrumentProfile profile;
  final bool selected;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: _profileArtworkBackground,
      border: Border.all(color: TempoColors.line),
      borderRadius: BorderRadius.circular(TempoRadius.card),
    ),
    child: Row(
      children: [
        MeloopArt.instrument(
          MeloopInstrument.values[profile.instrumentType.index],
          size: 112,
          backgroundColor: _profileArtworkBackground,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: selected ? TempoColors.yellow : TempoColors.soft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  child: Text(
                    selected ? 'Đang chọn' : 'Hồ sơ khác',
                    style: TempoType.caption.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(profile.name, style: TempoType.title),
              Text(
                profile.instrumentLabel,
                style: TempoType.caption.copyWith(color: TempoColors.muted),
              ),
              Wrap(
                spacing: TempoSpace.md,
                children: [
                  TextButton(
                    key: Key('edit-profile-${profile.id}'),
                    onPressed: onEdit,
                    child: Text(
                      'Sửa tên',
                      style: TempoType.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  TextButton(
                    key: Key('delete-profile-${profile.id}'),
                    onPressed: onDelete,
                    child: Text(
                      'Xóa hồ sơ',
                      style: TempoType.caption.copyWith(
                        color: TempoColors.error,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ProfileIntro extends StatelessWidget {
  const _ProfileIntro({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 0, 4, 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TempoType.heading),
        const SizedBox(height: TempoSpace.sm),
        Text(
          subtitle,
          style: TempoType.body.copyWith(color: TempoColors.muted),
        ),
      ],
    ),
  );
}
