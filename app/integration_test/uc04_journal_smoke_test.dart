import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meloop/app/journal_providers.dart';
import 'package:meloop/backend/journal/sqlite_practice_review_service.dart';
import 'package:meloop/app/profile_preview_app.dart';
import 'package:meloop/backend/database/journal_database.dart';
import 'package:meloop/backend/database/journal_database_owner.dart';
import 'package:meloop/backend/journal/practice_timer.dart';
import 'package:meloop/backend/journal/practice_screen_awake.dart';
import 'package:meloop/backend/journal/sqlite_practice_timer_store.dart';
import 'package:meloop/backend/journal/sqlite_instrument_profile_service.dart';
import 'package:meloop/backend/journal/sqlite_journal_readers.dart';
import 'package:meloop/frontend/components/meloop_ui.dart';
import 'package:meloop/frontend/practice/practice_instrument_art.dart';
import 'package:meloop/frontend/practice/practice_tools_page.dart';
import 'package:meloop/frontend/practice_sessions/practice_session_detail_page.dart';
import 'package:meloop/frontend/practice_sessions/practice_session_card.dart';
import 'package:meloop/frontend/practice_sessions/practice_sessions_tab.dart';
import 'package:meloop/frontend/showcase/home_example.dart';
import 'package:meloop/frontend/showcase/timer_example.dart';
import 'package:meloop/frontend/showcase/session_form_example.dart';
import 'package:meloop/shared/journal/journal_models.dart';
import 'package:meloop/shared/journal/journal_runtime.dart';
import 'package:meloop/shared/journal/practice_review_service.dart';
import 'package:meloop/shared/profiles/instrument_profile_service.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'UC-04 Android: icon, instrument, tools, Review, duplicate Save, reopen and next Start',
    (tester) async {
      final path =
          '${await getDatabasesPath()}/uc04-test-${const UuidJournalIdentifiers().newId()}.db';
      final owner = JournalDatabaseOwner(
        open: () => JournalDatabase.open(path: path),
      );
      final timer = PracticeTimer(
        store: SqlitePracticeTimerStore(owner: owner),
        clock: StopwatchMonotonicClock(),
        screenAwake: AndroidPracticeScreenAwake(),
      );
      const profileId = '00000000-0000-4000-8000-000000000001';
      final pending = Completer<void>();
      var calls = 0;
      bool blockSave = false;
      final review = PendingReviewService(
        SqlitePracticeReviewService(owner: owner),
        () async {
          calls++;
          if (blockSave) await pending.future;
        },
      );
      Future<void> waitFor(Finder finder) async {
        for (var i = 0; i < 150 && finder.evaluate().isEmpty; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.pumpAndSettle();
        expect(finder, findsOneWidget);
      }

      Future<void> tap(Finder finder) async {
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        await tester.tap(finder);
        await tester.pumpAndSettle();
        for (var i = 0; i < 150 && timer.snapshot?.busy == true; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
      }

      try {
        await SqliteInstrumentProfileService(
          owner: owner,
          initialLanguage: 'vi',
        ).create(
          requestId: profileId,
          name: 'Sáo UC04 QA',
          instrumentType: InstrumentType.flute,
          customType: '',
        );
        await tester.pumpWidget(
          createJournalProfileApp(
            overrides: [
              journalDatabaseOwnerProvider.overrideWithValue(owner),
              journalPracticeTimerProvider.overrideWithValue(timer),
              journalReviewServiceProvider.overrideWithValue(review),
            ],
          ),
        );
        await waitFor(find.byType(HomeExample));
        final sessionsTab = find.descendant(
          of: find.byType(MeloopBottomNavigation),
          matching: find.text('Buổi luyện'),
        );
        await tap(sessionsTab);
        await waitFor(find.byType(PracticeSessionsTab));
        final create = find.byKey(const Key('practice-create'));
        expect(
          tester.getRect(create).bottom,
          lessThan(tester.getRect(find.byType(MeloopBottomNavigation)).top),
        );
        await tap(create);
        await tester.enterText(
          find.byType(TextFormField),
          'UC04 lưu đúng một buổi',
        );
        await tap(find.text('Bắt đầu luyện'));
        await waitFor(find.byType(TimerExample));
        expect(
          tester
              .widget<PracticeProfileCover>(find.byType(PracticeProfileCover))
              .instrument,
          MeloopInstrument.flute,
        );
        expect(
          tester
              .widget<PracticeTimerArtwork>(find.byType(PracticeTimerArtwork))
              .instrument,
          MeloopInstrument.flute,
        );
        final sessionId = timer.snapshot!.sessionId;
        await tester.pump(const Duration(seconds: 2));
        await tap(find.text('Công cụ'));
        expect(find.byType(PracticeToolsPage), findsOneWidget);
        expect(timer.snapshot!.sessionId, sessionId);
        await tap(find.byTooltip('Quay lại'));
        await waitFor(find.byType(TimerExample));
        await tap(find.text('Tạm dừng'));
        expect(timer.snapshot!.state, PracticeState.paused);
        final frozen = timer.snapshot!.elapsedMilliseconds;
        await tester.pump(const Duration(seconds: 2));
        expect(timer.snapshot!.elapsedMilliseconds, frozen);
        await tap(find.text('Tiếp tục'));
        expect(timer.snapshot!.state, PracticeState.running);
        await binding.convertFlutterSurfaceToImage();
        await tester.pump();
        await binding.takeScreenshot('uc04-flute-timer');
        await tap(find.text('Kết thúc'));
        await waitFor(find.byType(SessionFormExample));
        expect(timer.snapshot!.state, PracticeState.review);
        final reader = SqliteJournalSessionReader(owner);
        expect(
          (await reader.unfinished())!.session.state,
          PracticeState.review,
        );
        // Keep Save pending to prove repeated taps cannot send another commit.
        blockSave = true;
        final saveButton = find.widgetWithText(MeloopButton, 'Lưu buổi luyện');
        await tester.ensureVisible(saveButton);
        await tester.tap(saveButton);
        await tester.pump();
        await tester.tap(find.byType(MeloopButton).last);
        await tester.pump();
        expect(calls, 1);
        pending.complete();
        await waitFor(find.byType(PracticeSessionDetailPage));
        expect(await reader.saved(profileId: profileId), hasLength(1));
        expect(await reader.unfinished(), isNull);
        expect(timer.snapshot, isNull);
        expect(find.text('Kết thúc'), findsNothing);
        await binding.takeScreenshot('uc04-saved-detail');
        await tap(find.byTooltip('Trang chủ'));
        await waitFor(find.byType(HomeExample));
        await tap(sessionsTab);
        final savedCard = find.widgetWithText(
          PracticeSessionCard,
          'UC04 lưu đúng một buổi',
        );
        await waitFor(savedCard);
        await binding.takeScreenshot('uc04-saved-history');
        await tap(savedCard);
        await waitFor(find.byType(PracticeSessionDetailPage));
        await tap(find.byTooltip('Quay lại'));
        await waitFor(find.byType(PracticeSessionsTab));
        expect(savedCard, findsOneWidget);
        await tap(create);
        await tester.enterText(find.byType(TextFormField), 'Buổi tiếp theo');
        await tap(find.text('Bắt đầu luyện'));
        await waitFor(find.byType(TimerExample));
        expect(timer.snapshot!.sessionId, isNot(sessionId));
        expect(await reader.saved(profileId: profileId), hasLength(1));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await timer.close();
        await owner.close();
        final reopened = JournalDatabaseOwner(
          open: () => JournalDatabase.open(path: path),
        );
        try {
          expect(
            await SqliteJournalSessionReader(reopened)
                .saved(profileId: profileId),
            hasLength(1),
          );
        } finally {
          await reopened.close();
        }
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await timer.close();
        await owner.close();
        await deleteDatabase(path);
      }
    },
  );
}

class PendingReviewService implements PracticeReviewService {
  PendingReviewService(this.delegate, this.beforeSave);
  final PracticeReviewService delegate;
  final Future<void> Function() beforeSave;
  @override
  Future<PracticeDraft> read(String id) => delegate.read(id);
  @override
  Future<String> rename(String id, String title) => delegate.rename(id, title);
  @override
  Future<void> persistInput(String id, ReviewInput input) =>
      delegate.persistInput(id, input);
  @override
  Future<PracticeSession> save(String id, PracticeReviewValues values) async {
    await beforeSave();
    return delegate.save(id, values);
  }
}
