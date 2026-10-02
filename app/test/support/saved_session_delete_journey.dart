import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/app/journal_providers.dart';
import 'package:meloop/app/profile_preview_app.dart';
import 'package:meloop/backend/database/journal_database_owner.dart';
import 'package:meloop/backend/journal/practice_timer.dart';
import 'package:meloop/backend/journal/sqlite_instrument_profile_service.dart';
import 'package:meloop/backend/journal/sqlite_journal_readers.dart';
import 'package:meloop/backend/journal/sqlite_practice_review_service.dart';
import 'package:meloop/backend/journal/sqlite_practice_start_service.dart';
import 'package:meloop/backend/journal/sqlite_practice_timer_store.dart';
import 'package:meloop/frontend/components/meloop_ui.dart';
import 'package:meloop/frontend/practice_sessions/practice_session_card.dart';
import 'package:meloop/frontend/practice_sessions/practice_session_detail_page.dart';
import 'package:meloop/frontend/practice_sessions/practice_sessions_tab.dart';
import 'package:meloop/frontend/profiles/profile_screens.dart';
import 'package:meloop/frontend/showcase/home_example.dart';
import 'package:meloop/shared/journal/practice_date.dart';
import 'package:meloop/shared/journal/practice_review_service.dart';
import 'package:meloop/shared/journal/practice_timer_service.dart';
import 'package:meloop/shared/profiles/instrument_profile_service.dart';

import 'profile_draft_journey.dart' show DraftJourneyClock;

