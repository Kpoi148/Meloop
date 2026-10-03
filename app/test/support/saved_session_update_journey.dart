import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/app/journal_providers.dart';
import 'package:meloop/app/profile_preview_app.dart';
import 'package:meloop/backend/database/journal_database_owner.dart';
import 'package:meloop/backend/journal/practice_timer.dart';
import 'package:meloop/backend/journal/sqlite_practice_timer_store.dart';
import 'package:meloop/frontend/components/meloop_ui.dart';
import 'package:meloop/frontend/practice_sessions/practice_session_card.dart';
import 'package:meloop/frontend/practice_sessions/practice_session_detail_page.dart';
import 'package:meloop/frontend/showcase/home_example.dart';
import 'package:meloop/frontend/showcase/session_form_example.dart';
import 'package:meloop/shared/journal/practice_timer_service.dart';
import 'package:sqflite/sqflite.dart';

import '../backend/database/journal_database_test.dart'
    show addProfile, sessionRow, sessionId;
import 'profile_draft_journey.dart' show DraftJourneyClock;

Future<void> runSavedSessionUpdateJourney(
  WidgetTester tester, {
  required JournalDatabaseOwner Function() createOwner,
  required PracticeScreenAwake Function() createScreenAwake,
}) async {
  var owner = createOwner();
  PracticeTimer makeTimer() => PracticeTimer(
    clock: DraftJourneyClock(),
    store: SqlitePracticeTimerStore(owner: owner),
    screenAwake: createScreenAwake(),
    schedulePulses: false,
  );
  var timer = makeTimer();
  Future<void> mount() => tester.pumpWidget(
    createJournalProfileApp(
      overrides: [
        journalDatabaseOwnerProvider.overrideWithValue(owner),
        journalPracticeTimerProvider.overrideWithValue(timer),
      ],
    ),
  );
  Future<void> waitFor(Finder finder) async {
    for (var i = 0; i < 150; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await tester.pump(const Duration(milliseconds: 50));
      if (finder.evaluate().isNotEmpty &&
          find.byType(CircularProgressIndicator).evaluate().isEmpty) {
        break;
      }
    }
    await tester.pumpAndSettle();
    expect(finder, findsOneWidget);
  }

  Future<void> tap(Finder finder) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await waitFor(finder);
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pump(const Duration(milliseconds: 400));
  }

  Finder tab(String label) => find.descendant(
    of: find.byType(MeloopBottomNavigation),
    matching: find.text(label),
  );
  Future<void> openHistory() async {
    await waitFor(find.byType(HomeExample));
    await tap(tab('Buổi luyện'));
  }

  try {
    await owner.read((executor) async {
      final db = executor as Database;
      await addProfile(db);
      await db.insert('practice_sessions', sessionRow(state: 'saved'));
    });
    await mount();
    await openHistory();
    await tap(find.byType(PracticeSessionCard));
    await tap(find.text('Sửa nhật ký'));
    await waitFor(find.byType(SessionFormExample));
    await tester.enterText(find.byType(TextFormField).at(0), 'Đã sửa QA');
    await tester.enterText(find.byType(TextFormField).at(1), '2');
    await owner.read(
      (db) => db.execute(
        "CREATE TRIGGER injected_edit BEFORE UPDATE ON practice_sessions BEGIN SELECT RAISE(ABORT,'injected'); END",
      ),
    );
    await tap(find.text('Lưu thay đổi'));
    await waitFor(find.textContaining('Chưa thể lưu buổi luyện.'));
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller!
          .text,
      'Đã sửa QA',
    );
    final old = await owner.read((db) => db.query('practice_sessions'));
    expect(old.single['title'], isNot('Đã sửa QA'));
    await owner.read((db) => db.execute('DROP TRIGGER injected_edit'));
    await tap(find.text('Lưu thay đổi'));
    await waitFor(find.byType(PracticeSessionDetailPage));
    expect(find.text('Đã sửa QA'), findsOneWidget);
    final saved = await owner.read((db) => db.query('practice_sessions'));
    expect(saved, hasLength(1));
    expect(saved.single['id'], sessionId);
    expect(saved.single['duration_seconds'], 120);
    expect(
      saved.single['measured_duration_seconds'],
      old.single['measured_duration_seconds'],
    );
    await tap(find.byTooltip('Quay lại'));
    await waitFor(find.widgetWithText(PracticeSessionCard, 'Đã sửa QA'));
    await tap(tab('Trang chủ'));
    await waitFor(find.byType(HomeExample));
    expect(
      tester
          .widget<HomeExample>(find.byType(HomeExample))
          .sessionSummary!
          .minutes,
      2,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await timer.close();
    await owner.close();
    owner = createOwner();
    timer = makeTimer();
    await mount();
    await openHistory();
    await waitFor(find.widgetWithText(PracticeSessionCard, 'Đã sửa QA'));
    expect(tester.takeException(), isNull);
  } finally {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await timer.close();
    await owner.close();
  }
}
