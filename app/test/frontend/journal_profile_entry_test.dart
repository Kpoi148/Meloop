import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/app/meloop_app.dart';
import 'package:meloop/frontend/application/app_settings_controller.dart';
import 'package:meloop/frontend/application/instrument_profile_service.dart';
import 'package:meloop/frontend/components/meloop_ui.dart';
import 'package:meloop/frontend/profiles/journal_profile_entry.dart';
import 'package:meloop/frontend/profiles/profile_screens.dart';
import 'package:meloop/frontend/showcase/meloop_ui_showcase.dart';
import 'package:meloop/frontend/showcase/profile_preview_service.dart';
import 'package:meloop/frontend/showcase/timer_example.dart';
import 'package:meloop/frontend/showcase/welcome_example.dart';
import 'package:meloop/shared/journal/journal_bootstrap.dart';
import 'package:meloop/shared/journal/journal_models.dart';
import 'package:meloop/shared/journal/practice_date.dart';
import 'package:meloop/shared/settings/app_settings_store.dart';

void main() {
  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> pump(
    WidgetTester tester,
    ProfilePreviewService service,
    JournalBootstrapLoader loader, {
    bool settle = true,
  }) async {
    await tester.pumpWidget(
      MeloopApp(
        overrides: [
          appSettingsStoreProvider.overrideWithValue(
            InMemoryAppSettingsStore(languageCode: 'vi'),
          ),
          instrumentProfileServiceProvider.overrideWithValue(service),
          journalBootstrapLoaderProvider.overrideWithValue(loader),
        ],
        home: const JournalProfileEntry(),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  Future<ProfilePreviewService> profiles(int count) async {
    final service = ProfilePreviewService();
    for (var n = 0; n < count; n++) {
      await service.create(
        requestId: 'request-$n',
        name: 'Nhạc cụ $n',
        instrumentType: InstrumentType.guitar,
        customType: '',
      );
    }
    return service;
  }

  for (final count in [0, 1, 2]) {
    testWidgets(
      'fresh entry with $count profiles follows SRS, including existing selection',
      (tester) async {
        final service = await profiles(count);
        await pump(
          tester,
          service,
          () async => JournalBootstrapSnapshot(directory: await service.load()),
        );
        expect(
          find.byType(WelcomeExample),
          count == 0 ? findsOneWidget : findsNothing,
        );
        expect(
          find.byType(ProfilePickerScreen),
          count == 2 ? findsOneWidget : findsNothing,
        );
        if (count == 2) {
          await tap(tester, find.byKey(const Key('select-profile-preview-1')));
          expect((await service.load()).selectedProfileId, 'preview-1');
        }
        if (count > 0) expect(find.byType(MeloopUiShowcase), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'load error has retry and cannot look like zero profiles; disposed load is safe',
    (tester) async {
      final service = await profiles(0);
      final pending = Completer<JournalBootstrapSnapshot>();
      var attempts = 0;
      await pump(tester, service, () async {
        if (++attempts == 1) return pending.future;
        return JournalBootstrapSnapshot(directory: await service.load());
      }, settle: false);
      expect(find.text('Đang mở hồ sơ…'), findsOneWidget);
      expect(find.byType(WelcomeExample), findsNothing);
      pending.completeError(StateError('Injected read failure'));
      await tester.pumpAndSettle();
      expect(find.text('Chưa thể mở hồ sơ trên thiết bị.'), findsOneWidget);
      expect(find.byType(WelcomeExample), findsNothing);
      await tap(tester, find.text('Thử lại'));
      expect(find.byType(WelcomeExample), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      final delayed = Completer<JournalBootstrapSnapshot>();
      await pump(tester, service, () => delayed.future, settle: false);
      await tester.pumpWidget(const SizedBox.shrink());
      delayed.complete(
        JournalBootstrapSnapshot(directory: await service.load()),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  for (final practiceState in [PracticeState.running, PracticeState.review]) {
    testWidgets(
      'draft recovery $practiceState preserves owner and time while browsing another profile',
      (tester) async {
        final service = await profiles(2);
        await service.select('preview-1');
        final now = DateTime.utc(2026, 10, 1);
        final draft = PracticeDraft(
          session: PracticeSession(
            id: '00000000-0000-4000-8000-000000000010',
            profileId: 'preview-1',
            state: practiceState,
            title: 'Luyện hợp âm',
            practiceDate: PracticeDate.parse('2026-10-01'),
            startOffsetMinutes: 420,
            createdAt: now,
            updatedAt: now,
          ),
          accumulatedMilliseconds: 754000,
          checkpointAt: now,
          updatedAt: now,
        );
        await pump(
          tester,
          service,
          () async => JournalBootstrapSnapshot(
            directory: await service.load(),
            draft: draft,
          ),
        );
        expect(find.byType(TimerExample), findsOneWidget);
        expect(find.text('12:34'), findsOneWidget);
        expect(
          find.text(
            practiceState == PracticeState.review ? 'Đang rà soát' : 'Tạm dừng',
          ),
          findsOneWidget,
        );
        final resume = tester.widget<MeloopButton>(
          find.widgetWithText(MeloopButton, 'Tiếp tục'),
        );
        expect(resume.onPressed, isNull);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        await tap(tester, find.byKey(const Key('choose-profile')));
        expect(find.byType(ProfilePickerScreen), findsOneWidget);
        await tap(tester, find.byKey(const Key('select-profile-preview-2')));
        expect((await service.load()).selectedProfileId, 'preview-2');
        expect(find.text('Tiếp tục · Nhạc cụ 0'), findsNothing);
        expect(find.text('Tạo buổi luyện'), findsOneWidget);
        await tap(tester, find.byKey(const Key('choose-profile')));
        await tap(tester, find.byKey(const Key('select-profile-preview-1')));
        expect(find.text('Tiếp tục · Nhạc cụ 0'), findsOneWidget);
        await tap(tester, find.text('Tiếp tục · Nhạc cụ 0'));
        expect(find.byType(TimerExample), findsOneWidget);
        expect(find.text('12:34'), findsOneWidget);
        expect(find.text('Nhạc cụ 0'), findsOneWidget);
        expect(find.text('Nhạc cụ 1'), findsNothing);
        expect(draft.session.profileId, 'preview-1');
        expect(tester.takeException(), isNull);
      },
    );
  }
}
