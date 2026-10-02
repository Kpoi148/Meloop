import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/app/journal_providers.dart';
import 'package:meloop/app/profile_preview_app.dart';
import 'package:meloop/backend/database/journal_database_owner.dart';
import 'package:meloop/backend/journal/practice_timer.dart';
import 'package:meloop/backend/journal/sqlite_instrument_profile_service.dart';
import 'package:meloop/backend/journal/sqlite_journal_readers.dart';
import 'package:meloop/backend/journal/sqlite_practice_timer_store.dart';
import 'package:meloop/frontend/components/meloop_ui.dart';
import 'package:meloop/frontend/practice/practice_instrument_art.dart';
import 'package:meloop/frontend/practice_sessions/practice_session_card.dart';
import 'package:meloop/frontend/practice_sessions/practice_session_detail_page.dart';
import 'package:meloop/frontend/practice_sessions/practice_sessions_tab.dart';
import 'package:meloop/frontend/profiles/profile_screens.dart';
import 'package:meloop/frontend/showcase/home_example.dart';
import 'package:meloop/frontend/showcase/session_form_example.dart';
import 'package:meloop/frontend/showcase/timer_example.dart';
import 'package:meloop/shared/journal/journal_models.dart';
import 'package:meloop/shared/journal/practice_timer_service.dart';
import 'package:meloop/shared/profiles/instrument_profile_service.dart';

class DraftJourneyClock implements MonotonicClock {
  int now = 0;
  @override
  int get elapsedMilliseconds => now;
}

