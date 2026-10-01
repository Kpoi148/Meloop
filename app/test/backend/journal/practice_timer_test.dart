import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/backend/database/journal_database.dart';
import 'package:meloop/backend/database/journal_database_owner.dart';
import 'package:meloop/backend/journal/practice_timer.dart';
import 'package:meloop/backend/journal/sqlite_practice_start_service.dart';
import 'package:meloop/backend/journal/sqlite_practice_timer_store.dart';
import 'package:meloop/backend/journal/sqlite_journal_readers.dart';
import 'package:meloop/shared/journal/journal_failure.dart';
import 'package:meloop/shared/journal/journal_models.dart';
import 'package:meloop/shared/journal/journal_runtime.dart';
import 'package:meloop/shared/journal/journal_text.dart';
import 'package:meloop/shared/journal/practice_timer_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'journal_foundation_test.dart' show insertProfile;
import 'profile_create_test.dart' show id;

class TestMonotonicClock implements MonotonicClock {
  int now = 0;
  @override
  int get elapsedMilliseconds => now;
  void advance(int milliseconds) => now += milliseconds;
}

class TestAwake implements PracticeScreenAwake {
  final enabled = <bool>[];
  @override
  Future<void> setEnabled(bool value) async {
    enabled.add(value);
  }
}

class JumpClock implements JournalClock {
  DateTime now = DateTime.utc(2026, 10, 1);
  @override
  DateTime utcNow() => now;
  @override
  DateTime localNow() => now.toLocal();
}

class GatedTimerStore implements PracticeTimerStore {
  GatedTimerStore(this.delegate);
  final PracticeTimerStore delegate;
  Completer<void>? gate;
  Completer<void>? entered;
  @override
  Future<PracticeDraft> checkpoint({
    required String sessionId,
    required String profileId,
    required int accumulatedMilliseconds,
    required PracticeState state,
  }) async {
    final waiting = gate;
    gate = null;
    if (waiting != null) {
      entered?.complete();
      await waiting.future;
    }
    return delegate.checkpoint(
      sessionId: sessionId,
      profileId: profileId,
      accumulatedMilliseconds: accumulatedMilliseconds,
      state: state,
    );
  }
}

