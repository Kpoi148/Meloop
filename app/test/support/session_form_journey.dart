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
import 'package:meloop/frontend/practice_sessions/practice_session_card.dart';
import 'package:meloop/frontend/practice_sessions/practice_session_detail_page.dart';
import 'package:meloop/frontend/showcase/home_example.dart';
import 'package:meloop/frontend/showcase/session_form_example.dart';
import 'package:meloop/frontend/showcase/timer_example.dart';
import 'package:meloop/shared/journal/practice_timer_service.dart';
import 'package:meloop/shared/profiles/instrument_profile_service.dart';

import 'profile_draft_journey.dart' show DraftJourneyClock;

Future<void> runSessionFormJourney(
  WidgetTester tester, {
  required JournalDatabaseOwner Function() createOwner,
  required PracticeScreenAwake Function() createScreenAwake,
  Future<void> Function(String)? screenshot,
}) async {
  const profile = '00000000-0000-4000-8000-000000000001';
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
  Future<void> mount() => tester.pumpWidget(
    createJournalProfileApp(
      overrides: [
        journalDatabaseOwnerProvider.overrideWithValue(owner),
        journalPracticeTimerProvider.overrideWithValue(timer),
      ],
    ),
  );
  Future<void> waitFor(Finder finder) async {
    for (var attempt = 0; attempt < 150; attempt++) {
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
    await waitFor(finder);
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> enter(Finder finder, String text) async {
    await waitFor(finder);
    await tester.ensureVisible(finder);
    await tester.enterText(finder, text);
    await tester.pump();
  }

  Finder duration(String part) => find.byKey(Key('session-duration-$part'));
  Finder practiced() => find.ancestor(
    of: find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.hintText == 'Gam, hợp âm, bài nhạc…',
    ),
    matching: find.byType(TextFormField),
  );

  try {
    await SqliteInstrumentProfileService(
      owner: owner,
      initialLanguage: 'vi',
    ).create(
      requestId: profile,
      name: 'Guitar QA',
      instrumentType: InstrumentType.guitar,
      customType: '',
    );
    await mount();
    await waitFor(find.byType(HomeExample));
    await tap(
      find.descendant(
        of: find.byType(MeloopBottomNavigation),
        matching: find.text('Buổi luyện'),
      ),
    );
    await tap(find.byKey(const Key('practice-create')));
    await enter(find.byType(TextFormField), 'Buổi luyện form QA');
    await tap(find.text('Bắt đầu luyện'));
    await waitFor(find.byType(TimerExample));
    final id = timer.snapshot!.sessionId;
    clock.now += 7000;
    await tap(find.text('Kết thúc'));
    await waitFor(find.byType(SessionFormExample));
    expect(
      tester.widget<TextFormField>(duration('seconds')).controller!.text,
      '7',
    );
    await enter(duration('seconds'), '1.5');
    await enter(duration('hours'), '');
    await enter(duration('minutes'), '-1');
    await enter(practiced(), 'Ghi chú\nchưa lưu');
    await enter(find.byType(TextFormField).at(5), 'Khó\nchưa xong');
    await enter(find.byType(TextFormField).at(6), '  Lần sau  ');
    await enter(find.byType(TextFormField).at(7), 'bad');
    await owner.read((_) async {});
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tap(find.text('Tiếp tục sửa'));
    expect(
      tester.widget<TextFormField>(duration('seconds')).controller!.text,
      '1.5',
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tap(find.text('Quay lại buổi luyện').last);
    await waitFor(find.byType(TimerExample));
    final draft = (await reader().unfinished(sessionId: id))!;
    expect(draft.reviewInput!.durationSecondsInput, '1.5');
    expect(draft.reviewInput!.durationHoursInput, '');
    expect(draft.reviewInput!.durationMinutesInput, '-1');
    expect(draft.reviewInput!.bpmInput, 'bad');
    expect(draft.reviewInput!.practiced, 'Ghi chú\nchưa lưu');
    expect(await reader().saved(profileId: profile), isEmpty);
    // Reopen the actual app/storage before reviewing again.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await timer.close();
    await owner.close();
    owner = createOwner();
    timer = createTimer();
    await mount();
    await waitFor(find.byType(TimerExample));
    await tap(find.text('Kết thúc'));
    await waitFor(find.byType(SessionFormExample));
    expect(
      tester.widget<TextFormField>(duration('seconds')).controller!.text,
      '1.5',
    );
    expect(
      tester.widget<TextFormField>(practiced()).controller!.text,
      'Ghi chú\nchưa lưu',
    );
    expect(
      tester.widget<TextFormField>(duration('hours')).controller!.text,
      '',
    );
    expect(
      tester.widget<TextFormField>(duration('minutes')).controller!.text,
      '-1',
    );
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).at(5))
          .controller!
          .text,
      'Khó\nchưa xong',
    );
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).at(6))
          .controller!
          .text,
      '  Lần sau  ',
    );
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).at(7))
          .controller!
          .text,
      'bad',
    );
    await enter(duration('hours'), '0');
    await enter(duration('minutes'), '0');
    await enter(duration('seconds'), '30');
    await enter(find.byType(TextFormField).at(7), '');
    await screenshot?.call('task19-review');
    await tap(find.widgetWithText(MeloopButton, 'Lưu buổi luyện'));
    await waitFor(find.byType(PracticeSessionDetailPage));
    final saved = (await reader().saved(profileId: profile)).single;
    expect(saved.id, id);
    expect(saved.durationSeconds, 30);
    expect(saved.measuredDurationSeconds, 7);
    expect(saved.mood, isNull);
    expect(saved.focus, isNull);
    expect(await reader().unfinished(profileId: profile), isNull);
    await tap(find.text('Sửa nhật ký'));
    await waitFor(find.byType(SessionFormExample));
    expect(find.text('Nhạc cụ: Guitar QA'), findsOneWidget);
    expect(find.text('Ghi âm'), findsNothing);
    await enter(find.byType(TextFormField).first, 'Buổi đã sửa QA');
    await enter(duration('seconds'), '45');
    await owner.read(
      (db) => db.execute(
        "CREATE TRIGGER injected_edit BEFORE UPDATE ON practice_sessions BEGIN SELECT RAISE(ABORT,'injected'); END",
      ),
    );
    await tap(find.widgetWithText(MeloopButton, 'Lưu thay đổi'));
    await waitFor(find.textContaining('Chưa thể lưu buổi luyện.'));
    expect(
      (await reader().saved(profileId: profile)).single.title,
      'Buổi luyện form QA',
    );
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller!
          .text,
      'Buổi đã sửa QA',
    );
    await screenshot?.call('task19-edit-retry');
    await owner.read((db) => db.execute('DROP TRIGGER injected_edit'));
    await tap(find.widgetWithText(MeloopButton, 'Thử lại'));
    await waitFor(find.byType(PracticeSessionDetailPage));
    expect(find.text('Buổi đã sửa QA'), findsOneWidget);
    await screenshot?.call('task19-edited-detail');
    final edited = (await reader().saved(profileId: profile)).single;
    expect(edited.id, id);
    expect(edited.profileId, profile);
    expect(edited.durationSeconds, 45);
    expect(edited.measuredDurationSeconds, 7);
    expect(edited.practiced, 'Ghi chú\nchưa lưu');
    await tap(find.byTooltip('Trang chủ'));
    await waitFor(find.byType(HomeExample));
    await tap(
      find.descendant(
        of: find.byType(MeloopBottomNavigation),
        matching: find.text('Buổi luyện'),
      ),
    );
    await waitFor(find.widgetWithText(PracticeSessionCard, 'Buổi đã sửa QA'));
    await owner.close();
    owner = createOwner();
    expect(
      (await reader().saved(profileId: profile)).single.title,
      'Buổi đã sửa QA',
    );
    expect(tester.takeException(), isNull);
  } finally {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await timer.close();
    await owner.close();
  }
}
