import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/app/meloop_app.dart';
import 'package:meloop/frontend/application/instrument_profile_service.dart';
import 'package:meloop/frontend/profiles/instrument_profiles_feature.dart';
import 'package:meloop/frontend/profiles/profile_form.dart';
import 'package:meloop/frontend/showcase/profile_preview_service.dart';

void main() {
  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> pumpFeature(
    WidgetTester tester,
    InstrumentProfileService service, {
    ProfileEntryPage entryPage = ProfileEntryPage.automatic,
    List<InstrumentProfile>? opened,
    VoidCallback? onViewPro,
  }) async {
    await tester.pumpWidget(
      MeloopApp(
        overrides: [
          instrumentProfileServiceProvider.overrideWithValue(service),
        ],
        home: InstrumentProfilesFeature(
          entryPage: entryPage,
          onOpenHome: (profile) => opened?.add(profile),
          onViewPro: onViewPro ?? () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> seed(
    ProfilePreviewService service,
    String name,
    InstrumentType type,
  ) async {
    await service.create(
      requestId: name,
      name: name,
      instrumentType: type,
      customType: '',
    );
  }

  testWidgets('create selects a profile without a practice session', (
    tester,
  ) async {
    final service = ProfilePreviewService();
    final opened = <InstrumentProfile>[];
    await pumpFeature(tester, service, opened: opened);
    await tapVisible(tester, find.text('Tạo hồ sơ đầu tiên'));

    expect(find.byKey(const Key('profile-type-guitar')), findsOneWidget);
    await tapVisible(tester, find.byKey(const Key('profile-type-guitar')));
    final field = tester.widget<TextFormField>(find.byType(TextFormField).last);
    expect(field.controller!.text, 'Guitar của tôi');
    await tapVisible(tester, find.byKey(const Key('save-profile')));

    final directory = await service.load();
    expect(directory.profiles, hasLength(1));
    expect(directory.selectedProfileId, directory.profiles.first.id);
    expect(directory.profiles.first.savedSessionCount, 0);
    expect(opened.single.id, directory.profiles.first.id);
  });

  testWidgets('rename exposes immutable type and retains profile identity', (
    tester,
  ) async {
    final service = ProfilePreviewService();
    await seed(service, 'Guitar của tôi', InstrumentType.guitar);
    await pumpFeature(tester, service, entryPage: ProfileEntryPage.manager);
    await tapVisible(tester, find.byKey(const Key('edit-profile-preview-1')));

    expect(find.text('Loại nhạc cụ'), findsOneWidget);
    expect(find.byKey(const Key('profile-type-piano')), findsNothing);
    await tester.enterText(find.byType(TextFormField).last, 'Guitar buổi tối');
    await tapVisible(tester, find.byKey(const Key('save-profile')));

    final profile = (await service.load()).profiles.single;
    expect(profile.id, 'preview-1');
    expect(profile.name, 'Guitar buổi tối');
    expect(profile.instrumentType, InstrumentType.guitar);
  });

  testWidgets('Free limit offers Pro without locking existing profiles', (
    tester,
  ) async {
    final service = ProfilePreviewService();
    await seed(service, 'Guitar', InstrumentType.guitar);
    await seed(service, 'Piano', InstrumentType.piano);
    await seed(service, 'Sáo', InstrumentType.flute);
    var proOpened = false;
    await pumpFeature(
      tester,
      service,
      entryPage: ProfileEntryPage.manager,
      onViewPro: () => proOpened = true,
    );
    expect(find.byKey(const Key('edit-profile-preview-1')), findsOneWidget);
    expect(find.byKey(const Key('delete-profile-preview-1')), findsOneWidget);
    await tapVisible(tester, find.text('Thêm hồ sơ'));
    expect(find.text('Đã đủ 3 hồ sơ'), findsOneWidget);
    await tapVisible(tester, find.text('Xem Meloop Pro'));
    expect(proOpened, isTrue);
    expect((await service.load()).profiles, hasLength(3));
  });

  testWidgets('delete confirms scope and selects a remaining profile', (
    tester,
  ) async {
    final service = _ImpactPreviewService();
    await seed(service, 'Guitar', InstrumentType.guitar);
    await seed(service, 'Piano', InstrumentType.piano);
    final opened = <InstrumentProfile>[];
    await pumpFeature(
      tester,
      service,
      entryPage: ProfileEntryPage.manager,
      opened: opened,
    );
    await tapVisible(tester, find.byKey(const Key('delete-profile-preview-2')));
    expect(find.textContaining('5 buổi luyện'), findsOneWidget);
    expect(find.textContaining('2 bản ghi âm'), findsOneWidget);
    await tapVisible(tester, find.text('Giữ hồ sơ'));
    expect((await service.load()).profiles, hasLength(2));

    await tapVisible(tester, find.byKey(const Key('delete-profile-preview-2')));
    await tapVisible(tester, find.text('Xóa hồ sơ').last);
    final directory = await service.load();
    expect(directory.profiles.map((profile) => profile.id), ['preview-1']);
    expect(directory.selectedProfileId, 'preview-1');
    expect(opened.last.id, 'preview-1');
  });

  testWidgets('failed creation retains the form and retries with same input', (
    tester,
  ) async {
    final service = _FailOnceService();
    await pumpFeature(tester, service);
    await tapVisible(tester, find.text('Tạo hồ sơ đầu tiên'));
    await tapVisible(tester, find.byKey(const Key('profile-type-violin')));
    await tester.enterText(find.byType(TextFormField).last, 'Violin sáng');
    await tapVisible(tester, find.byKey(const Key('save-profile')));

    expect(find.textContaining('Nội dung của bạn vẫn ở đây'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).last)
          .controller!
          .text,
      'Violin sáng',
    );
    await tapVisible(tester, find.byKey(const Key('save-profile')));
    expect((await service.load()).profiles.single.name, 'Violin sáng');
    expect(service.requestIds, hasLength(2));
    expect(service.requestIds.first, service.requestIds.last);
  });

  testWidgets('switching profile only updates selection', (tester) async {
    final service = _SelectionSpyService();
    await seed(service, 'Guitar', InstrumentType.guitar);
    await seed(service, 'Piano', InstrumentType.piano);
    final opened = <InstrumentProfile>[];
    await pumpFeature(
      tester,
      service,
      entryPage: ProfileEntryPage.picker,
      opened: opened,
    );
    await tapVisible(tester, find.byKey(const Key('select-profile-preview-1')));
    expect(service.selectedIds, ['preview-1']);
    expect((await service.load()).profiles, hasLength(2));
    expect(opened.last.instrumentType, InstrumentType.guitar);
  });

  testWidgets('Other keeps its name while changing instrument choices', (
    tester,
  ) async {
    final service = ProfilePreviewService();
    await pumpFeature(tester, service);
    await tapVisible(tester, find.text('Tạo hồ sơ đầu tiên'));
    await tapVisible(tester, find.byKey(const Key('profile-type-other')));
    await tester.enterText(find.byType(TextFormField).first, 'Saxophone');
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).last)
          .controller!
          .text,
      'Saxophone của tôi',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(const Key('profile-type-guitar')));
    expect(find.byType(TextFormField), findsOneWidget);
    await tapVisible(tester, find.byKey(const Key('profile-type-other')));
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller!
          .text,
      'Saxophone',
    );
    await tapVisible(tester, find.byKey(const Key('save-profile')));
    final profile = (await service.load()).profiles.single;
    expect(profile.instrumentType, InstrumentType.other);
    expect(profile.customType, 'Saxophone');
    expect(profile.name, 'Saxophone của tôi');
  });

  testWidgets('form keeps primary action reachable at 360 dp and 200% text', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      MeloopApp(
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: ProfileForm(
              onBack: () {},
              onCreate: (_, _, _, _) async {},
              onRename: (_, _) async {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('save-profile')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('save-profile')), findsOneWidget);
  });
}

class _FailOnceService extends ProfilePreviewService {
  bool shouldFail = true;
  final requestIds = <String>[];

  @override
  Future<ProfileDirectory> create({
    required String requestId,
    required String name,
    required InstrumentType instrumentType,
    required String customType,
  }) async {
    requestIds.add(requestId);
    if (shouldFail) {
      shouldFail = false;
      throw const ProfileServiceException(ProfileServiceError.storage);
    }
    return super.create(
      requestId: requestId,
      name: name,
      instrumentType: instrumentType,
      customType: customType,
    );
  }
}

class _SelectionSpyService extends ProfilePreviewService {
  final selectedIds = <String>[];

  @override
  Future<ProfileDirectory> select(String profileId) {
    selectedIds.add(profileId);
    return super.select(profileId);
  }
}

class _ImpactPreviewService extends ProfilePreviewService {
  @override
  Future<ProfileDeletionImpact> deletionImpact(String profileId) async =>
      const ProfileDeletionImpact(savedSessionCount: 5, recordingCount: 2);
}