void main() {
  sqfliteFfiInit();
  late Directory temp;
  late JournalDatabaseOwner owner;
  late SqlitePracticeTimerStore store;
  late GatedTimerStore gated;
  late PracticeTimer timer;
  late TestMonotonicClock mono;
  late TestAwake awake;
  late JumpClock wall;
  late PracticeDraft draft;
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('meloop-timer-');
    owner = JournalDatabaseOwner(
      open: () => JournalDatabase.open(
        factory: databaseFactoryFfi,
        path: '${temp.path}/journal.db',
      ),
    );
    wall = JumpClock();
    mono = TestMonotonicClock();
    awake = TestAwake();
    store = SqlitePracticeTimerStore(owner: owner, clock: wall);
    gated = GatedTimerStore(store);
    timer = PracticeTimer(
      store: gated,
      clock: mono,
      screenAwake: awake,
      schedulePulses: false,
    );
    await owner.transaction((db) => insertProfile(db, id(1), 'Guitar'));
    draft = await SqlitePracticeStartService(
      owner: owner,
      clock: wall,
    ).start(requestId: id(10), profileId: id(1), title: 'Timer QA');
  });
  tearDown(() async {
    await timer.close();
    await owner.close();
    await temp.delete(recursive: true);
  });
  Future<PracticeDraft> stored() async =>
      (await SqliteJournalSessionReader(owner).unfinished())!;
  Future<void> injectFailure() => owner.read(
    (db) => db.execute(
      "CREATE TRIGGER injected_checkpoint BEFORE UPDATE ON session_drafts BEGIN SELECT RAISE(ABORT,'injected'); END",
    ),
  );
  Future<void> removeFailure() =>
      owner.read((db) => db.execute('DROP TRIGGER injected_checkpoint'));

  test('new Start/Pause/Resume measure monotonic running intervals only with same identity', () async {
    await timer.open(draft, newlyStarted: true);
    expect(timer.snapshot!.state, PracticeState.running);
    expect(awake.enabled.last, true);
    mono.advance(2400);
    await timer.pause();
    expect((await stored()).accumulatedMilliseconds, 2400);
    mono.advance(100000);
    wall.now = DateTime.utc(2025);
    expect(timer.snapshot!.elapsedMilliseconds, 2400);
    await timer.resume();
    mono.advance(1900);
    await timer.pause();
    final result = await stored();
    expect(result.accumulatedMilliseconds, 4300);
    expect(result.session.state, PracticeState.paused);
    expect(result.session.id, id(10));
    expect(result.session.profileId, id(1));
    expect(result.session.startOffsetMinutes, draft.session.startOffsetMinutes);
    expect(result.session.durationSeconds, isNull);
    expect(awake.enabled.last, false);
    expect(result.updatedAt.isBefore(draft.updatedAt), false);
  });
  test(
    'checkpoint threshold is five seconds and delayed pulses do not undercount',
    () async {
      await timer.open(draft, newlyStarted: true);
      mono.advance(4999);
      await timer.pulse();
      expect((await stored()).accumulatedMilliseconds, 0);
      mono.advance(1);
      await timer.pulse();
      expect((await stored()).accumulatedMilliseconds, 5000);
      mono.advance(8700);
      await timer.pulse();
      expect((await stored()).accumulatedMilliseconds, 13700);
      expect(timer.snapshot!.elapsedMilliseconds, 13700);
    },
  );
  test('cold recovery persists Paused at last checkpoint, with no wall-clock addition', () async {
    draft = await store.checkpoint(
      sessionId: id(10),
      profileId: id(1),
      accumulatedMilliseconds: 5300,
      state: PracticeState.running,
    );
    wall.now = DateTime.utc(2030);
    mono.advance(10000000);
    await timer.open(draft);
    expect(timer.snapshot!.state, PracticeState.paused);
    expect(timer.snapshot!.elapsedMilliseconds, 5300);
    expect((await stored()).session.state, PracticeState.paused);
    mono.advance(60000);
    expect(timer.snapshot!.elapsedMilliseconds, 5300);
    await timer.resume();
    mono.advance(700);
    await timer.pause();
    expect((await stored()).accumulatedMilliseconds, 6000);
  });
  test('Review recovery preserves raw form input and cannot resume', () async {
    final raw = jsonEncode({
      'title': 'Edited',
      'practiceDate': 'invalid',
      'durationHoursInput': 'bad',
      'durationMinutesInput': '',
      'durationSecondsInput': '',
      'practiced': 'notes',
      'difficulty': '',
      'next': '',
      'mood': null,
      'focus': null,
    });
    await owner.transaction((db) async {
      await db.update(
        'practice_sessions',
        {'state': 'review'},
        where: 'id=?',
        whereArgs: [id(10)],
      );
      await db.update(
        'session_drafts',
        {'accumulated_ms': 12345, 'review_input_json': raw},
        where: 'session_id=?',
        whereArgs: [id(10)],
      );
    });
    await timer.open(await stored());
    await timer.resume();
    mono.advance(60000);
    await timer.pulse();
    expect(timer.snapshot!.state, PracticeState.review);
    expect(timer.snapshot!.elapsedMilliseconds, 12345);
    expect((await stored()).reviewInput!.durationHoursInput, 'bad');
    expect((await stored()).reviewInput!.title, 'Edited');
    expect(timer.snapshot!.failed, false);
  });
  test('checkpoint failure freezes retained time, rollback keeps durable checkpoint, Retry saves Paused', () async {
    await timer.open(draft, newlyStarted: true);
    mono.advance(5000);
    await timer.pulse();
    await injectFailure();
    mono.advance(6200);
    await expectLater(timer.pulse(), throwsA(isA<JournalFailure>()));
    expect(timer.snapshot!.failed, true);
    expect(timer.snapshot!.state, PracticeState.paused);
    expect(timer.snapshot!.elapsedMilliseconds, 11200);
    expect(timer.snapshot!.persistedMilliseconds, 5000);
    expect((await stored()).accumulatedMilliseconds, 5000);
    mono.advance(90000);
    await timer.open(await stored());
    expect(
      timer.snapshot!.elapsedMilliseconds,
      11200,
    ); // Navigation/reload cannot discard unsaved memory.
    await removeFailure();
    await timer.retry();
    expect(timer.snapshot!.failed, false);
    expect((await stored()).accumulatedMilliseconds, 11200);
    expect((await stored()).session.state, PracticeState.paused);
    await timer.resume();
    mono.advance(800);
    await timer.pause();
    expect((await stored()).accumulatedMilliseconds, 12000);
  });
  test('pause during a slow checkpoint freezes immediately and later writes cannot revert state/time', () async {
    await timer.open(draft, newlyStarted: true);
    mono.advance(6000);
    final gate = Completer<void>();
    gated.gate = gate;
    gated.entered = Completer<void>();
    final checkpoint = timer.pulse();
    await gated.entered!.future;
    mono.advance(2000);
    final pause = timer.pause();
    mono.advance(3600000);
    expect(timer.snapshot!.elapsedMilliseconds, 8000);
    expect(timer.snapshot!.state, PracticeState.paused);
    gate.complete();
    await checkpoint;
    await pause;
    expect((await stored()).accumulatedMilliseconds, 8000);
    expect((await stored()).session.state, PracticeState.paused);
  });
  test('background while Resume is pending never starts a running interval on completion', () async {
    await timer.open(draft);
    final gate = Completer<void>();
    gated.gate = gate;
    gated.entered = Completer<void>();
    final resume = timer.resume();
    await gated.entered!.future;
    timer.setForeground(false);
    mono.advance(10000);
    gate.complete();
    await resume;
    await timer.pause();
    expect(timer.snapshot!.state, PracticeState.paused);
    expect(timer.snapshot!.elapsedMilliseconds, 0);
    expect(awake.enabled.last, false);
    expect((await stored()).session.state, PracticeState.paused);
    timer.setForeground(true);
    mono.advance(60000);
    expect(timer.snapshot!.elapsedMilliseconds, 0);
    await timer.resume();
    mono.advance(1000);
    await timer.pause();
    expect((await stored()).accumulatedMilliseconds, 1000);
  });
  test(
    '24 hours caps elapsed and atomically stops in Review, without final Save',
    () async {
      await timer.open(draft, newlyStarted: true);
      mono.advance(PracticeRules.maximumDuration.inMilliseconds + 12000);
      await timer.pulse();
      expect(timer.snapshot!.state, PracticeState.review);
      expect(
        timer.snapshot!.elapsedMilliseconds,
        PracticeRules.maximumDuration.inMilliseconds,
      );
      expect((await stored()).session.state, PracticeState.review);
      expect(awake.enabled.last, false);
      await timer.resume();
      mono.advance(999999);
      await timer.pulse();
      expect(
        timer.snapshot!.elapsedMilliseconds,
        PracticeRules.maximumDuration.inMilliseconds,
      );
      expect(
        await SqliteJournalSessionReader(owner).saved(profileId: id(1)),
        isEmpty,
      );
    },
  );
  test('storage rejects wrong ownership, stale/regressing time and saved transition', () async {
    for (final args in [
      (id(11), id(1), 1, PracticeState.paused),
      (id(10), id(2), 1, PracticeState.paused),
      (id(10), id(1), -1, PracticeState.paused),
      (id(10), id(1), 1, PracticeState.saved),
      (
        id(10),
        id(1),
        PracticeRules.maximumDuration.inMilliseconds + 1,
        PracticeState.paused,
      ),
    ]) {
      await expectLater(
        store.checkpoint(
          sessionId: args.$1,
          profileId: args.$2,
          accumulatedMilliseconds: args.$3,
          state: args.$4,
        ),
        throwsA(isA<JournalFailure>()),
      );
    }
    await store.checkpoint(
      sessionId: id(10),
      profileId: id(1),
      accumulatedMilliseconds: 3000,
      state: PracticeState.paused,
    );
    await expectLater(
      store.checkpoint(
        sessionId: id(10),
        profileId: id(1),
        accumulatedMilliseconds: 2000,
        state: PracticeState.paused,
      ),
      throwsA(isA<JournalFailure>()),
    );
    expect((await stored()).accumulatedMilliseconds, 3000);
  });
  test(
    'failed state transition rolls back checkpoint as well as session state',
    () async {
      await owner.read(
        (db) => db.execute(
          "CREATE TRIGGER injected_transition BEFORE UPDATE OF state ON practice_sessions BEGIN SELECT RAISE(ABORT,'injected'); END",
        ),
      );
      await expectLater(
        store.checkpoint(
          sessionId: id(10),
          profileId: id(1),
          accumulatedMilliseconds: 4000,
          state: PracticeState.paused,
        ),
        throwsA(isA<JournalFailure>()),
      );
      expect((await stored()).accumulatedMilliseconds, 0);
      expect((await stored()).session.state, PracticeState.running);
    },
  );
  test(
    'repeated Resume does not reset anchor and close persists final pause',
    () async {
      await timer.open(draft);
      await Future.wait([timer.resume(), timer.resume()]);
      mono.advance(2450);
      await timer.resume();
      mono.advance(550);
      await timer.close();
      expect((await stored()).accumulatedMilliseconds, 3000);
      expect((await stored()).session.state, PracticeState.paused);
      expect(awake.enabled.last, false);
      await expectLater(timer.resume(), throwsA(isA<JournalFailure>()));
    },
  );
}
