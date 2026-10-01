import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/backend/database/journal_database.dart';
import 'package:meloop/backend/database/journal_database_owner.dart';
import 'package:meloop/backend/journal/sqlite_journal_readers.dart';
import 'package:meloop/backend/settings/sqlite_app_settings_store.dart';
import 'package:meloop/shared/journal/journal_failure.dart';
import 'package:meloop/shared/journal/journal_models.dart';
import 'package:meloop/shared/journal/journal_runtime.dart';
import 'package:meloop/shared/journal/journal_text.dart';
import 'package:meloop/shared/journal/practice_date.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const profile = '00000000-0000-4000-8000-000000000001';
const otherProfile = '00000000-0000-4000-8000-000000000002';
const savedId = '00000000-0000-4000-8000-000000000011';
const draftId = '00000000-0000-4000-8000-000000000012';
const timestamp = 1790726400000;

class TestClock implements JournalClock {
  @override
  DateTime utcNow() =>
      DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: true);
  @override
  DateTime localNow() => DateTime(2026, 9, 30);
}

Future<void> insertProfile(DatabaseExecutor db, String id, String name) async {
  await db.insert('instrument_profiles', {
    'id': id,
    'name': name,
    'name_key': JournalText.profileKey(name),
    'instrument_type': 'guitar',
    'created_at': timestamp,
    'updated_at': timestamp,
  });
}

Future<void> insertSession(
  DatabaseExecutor db, {
  required String id,
  required String ownerId,
  String state = 'saved',
  String title = 'Đàn 100%_\\',
  String date = '2026-09-30',
  String notes = '',
}) async {
  await db.insert('practice_sessions', {
    'id': id,
    'profile_id': ownerId,
    'state': state,
    'title': title,
    'practice_date': date,
    'start_offset_minutes': 420,
    'practiced': notes,
    'title_search': JournalText.searchKey(title),
    'practiced_search': JournalText.searchKey(notes),
    'created_at': timestamp,
    'updated_at': timestamp,
    if (state == 'saved') 'duration_seconds': 120,
    if (state == 'saved') 'measured_duration_seconds': 60,
  });
}

Matcher failure(JournalFailureCode code) =>
    isA<JournalFailure>().having((e) => e.code, 'code', code);

