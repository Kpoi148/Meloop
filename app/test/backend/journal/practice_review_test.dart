import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/backend/database/journal_database.dart';
import 'package:meloop/backend/database/journal_database_owner.dart';
import 'package:meloop/backend/journal/sqlite_practice_review_service.dart';
import 'package:meloop/backend/journal/sqlite_practice_start_service.dart';
import 'package:meloop/backend/journal/sqlite_practice_timer_store.dart';
import 'package:meloop/backend/journal/sqlite_journal_readers.dart';
import 'package:meloop/backend/journal/practice_timer.dart';
import 'package:meloop/shared/journal/journal_models.dart';
import 'package:meloop/shared/journal/journal_failure.dart';
import 'package:meloop/shared/journal/practice_date.dart';
import 'package:meloop/shared/journal/practice_review_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'journal_foundation_test.dart' show insertProfile, TestClock;
import 'profile_create_test.dart' show id;
import 'practice_timer_test.dart' show TestMonotonicClock, TestAwake;

void main() {
  sqfliteFfiInit();
  late Directory temp;
  late JournalDatabaseOwner owner;
  late PracticeTimer timer;
  late SqlitePracticeReviewService review;
  late TestMonotonicClock mono;
  PracticeReviewValues values({
    String title = 'Luyện sáo',
    int duration = 120,
    int? bpm = 80,
  }) => PracticeReviewValues(
    title: title,
    date: PracticeDate.parse('2026-10-02'),
    durationSeconds: duration,
    practiced: 'Âm dài',
    difficulty: 'Hơi thở',
    next: 'Luyện chậm',
    mood: 4,
    focus: 5,
    bpm: bpm,
  );
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('meloop-review-');
    owner = JournalDatabaseOwner(
      open: () => JournalDatabase.open(
        factory: databaseFactoryFfi,
        path: '${temp.path}/journal.db',
      ),
    );
    await owner.transaction((db) => insertProfile(db, id(1), 'Sáo'));
    final draft = await SqlitePracticeStartService(
      owner: owner,
      clock: TestClock(),
    ).start(requestId: id(10), profileId: id(1), title: 'Buổi đang luyện');
    mono = TestMonotonicClock();
    timer = PracticeTimer(
      store: SqlitePracticeTimerStore(owner: owner, clock: TestClock()),
      clock: mono,
      screenAwake: TestAwake(),
      schedulePulses: false,
    );
    await timer.open(draft, newlyStarted: true);
    review = SqlitePracticeReviewService(owner: owner, clock: TestClock());
  });
  tearDown(() async {
    await timer.close();
    await owner.close();
    await temp.delete(recursive: true);
  });
  test('Finish freezes service time and stores Review; cancel returns same paused draft', () async {
    mono.advance(15300);
    await timer.finish();
    mono.advance(60000);
    final draft = await review.read(id(10));
    expect(draft.session.state, PracticeState.review);
    expect(draft.accumulatedMilliseconds, 15300);
    expect(timer.snapshot!.elapsedMilliseconds, 15300);
    await timer.leaveReview();
    expect(
      (await SqliteJournalSessionReader(owner).unfinished())!.session.state,
      PracticeState.paused,
    );
    await timer.resume();
    mono.advance(1700);
    await timer.finish();
    expect(timer.snapshot!.elapsedMilliseconds, 17000);
  });
  test('concurrent/repeated Save creates one saved row; measured time remains separate; new Start works', () async {
    mono.advance(15300);
    await timer.finish();
    final saved = await Future.wait([
      review.save(id(10), values()),
      review.save(id(10), values(title: 'Duplicate')),
    ]);
    expect(saved.map((s) => s.title).toSet(), {'Luyện sáo'});
    expect(saved.first.durationSeconds, 120);
    expect(saved.first.measuredDurationSeconds, 15);
    expect(saved.first.bpm, 80);
    expect(
      await owner.read((db) => db.query('practice_sessions')),
      hasLength(1),
    );
    expect(await owner.read((db) => db.query('session_drafts')), isEmpty);
    await timer.complete(id(10));
    expect(timer.snapshot, isNull);
    final next = await SqlitePracticeStartService(
      owner: owner,
      clock: TestClock(),
    ).start(requestId: id(11), profileId: id(1), title: 'Buổi tiếp theo');
    await timer.open(next, newlyStarted: true);
    expect(timer.snapshot!.sessionId, id(11));
  });
  test('Save rollback retains Review for retry; reopen retains exactly one saved session', () async {
    mono.advance(12000);
    await timer.finish();
    await owner.read(
      (db) => db.execute(
        "CREATE TRIGGER injected_save BEFORE DELETE ON session_drafts BEGIN SELECT RAISE(ABORT,'injected'); END",
      ),
    );
    await expectLater(
      review.save(id(10), values()),
      throwsA(isA<JournalFailure>()),
    );
    expect((await review.read(id(10))).session.state, PracticeState.review);
    expect(
      await SqliteJournalSessionReader(owner).saved(profileId: id(1)),
      isEmpty,
    );
    await owner.read((db) => db.execute('DROP TRIGGER injected_save'));
    await review.save(id(10), values());
    await timer.complete(id(10));
    await owner.close();
    owner = JournalDatabaseOwner(
      open: () => JournalDatabase.open(
        factory: databaseFactoryFfi,
        path: '${temp.path}/journal.db',
      ),
    );
    final saved = await SqliteJournalSessionReader(owner)
        .saved(profileId: id(1));
    expect(saved, hasLength(1));
    expect(saved.single.practiced, 'Âm dài');
    expect(saved.single.focus, 5);
    review = SqlitePracticeReviewService(owner: owner, clock: TestClock());
    expect(
      (await review.save(id(10), values(title: 'Retry'))).title,
      'Luyện sáo',
    );
  });
  test('invalid or premature Save cannot change draft; rename preserves ownership and time', () async {
    await expectLater(
      review.save(id(10), values()),
      throwsA(isA<JournalFailure>()),
    );
    expect(await review.rename(id(10), '  Luyện mới  '), 'Luyện mới');
    mono.advance(5000);
    await timer.finish();
    for (final invalid in [
      values(title: ''),
      values(duration: 0),
      values(duration: 86401),
      values(bpm: 401),
    ]) {
      await expectLater(
        review.save(id(10), invalid),
        throwsA(isA<JournalFailure>()),
      );
    }
    expect((await review.read(id(10))).accumulatedMilliseconds, 5000);
    expect(
      await owner.read((db) => db.query('practice_sessions')),
      hasLength(1),
    );
  });

  test('review commands target their session while another profile has a running draft', () async {
    mono.advance(12000);
    await timer.finish();
    await owner.transaction((db) => insertProfile(db, id(2), 'Guitar'));
    final other = await SqlitePracticeStartService(
      owner: owner,
      clock: TestClock(),
    ).start(requestId: id(11), profileId: id(2), title: 'Other draft');
    await SqlitePracticeTimerStore(owner: owner, clock: TestClock()).checkpoint(
      sessionId: other.session.id,
      profileId: id(2),
      accumulatedMilliseconds: 4500,
      state: PracticeState.running,
    );
    expect(await review.rename(id(10), 'Renamed review'), 'Renamed review');
    expect((await review.read(id(10))).accumulatedMilliseconds, 12000);
    await review.save(id(10), values());
    await review.save(id(10), values(title: 'Duplicate'));
    await timer.complete(id(10));
    final reader = SqliteJournalSessionReader(owner);
    final retained = (await reader.unfinished(profileId: id(2)))!;
    expect(retained.session.id, id(11));
    expect(retained.session.title, 'Other draft');
    expect(retained.accumulatedMilliseconds, 4500);
    expect(await reader.saved(profileId: id(1)), hasLength(1));
    expect(await reader.saved(profileId: id(2)), isEmpty);
  });
}
