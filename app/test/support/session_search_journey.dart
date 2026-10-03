import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/app/journal_practice_adapter.dart';
import 'package:meloop/app/journal_providers.dart';
import 'package:meloop/app/profile_preview_app.dart';
import 'package:meloop/backend/database/journal_database_owner.dart';
import 'package:meloop/backend/journal/sqlite_journal_readers.dart';
import 'package:meloop/frontend/practice_sessions/practice_session.dart';
import 'package:meloop/frontend/practice_sessions/practice_session_card.dart';
import 'package:meloop/frontend/practice_sessions/practice_sessions_controller.dart';
import 'package:meloop/frontend/profiles/profile_screens.dart';
import 'package:meloop/shared/journal/journal_text.dart';
import 'package:meloop/shared/journal/practice_date.dart';

/// Disposable SQLite fixtures exercise the production loader and existing UI.
Future<void> runSessionSearchJourney(
  WidgetTester tester,
  JournalDatabaseOwner owner,
) async {
  const profile = '00000000-0000-4000-8000-000000000001';
  const other = '00000000-0000-4000-8000-000000000002';
  final today = DateTime(2026, 10, 3);

  await owner.transaction((db) async {
    for (final id in [profile, other]) {
      await db.insert('instrument_profiles', {
        'id': id,
        'name': id == profile ? 'Search Guitar QA' : 'Search Flute QA',
        'name_key': id,
        'instrument_type': 'guitar',
        'created_at': today.millisecondsSinceEpoch,
        'updated_at': today.millisecondsSinceEpoch,
      });
    }
    for (var i = 0; i < 9; i++) {
      final day = [0, 6, 7, 29, 30, -1, 0, 0, 0][i];
      final title = i == 7 ? 'Đàn Straße 100%_\\' : 'Luyện gam QA $i';
      final practiced = i == 0 ? 'Chuyển hợp âm' : 'Đều nhịp';
      final difficulty = i == 0 ? 'Khó đổi dây' : 'foo';
      final next = i == 0 ? 'Ôn đoạn cuối' : 'bar';
      await db.insert('practice_sessions', {
        'id': '00000000-0000-4000-8000-00000000001$i',
        'profile_id': i == 6 ? other : profile,
        'state': i == 8 ? 'review' : 'saved',
        'title': title,
        'title_search': JournalText.searchKey(title),
        'practice_date': PracticeDate.fromLocal(
          DateTime(today.year, today.month, today.day - day),
        ).value,
        'start_offset_minutes': 420,
        if (i != 8) 'duration_seconds': 60,
        'measured_duration_seconds': 60,
        'practiced': practiced,
        'practiced_search': JournalText.searchKey(practiced),
        'difficulty': difficulty,
        'difficulty_search': JournalText.searchKey(difficulty),
        'next_note': next,
        'next_search': JournalText.searchKey(next),
        'created_at': today.millisecondsSinceEpoch,
        'updated_at': today.millisecondsSinceEpoch,
      });
    }
  });
  final reader = SqliteJournalSessionReader(owner);
  final records = (await reader.saved(profileId: profile))
      .map(presentPracticeSession)
      .toList();
  for (final period in PracticePeriod.values) {
    final days = period.days;
    final from = days == null
        ? null
        : PracticeDate.fromLocal(
            DateTime(today.year, today.month, today.day - days + 1),
          );
    for (final query in [
      '',
      'LUYEN',
      'chuyen',
      'kho doi',
      'on doan',
      'ĐÀN',
      'STRASSE',
      '%',
      '_',
      '\\',
      'foo bar',
      'không có',
    ]) {
      final state = PracticeSessionsViewState(
        query: query,
        filters: PracticeSessionFilters(period: period),
      );
      final visible = state.visibleSessions(
        records,
        profileId: profile,
        now: today,
      );
      final stored = await reader.saved(
        profileId: profile,
        from: from,
        through: PracticeDate.fromLocal(today),
        query: query,
      );
      expect(
        visible.map((s) => s.id).toSet(),
        stored.map((s) => s.id).toSet(),
        reason: '$period / $query',
      );
    }
    final recent = PracticeSessionsViewState(
      filters: PracticeSessionFilters(period: period),
    ).visibleSessions(records, profileId: profile, now: today);
    final oldest = PracticeSessionsViewState(
      filters: PracticeSessionFilters(
        period: period,
        order: PracticeOrder.oldest,
      ),
    ).visibleSessions(records, profileId: profile, now: today);
    expect(oldest.map((s) => s.id), recent.reversed.map((s) => s.id));
    expect(
      recent.length,
      {
        PracticePeriod.all: 6,
        PracticePeriod.week: 3,
        PracticePeriod.month: 5,
      }[period],
    );
  }

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
    expect(
      finder,
      findsOneWidget,
      reason: tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .join(' | '),
    );
  }

  // The query matrix includes an unfinished fixture. The following UI journey
  // exercises Saved search only, without starting the timer recovery flow.
  await owner.transaction(
    (db) => db.delete(
      'practice_sessions',
      where: 'id = ?',
      whereArgs: ['00000000-0000-4000-8000-000000000018'],
    ),
  );
  await tester.pumpWidget(
    createJournalProfileApp(
      overrides: [
        journalDatabaseOwnerProvider.overrideWithValue(owner),
        practiceSessionsClockProvider.overrideWithValue(() => today),
      ],
    ),
  );
  await waitFor(find.byType(ProfilePickerScreen));
  await tester.tap(find.byKey(const Key('select-profile-$profile')));
  await waitFor(find.byKey(const Key('overview-count')));
  await tester.tap(find.text('Buổi luyện').last);
  await waitFor(find.byType(TextField));
  await tester.enterText(find.byType(TextField), 'kho doi');
  await waitFor(find.widgetWithText(PracticeSessionCard, 'Luyện gam QA 0'));
  expect(find.byType(PracticeSessionCard), findsOneWidget);
  await tester.enterText(find.byType(TextField), 'strasse');
  await waitFor(find.widgetWithText(PracticeSessionCard, 'Đàn Straße 100%_\\'));
  expect(find.byType(PracticeSessionCard), findsOneWidget);
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}