/// Exercises the real app's injected delete action on host and Android SQLite.
Future<void> runSavedSessionDeleteJourney(
  WidgetTester tester, {
  required JournalDatabaseOwner Function() createOwner,
  required PracticeScreenAwake Function() createScreenAwake,
  Future<void> Function(String)? screenshot,
}) async {
  const guitar = '00000000-0000-4000-8000-000000000001';
  const flute = '00000000-0000-4000-8000-000000000002';
  const audioSession = '00000000-0000-4000-8000-000000000011';
  const plainSession = '00000000-0000-4000-8000-000000000012';
  const fluteSession = '00000000-0000-4000-8000-000000000013';
  const fluteDraft = '00000000-0000-4000-8000-000000000014';
  const recording = '00000000-0000-4000-8000-000000000021';
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

  Finder tab(String label) => find.descendant(
    of: find.byType(MeloopBottomNavigation),
    matching: find.text(label),
  );
  Future<void> openDelete() =>
      tap(find.widgetWithText(MeloopButton, 'Xóa buổi luyện'));
  Finder confirm() => find.descendant(
    of: find.byType(Dialog),
    matching: find.text('Xóa buổi luyện'),
  );
  Future<void> seedSaved(
    String id,
    String profile,
    String title, {
    bool audio = false,
  }) async {
    final draft = await SqlitePracticeStartService(owner: owner)
        .start(requestId: id, profileId: profile, title: title);
    await timer.open(draft, newlyStarted: true);
    if (audio) {
      await owner.transaction(
        (db) => db.insert('recordings', {
          'id': recording,
          'session_id': id,
          'status': 'ready',
          'local_relative_path': 'qa/retained.m4a',
          'filename': 'retained.m4a',
          'duration_ms': 1000,
          'size_bytes': 12000,
          'sample_rate_hz': 44100,
          'channel_count': 1,
          'created_at': draft.session.createdAt.millisecondsSinceEpoch,
          'updated_at': draft.session.updatedAt.millisecondsSinceEpoch,
        }),
      );
    }
    clock.now += 120000;
    await timer.finish();
    await SqlitePracticeReviewService(owner: owner).save(
      id,
      PracticeReviewValues(
        title: title,
        date: PracticeDate.fromLocal(DateTime.now()),
        durationSeconds: 120,
        practiced: 'Nội dung QA',
        difficulty: '',
        next: '',
        mood: 4,
        focus: 5,
        bpm: 80,
      ),
    );
    await timer.complete(id);
  }

  try {
    final profiles = SqliteInstrumentProfileService(
      owner: owner,
      initialLanguage: 'vi',
    );
    for (final (id, name, instrument) in [
      (guitar, 'Guitar QA', InstrumentType.guitar),
      (flute, 'Sáo QA', InstrumentType.flute),
    ]) {
      await profiles.create(
        requestId: id,
        name: name,
        instrumentType: instrument,
        customType: '',
      );
    }
    await seedSaved(audioSession, guitar, 'Buổi có bản ghi QA', audio: true);
    await seedSaved(plainSession, guitar, 'Buổi thường QA');
    await seedSaved(fluteSession, flute, 'Buổi Sáo QA');
    final draft = await SqlitePracticeStartService(
      owner: owner,
    ).start(requestId: fluteDraft, profileId: flute, title: 'Sáo chưa lưu QA');
    await timer.open(draft, newlyStarted: true);
    clock.now += 12000;
    await timer.pause();
    await profiles.select(guitar);
    final recordingsBefore = await owner.read((db) => db.query('recordings'));
    await mount();
    await waitFor(find.byType(ProfilePickerScreen));
    await tap(find.byKey(const Key('select-profile-$guitar')));
    await waitFor(find.byType(HomeExample));
    await tap(tab('Buổi luyện'));
    await waitFor(
      find.widgetWithText(PracticeSessionCard, 'Buổi có bản ghi QA'),
    );
    await tap(tab('Trang chủ'));
    await waitFor(find.byType(HomeExample));
    expect(
      tester
          .widget<HomeExample>(find.byType(HomeExample))
          .sessionSummary!
          .count,
      2,
    );
    final draftBefore = await owner.read((db) => db.query('session_drafts'));
    await tap(tab('Buổi luyện'));
    await waitFor(find.byType(PracticeSessionsTab));
    await tap(find.widgetWithText(PracticeSessionCard, 'Buổi có bản ghi QA'));
    await waitFor(find.byType(PracticeSessionDetailPage));
    expect(find.text('Tiếp tục luyện'), findsNothing);
    await openDelete();
    expect(
      find.textContaining('Bản ghi âm vẫn được giữ riêng.'),
      findsOneWidget,
    );
    await tap(find.text('Hủy'));
    expect(await reader().saved(profileId: guitar), hasLength(2));
    expect(find.byType(PracticeSessionDetailPage), findsOneWidget);
    await openDelete();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(await reader().saved(profileId: guitar), hasLength(2));
    await owner.read(
      (db) => db.execute(
        "CREATE TRIGGER injected_delete BEFORE UPDATE OF deleted_at ON practice_sessions BEGIN SELECT RAISE(ABORT,'injected'); END",
      ),
    );
    await openDelete();
    await tap(confirm());
    await waitFor(find.textContaining('Chưa thể xóa.'));
    expect(await reader().saved(profileId: guitar), hasLength(2));
    expect(await owner.read((db) => db.query('recordings')), recordingsBefore);
    if (screenshot != null) await screenshot('delete-session-retry');
    await owner.read((db) => db.execute('DROP TRIGGER injected_delete'));
    await tester.tap(find.text('Thử lại'));
    await tester.tap(find.text('Thử lại'));
    await waitFor(find.byType(PracticeSessionsTab));
    expect(
      find.widgetWithText(PracticeSessionCard, 'Buổi có bản ghi QA'),
      findsNothing,
    );
    expect(await reader().saved(profileId: guitar), hasLength(1));
    expect(await owner.read((db) => db.query('recordings')), recordingsBefore);
    expect(await owner.read((db) => db.query('file_cleanup_queue')), isEmpty);
    expect(await owner.read((db) => db.query('session_drafts')), draftBefore);
    await tap(find.widgetWithText(PracticeSessionCard, 'Buổi thường QA'));
    await openDelete();
    await tap(confirm());
    await waitFor(find.text('Chưa có buổi luyện'));
    expect(await reader().saved(profileId: guitar), isEmpty);
    expect(
      await owner.read(
        (db) => db.query(
          'practice_sessions',
          where: 'id = ?',
          whereArgs: [plainSession],
        ),
      ),
      isEmpty,
    );
    expect(await reader().saved(profileId: flute), hasLength(1));
    await tap(tab('Trang chủ'));
    await waitFor(find.byType(HomeExample));
    final summary = tester
        .widget<HomeExample>(find.byType(HomeExample))
        .sessionSummary!;
    expect(summary.count, 0);
    expect(summary.minutes, 0);
    if (screenshot != null) await screenshot('delete-session-home-updated');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await timer.close();
    await owner.close();
    owner = createOwner();
    timer = createTimer();
    await mount();
    await waitFor(find.byType(ProfilePickerScreen));
    final directory = await SqliteInstrumentProfileService(
      owner: owner,
      initialLanguage: 'vi',
    ).load();
    expect(directory.byId(guitar)!.savedSessionCount, 0);
    expect(directory.byId(guitar)!.recordingCount, 1);
    expect(directory.byId(flute)!.savedSessionCount, 1);
    await tap(find.byKey(const Key('select-profile-$guitar')));
    await waitFor(find.byType(HomeExample));
    await tap(tab('Buổi luyện'));
    await waitFor(find.text('Chưa có buổi luyện'));
    expect(
      await reader().findSaved(profileId: guitar, sessionId: audioSession),
      isNull,
    );
    expect(await owner.read((db) => db.query('recordings')), recordingsBefore);
    expect(
      await owner.read((db) => db.rawQuery('PRAGMA foreign_key_check')),
      isEmpty,
    );
    if (screenshot != null) {
      await screenshot('delete-session-history-after-reopen');
    }
    expect(tester.takeException(), isNull);
  } finally {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await timer.close();
    await owner.close();
  }
}