/// Runs the same real UI/storage regression with host SQLite and Android SQLite.
Future<void> runProfileDraftJourney(
  WidgetTester tester, {
  required JournalDatabaseOwner Function() createOwner,
  required PracticeScreenAwake Function() createScreenAwake,
  Future<void> Function(String)? screenshot,
}) async {
  const guitarId = '00000000-0000-4000-8000-000000000001';
  const fluteId = '00000000-0000-4000-8000-000000000002';
  const guitarName = 'Guitar QA';
  const fluteName = 'Sáo QA';
  const guitarTitle = 'Buổi Guitar QA';
  const fluteTitle = 'Buổi Sáo QA';
  var owner = createOwner();
  final clock = DraftJourneyClock();
  PracticeTimer createTimer() => PracticeTimer(
    store: SqlitePracticeTimerStore(owner: owner),
    clock: clock,
    screenAwake: createScreenAwake(),
    schedulePulses: false,
  );
  var timer = createTimer();
  SqliteJournalSessionReader reader() => SqliteJournalSessionReader(owner);
  Future<void> waitFor(Finder finder) async {
    for (var i = 0; i < 150; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await tester.pump(const Duration(milliseconds: 50));
      if (finder.evaluate().isNotEmpty &&
          find.byType(CircularProgressIndicator).evaluate().isEmpty &&
          timer.snapshot?.busy != true) {
        break;
      }
    }
    await tester.pumpAndSettle();
    expect(finder, findsOneWidget);
  }

  Future<void> tap(Finder finder) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    // Android reports keyboard insets asynchronously; navigation appears only
    // after the keyboard has closed. Wait for the actual tappable widget.
    await waitFor(finder);
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    for (var i = 0; i < 150 && timer.snapshot?.busy == true; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Finder tab(String label) => find.descendant(
    of: find.byType(MeloopBottomNavigation),
    matching: find.text(label),
  );
  Future<void> mount() async => tester.pumpWidget(
    createJournalProfileApp(
      overrides: [
        journalDatabaseOwnerProvider.overrideWithValue(owner),
        journalPracticeTimerProvider.overrideWithValue(timer),
      ],
    ),
  );
  Future<void> choose(String id) async {
    await tap(find.byKey(const Key('choose-profile')));
    await waitFor(find.byType(ProfilePickerScreen));
    await tap(find.byKey(Key('select-profile-$id')));
    await waitFor(find.byType(HomeExample));
  }

  Future<void> start(String title) async {
    await tap(tab('Buổi luyện'));
    await waitFor(find.byType(PracticeSessionsTab));
    final create = find.byKey(const Key('practice-create'));
    expect(
      tester.getRect(create).bottom,
      lessThan(tester.getRect(find.byType(MeloopBottomNavigation)).top),
    );
    await tap(create);
    await waitFor(find.byType(TextFormField));
    await tester.enterText(find.byType(TextFormField), title);
    await tap(find.text('Bắt đầu luyện'));
    await waitFor(find.byType(TimerExample));
  }

  Future<void> save() async {
    await tap(find.text('Kết thúc'));
    await waitFor(find.byType(SessionFormExample));
    await tap(find.widgetWithText(MeloopButton, 'Lưu buổi luyện'));
    await waitFor(find.byType(PracticeSessionDetailPage));
    expect(find.text('Kết thúc'), findsNothing);
  }

  try {
    final profiles = SqliteInstrumentProfileService(
      owner: owner,
      initialLanguage: 'vi',
    );
    for (final (id, name, instrument) in [
      (guitarId, guitarName, InstrumentType.guitar),
      (fluteId, fluteName, InstrumentType.flute),
    ]) {
      await profiles.create(
        requestId: id,
        name: name,
        instrumentType: instrument,
        customType: '',
      );
    }
    await mount();
    await waitFor(find.byType(ProfilePickerScreen));
    await tap(find.byKey(const Key('select-profile-$guitarId')));
    await waitFor(find.byType(HomeExample));
    await start(guitarTitle);
    final guitarSession = timer.snapshot!.sessionId;
    clock.now += 32000;
    await tap(find.byTooltip('Quay lại'));
    await waitFor(find.byType(PracticeSessionsTab));
    expect(timer.snapshot!.elapsedMilliseconds, 32000);
    await tap(tab('Trang chủ'));
    await waitFor(find.byType(HomeExample));
    await choose(fluteId);
    expect(find.text('Tiếp tục · $guitarName'), findsNothing);
    expect(find.text('Tạo buổi luyện'), findsOneWidget);
    await start(fluteTitle);
    final fluteSession = timer.snapshot!.sessionId;
    expect(fluteSession, isNot(guitarSession));
    expect(timer.snapshot!.profileId, fluteId);
    for (final instrument in [
      tester
          .widget<PracticeProfileCover>(find.byType(PracticeProfileCover))
          .instrument,
      tester
          .widget<PracticeTimerArtwork>(find.byType(PracticeTimerArtwork))
          .instrument,
    ]) {
      expect(instrument, MeloopInstrument.flute);
    }
    clock.now += 41000;
    await tap(find.byTooltip('Quay lại'));
    await waitFor(find.byType(PracticeSessionsTab));
    expect(
      (await reader().unfinished(profileId: guitarId))!.accumulatedMilliseconds,
      32000,
    );
    expect(
      (await reader().unfinished(profileId: fluteId))!.accumulatedMilliseconds,
      41000,
    );
    expect(await reader().saved(profileId: fluteId), isEmpty);

    // Reopen the database and app with both unfinished sessions still present.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await timer.close();
    await owner.close();
    owner = createOwner();
    timer = createTimer();
    clock.now += 600000;
    await mount();
    await waitFor(find.byType(TimerExample));
    expect(timer.snapshot!.sessionId, fluteSession);
    expect(timer.snapshot!.state, PracticeState.paused);
    expect(find.text('00:41'), findsOneWidget);
    await screenshot?.call('profile-flute-recovered');
    await save();
    expect(find.text(fluteTitle), findsOneWidget);
    expect((await reader().saved(profileId: fluteId)).single.id, fluteSession);
    expect(await reader().unfinished(profileId: fluteId), isNull);
    expect(
      (await reader().unfinished(profileId: guitarId))!.session.id,
      guitarSession,
    );
    expect(
      (await reader().unfinished(profileId: guitarId))!.accumulatedMilliseconds,
      32000,
    );
    await tap(find.byTooltip('Trang chủ'));
    await waitFor(find.byType(HomeExample));
    await tap(tab('Buổi luyện'));
    await waitFor(find.widgetWithText(PracticeSessionCard, fluteTitle));
    expect(find.text(guitarTitle), findsNothing);
    await screenshot?.call('profile-flute-history');
    await tap(tab('Trang chủ'));
    await waitFor(find.byType(HomeExample));
    await choose(guitarId);
    expect(find.text('Tiếp tục · $guitarName'), findsOneWidget);
    await tap(find.text('Tiếp tục · $guitarName'));
    await waitFor(find.byType(TimerExample));
    expect(timer.snapshot!.sessionId, guitarSession);
    expect(timer.snapshot!.profileId, guitarId);
    expect(find.text('00:32'), findsOneWidget);
    await screenshot?.call('profile-guitar-preserved');
    await tap(find.text('Tiếp tục'));
    clock.now += 2000;
    await save();
    expect(find.text(guitarTitle), findsOneWidget);
    final saved = (await reader().saved(profileId: guitarId)).single;
    expect(saved.id, guitarSession);
    expect(saved.measuredDurationSeconds, 34);
    expect(await reader().unfinished(profileId: guitarId), isNull);
    expect(await reader().saved(profileId: fluteId), hasLength(1));
    expect(
      await owner.read((db) => db.query('practice_sessions')),
      hasLength(2),
    );
    await tap(find.byTooltip('Trang chủ'));
    await waitFor(find.byType(HomeExample));
    await tap(tab('Buổi luyện'));
    await waitFor(find.widgetWithText(PracticeSessionCard, guitarTitle));
    expect(find.text(fluteTitle), findsNothing);
    expect(tester.takeException(), isNull);
  } finally {
    await tester.pumpWidget(const SizedBox.shrink());
    await timer.close();
    await owner.close();
  }
}