void main() {
  sqfliteFfiInit();
  late JournalDatabaseOwner owner;
  setUp(() {
    owner = JournalDatabaseOwner(
      open: () => JournalDatabase.open(
        factory: databaseFactoryFfi,
        path: inMemoryDatabasePath,
      ),
    );
  });
  tearDown(() => owner.close());

  test(
    'settings and readers share one open connection and never close each other',
    () async {
      var opens = 0;
      final db = await JournalDatabase.open(
        factory: databaseFactoryFfi,
        path: inMemoryDatabasePath,
      );
      final shared = JournalDatabaseOwner(
        open: () async {
          opens++;
          return db;
        },
      );
      addTearDown(shared.close);
      final settings = SqliteAppSettingsStore(
        owner: shared,
        clock: TestClock(),
      );
      final profiles = SqliteJournalProfileReader(shared);
      await Future.wait([
        profiles.list(),
        settings.writeLanguageCode('en'),
        settings.readLanguageCode(),
      ]);
      expect(opens, 1);
      expect(db.isOpen, true);
      expect(await settings.readLanguageCode(), 'en');
      await shared.close();
      expect(db.isOpen, false);
      await expectLater(
        profiles.list(),
        throwsA(failure(JournalFailureCode.closed)),
      );
    },
  );

  test(
    'close waits for delayed open and accepted work but rejects new work',
    () async {
      final db = await JournalDatabase.open(
        factory: databaseFactoryFfi,
        path: inMemoryDatabasePath,
      );
      final gate = Completer<void>();
      final shared = JournalDatabaseOwner(
        open: () async {
          await gate.future;
          return db;
        },
      );
      final first = shared.read((db) async => db.rawQuery('SELECT 1'));
      final second = shared.read((db) async => db.rawQuery('SELECT 2'));
      final closing = shared.close();
      expect(identical(shared.close(), closing), true);
      await expectLater(
        shared.read((db) async => 3),
        throwsA(failure(JournalFailureCode.closed)),
      );
      gate.complete();
      await Future.wait([first, second]);
      await closing;
      expect(db.isOpen, false);
    },
  );

  test('failed opening can be retried without poisoning owner', () async {
    var attempts = 0;
    final shared = JournalDatabaseOwner(
      open: () async {
        if (++attempts == 1) throw StateError('Injected opening failure');
        return JournalDatabase.open(
          factory: databaseFactoryFfi,
          path: inMemoryDatabasePath,
        );
      },
    );
    addTearDown(shared.close);
    await expectLater(
      SqliteJournalProfileReader(shared).list(),
      throwsStateError,
    );
    expect(await SqliteJournalProfileReader(shared).list(), isEmpty);
    expect(attempts, 2);
  });

  test(
    'reentry fails immediately, rolls back and leaves the owner usable',
    () async {
      await expectLater(
        owner.transaction((db) async {
          await insertProfile(db, profile, 'Guitar');
          await owner.read((db) async => db.query('instrument_profiles'));
        }),
        throwsStateError,
      );
      expect(await SqliteJournalProfileReader(owner).list(), isEmpty);
      await expectLater(owner.read((db) => owner.close()), throwsStateError);
      expect(await SqliteJournalProfileReader(owner).list(), isEmpty);
    },
  );

  test(
    'transaction failure rolls back all writes and later work succeeds',
    () async {
      await expectLater(
        owner.transaction((db) async {
          await insertProfile(db, profile, 'Guitar');
          await db.insert('weekly_goals', {
            'profile_id': profile,
            'updated_at': timestamp,
          });
          throw StateError('Injected transaction failure');
        }),
        throwsStateError,
      );
      expect(await SqliteJournalProfileReader(owner).list(), isEmpty);
      expect(await owner.read((db) async => db.query('weekly_goals')), isEmpty);
      await owner.transaction((db) => insertProfile(db, profile, 'Guitar'));
      expect(
        (await SqliteJournalProfileReader(owner).list()).single.id,
        profile,
      );
    },
  );

  test('settings write preserves selection and readers return immutable UTC models', () async {
    await owner.transaction((db) async {
      await insertProfile(db, profile, 'Guitar');
      await db.insert('app_preferences', {
        'id': 1,
        'language': 'vi',
        'selected_profile_id': profile,
        'updated_at': timestamp,
      });
    });
    await SqliteAppSettingsStore(
      owner: owner,
      clock: TestClock(),
    ).writeLanguageCode('en');
    final prefs = (await SqliteJournalPreferencesReader(owner).read())!;
    expect(prefs.selectedProfileId, profile);
    expect(prefs.language, JournalLanguage.en);
    expect(prefs.updatedAt.isUtc, true);
    final rows = await SqliteJournalProfileReader(owner).list();
    expect(rows.single.createdAt.millisecondsSinceEpoch, timestamp);
    expect(() => rows.clear(), throwsUnsupportedError);
    expect(await SqliteJournalProfileReader(owner).find(otherProfile), isNull);
  });

  test(
    'saved queries enforce ownership, date boundaries and literal search',
    () async {
      await owner.transaction((db) async {
        await insertProfile(db, profile, 'Guitar');
        await insertProfile(db, otherProfile, 'Piano');
        await insertSession(
          db,
          id: savedId,
          ownerId: profile,
          notes: 'ĐẮNG độ',
        );
        await insertSession(db, id: draftId, ownerId: otherProfile);
      });
      final reader = SqliteJournalSessionReader(owner);
      expect(
        await reader.findSaved(profileId: otherProfile, sessionId: savedId),
        isNull,
      );
      final found = (await reader.saved(
        profileId: profile,
        from: PracticeDate.parse('2026-09-30'),
        through: PracticeDate.parse('2026-09-30'),
        query: r'100%_\',
      )).single;
      expect(found.id, savedId);
      expect(found.durationSeconds, 120);
      expect(found.measuredDurationSeconds, 60);
      expect(found.title, 'Đàn 100%_\\');
      expect(
        (await reader.saved(profileId: profile, query: 'dang do')).single.id,
        savedId,
      );
      expect(
        await reader.saved(
          profileId: profile,
          from: PracticeDate.parse('2026-10-01'),
        ),
        isEmpty,
      );
      expect(await reader.saved(profileId: profile, query: '100%X'), isEmpty);
      expect(
        () => reader.saved(
          profileId: profile,
          from: PracticeDate.parse('2026-10-01'),
          through: PracticeDate.parse('2026-09-30'),
        ),
        throwsA(failure(JournalFailureCode.invalidInput)),
      );
    },
  );

  test(
    'unfinished read preserves invalid review input without resuming or saving',
    () async {
      final review = {
        'title': '',
        'practiceDate': 'invalid',
        'durationHoursInput': '',
        'durationMinutesInput': '80.5',
        'durationSecondsInput': 'abc',
        'practiced': '',
        'difficulty': '',
        'next': '',
        'mood': null,
        'focus': 3,
      };
      await owner.transaction((db) async {
        await insertProfile(db, profile, 'Guitar');
        await insertSession(
          db,
          id: draftId,
          ownerId: profile,
          state: 'running',
        );
        await db.update(
          'session_drafts',
          {'accumulated_ms': 754000, 'review_input_json': jsonEncode(review)},
          where: 'session_id = ?',
          whereArgs: [draftId],
        );
      });
      final reader = SqliteJournalSessionReader(owner);
      final draft = (await reader.unfinished())!;
      expect(draft.session.profileId, profile);
      expect(draft.session.state, PracticeState.running);
      expect(draft.accumulatedMilliseconds, 754000);
      expect(draft.reviewInput!.durationMinutesInput, '80.5');
      expect(await reader.saved(profileId: profile), isEmpty);
      expect(
        await reader.findSaved(profileId: profile, sessionId: draftId),
        isNull,
      );
      expect((await reader.unfinished())!.session.state, PracticeState.running);
    },
  );

  test(
    'corrupt sidecar and query failure throw, never produce false empty state',
    () async {
      await owner.transaction((db) async {
        await insertProfile(db, profile, 'Guitar');
        await insertSession(
          db,
          id: draftId,
          ownerId: profile,
          state: 'running',
        );
        await db.update(
          'session_drafts',
          {'review_input_json': '{invalid'},
          where: 'session_id = ?',
          whereArgs: [draftId],
        );
      });
      await expectLater(
        SqliteJournalSessionReader(owner).unfinished(),
        throwsA(failure(JournalFailureCode.corruptData)),
      );
      await owner.transaction(
        (db) => db.execute('DROP VIEW saved_practice_sessions'),
      );
      await expectLater(
        SqliteJournalSessionReader(owner).saved(profileId: profile),
        throwsA(failure(JournalFailureCode.storage)),
      );
      expect(
        (await SqliteJournalProfileReader(owner).list()).single.id,
        profile,
      );
    },
  );

  test('committed journal/settings survive closing and reopening a real SQLite file', () async {
    final dir = await Directory.systemTemp.createTemp(
      'meloop-journal-foundation-',
    );
    var current = JournalDatabaseOwner(
      open: () => JournalDatabase.open(
        factory: databaseFactoryFfi,
        path: '${dir.path}/journal.db',
      ),
    );
    addTearDown(() async {
      await current.close();
      await dir.delete(recursive: true);
    });
    await current.transaction((db) async {
      await insertProfile(db, profile, 'Guitar');
      await insertSession(db, id: savedId, ownerId: profile);
    });
    await SqliteAppSettingsStore(
      owner: current,
      clock: TestClock(),
    ).writeLanguageCode('en');
    await current.close();
    current = JournalDatabaseOwner(
      open: () => JournalDatabase.open(
        factory: databaseFactoryFfi,
        path: '${dir.path}/journal.db',
      ),
    );
    expect(
      (await SqliteJournalProfileReader(current).list()).single.id,
      profile,
    );
    expect(
      (await SqliteJournalSessionReader(current).saved(profileId: profile))
          .single
          .id,
      savedId,
    );
    expect(
      await SqliteAppSettingsStore(owner: current).readLanguageCode(),
      'en',
    );
    expect(await current.read((db) => db.getVersion()), 1);
  });
}
