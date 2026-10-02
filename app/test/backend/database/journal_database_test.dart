import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/backend/database/journal_database.dart';
import 'package:meloop/backend/database/migration_runner.dart';
import 'package:meloop/backend/database/migrations/v001_initial_schema.dart';
import 'package:meloop/backend/database/migrations/v002_session_bpm.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const profileId = '00000000-0000-4000-8000-000000000001';
const otherProfileId = '00000000-0000-4000-8000-000000000002';
const sessionId = '00000000-0000-4000-8000-000000000011';
const otherSessionId = '00000000-0000-4000-8000-000000000012';
const recordingId = '00000000-0000-4000-8000-000000000021';
const timestamp = 1790726400000;

Future<void> addProfile(
  Database db, {
  String id = profileId,
  String name = 'Guitar',
}) => db
    .insert('instrument_profiles', {
      'id': id,
      'name': name,
      'name_key': name.toLowerCase(),
      'instrument_type': 'guitar',
      'created_at': timestamp,
      'updated_at': timestamp,
    })
    .then((_) {});

Map<String, Object?> sessionRow({
  String id = sessionId,
  String profile = profileId,
  String state = 'running',
}) => {
  'id': id,
  'profile_id': profile,
  'state': state,
  'title': 'Test practice',
  'practice_date': '2026-09-30',
  'start_offset_minutes': 420,
  'created_at': timestamp,
  'updated_at': timestamp,
  if (state == 'saved') 'duration_seconds': 60,
  if (state == 'saved') 'measured_duration_seconds': 60,
};

Future<void> addRecording(Database db, {bool pending = false}) => db
    .insert('recordings', {
      'id': recordingId,
      'session_id': sessionId,
      'status': pending ? 'pending' : 'ready',
      if (pending) 'temp_relative_path': 'recordings/tmp/test.part',
      if (!pending) ...{
        'local_relative_path': 'recordings/test.m4a',
        'filename': 'test.m4a',
        'duration_ms': 1000,
        'size_bytes': 12000,
        'sample_rate_hz': 44100,
        'channel_count': 1,
      },
      'created_at': timestamp,
      'updated_at': timestamp,
    })
    .then((_) {});

void main() {
  sqfliteFfiInit();
  late Database db;

  setUp(() async {
    db = await JournalDatabase.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
  });
  tearDown(() async => db.close());

  test(
    'v1 creates exactly nine empty tables and enables foreign keys',
    () async {
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%'",
      );
      expect(
        tables.map((row) => row['name']),
        unorderedEquals([
          'instrument_profiles',
          'practice_sessions',
          'session_drafts',
          'recordings',
          'weekly_goals',
          'app_preferences',
          'reminder_settings',
          'metronome_settings',
          'file_cleanup_queue',
        ]),
      );
      for (final table in tables) {
        final count = await db.rawQuery(
          'SELECT COUNT(*) AS n FROM ${table['name']}',
        );
        expect(count.single['n'], 0);
      }
      expect(await db.getVersion(), JournalDatabase.schemaVersion);
      expect(
        (await db.rawQuery('PRAGMA foreign_keys')).single.values.single,
        1,
      );
      expect(
        (await db.rawQuery('PRAGMA integrity_check')).single.values.single,
        'ok',
      );
    },
  );

  test(
    'orphans, duplicate normalized names and invalid profile types fail',
    () async {
      await expectLater(
        db.insert('practice_sessions', sessionRow()),
        throwsA(isA<DatabaseException>()),
      );
      await addProfile(db);
      await expectLater(
        addProfile(db, id: otherProfileId),
        throwsA(isA<DatabaseException>()),
      );
      await expectLater(
        db.insert('instrument_profiles', {
          'id': otherProfileId,
          'name': 'Other',
          'name_key': 'other',
          'instrument_type': 'other',
          'custom_type': '',
          'created_at': timestamp,
          'updated_at': timestamp,
        }),
        throwsA(isA<DatabaseException>()),
      );
    },
  );

  test(
    'one unfinished session per profile and only one running session',
    () async {
      await addProfile(db);
      await addProfile(db, id: otherProfileId, name: 'Second');
      await db.insert('practice_sessions', sessionRow());
      expect((await db.query('session_drafts')).single['accumulated_ms'], 0);
      expect(await db.query('saved_practice_sessions'), isEmpty);
      await expectLater(
        db.insert(
          'practice_sessions',
          sessionRow(id: otherSessionId, profile: otherProfileId),
        ),
        throwsA(isA<DatabaseException>()),
      );
      await expectLater(
        db.insert(
          'practice_sessions',
          sessionRow(id: otherSessionId, state: 'paused'),
        ),
        throwsA(isA<DatabaseException>()),
      );
      await db.insert(
        'practice_sessions',
        sessionRow(
          id: otherSessionId,
          profile: otherProfileId,
          state: 'paused',
        ),
      );
      expect(await db.query('session_drafts'), hasLength(2));
      expect(await db.query('saved_practice_sessions'), isEmpty);
    },
  );

  test(
    'saving preserves recording links, measurement and removes draft once',
    () async {
      await addProfile(db);
      await db.insert('practice_sessions', sessionRow());
      await addRecording(db);
      await db.update('session_drafts', {'accumulated_ms': 60999});
      await db.update('practice_sessions', {'state': 'review'});
      await db.transaction((txn) async {
        await txn.update(
          'practice_sessions',
          {
            'state': 'saved',
            'duration_seconds': 90,
            'measured_duration_seconds': 60,
            'practiced': 'Line one\nLine two',
            'mood': null,
            'focus': 4,
          },
          where: 'id = ? AND state = ?',
          whereArgs: [sessionId, 'review'],
        );
      });
      expect(await db.query('session_drafts'), isEmpty);
      final saved = (await db.query('saved_practice_sessions')).single;
      expect(saved['measured_duration_seconds'], 60);
      expect(saved['duration_seconds'], 90);
      expect(saved['mood'], isNull);
      expect(saved['practiced'], 'Line one\nLine two');
      expect((await db.query('recordings')).single['session_id'], sessionId);
      expect(
        await db.update(
          'practice_sessions',
          {'state': 'saved'},
          where: 'id = ? AND state = ?',
          whereArgs: [sessionId, 'review'],
        ),
        0,
      );
      await db.insert('practice_sessions', sessionRow(id: otherSessionId));
      await expectLater(
        db.update(
          'practice_sessions',
          {'state': 'running'},
          where: 'id = ?',
          whereArgs: [sessionId],
        ),
        throwsA(isA<DatabaseException>()),
      );
      await expectLater(
        db.update(
          'practice_sessions',
          {'measured_duration_seconds': 5},
          where: 'id = ?',
          whereArgs: [sessionId],
        ),
        throwsA(isA<DatabaseException>()),
      );
    },
  );

  test('save cannot bypass review, checkpoint or pending audio', () async {
    await addProfile(db);
    await db.insert('practice_sessions', sessionRow());
    await expectLater(
      db.update('practice_sessions', {
        'state': 'saved',
        'duration_seconds': 1,
        'measured_duration_seconds': 0,
      }),
      throwsA(isA<DatabaseException>()),
    );
    await addRecording(db, pending: true);
    await db.update('practice_sessions', {'state': 'review'});
    await expectLater(
      db.update('practice_sessions', {
        'state': 'saved',
        'duration_seconds': 1,
        'measured_duration_seconds': 0,
      }),
      throwsA(isA<DatabaseException>()),
    );
    expect(await db.query('session_drafts'), hasLength(1));
  });

  test('range and calendar checks reject invalid saved metadata', () async {
    await addProfile(db);
    for (final invalid in [
      {'practice_date': '2026-02-30'},
      {'practice_date': '1900-01-01'},
      {'duration_seconds': 0},
      {'duration_seconds': 86401},
      {'duration_seconds': 1.5},
      {'mood': 0},
      {'focus': 6},
      {'start_offset_minutes': 841},
      {'title': ''},
    ]) {
      await expectLater(
        db.insert('practice_sessions', {
          ...sessionRow(state: 'saved'),
          ...invalid,
        }),
        throwsA(isA<DatabaseException>()),
      );
    }
    await db.insert('practice_sessions', {
      ...sessionRow(state: 'saved'),
      'practice_date': '2024-02-29',
      'duration_seconds': 86400,
    });
  });

  test(
    'profile ownership is immutable; an unfinished profile cannot be deleted',
    () async {
      await addProfile(db);
      await db.insert('practice_sessions', sessionRow());
      await expectLater(
        db.update('instrument_profiles', {'instrument_type': 'piano'}),
        throwsA(isA<DatabaseException>()),
      );
      await expectLater(
        db.delete('instrument_profiles'),
        throwsA(isA<DatabaseException>()),
      );
      await db.delete('practice_sessions');
      await db.delete('instrument_profiles');
      expect(await db.query('instrument_profiles'), isEmpty);
    },
  );

  test(
    'cascade deletion queues audio atomically and clears selection',
    () async {
      await addProfile(db);
      await db.insert('practice_sessions', sessionRow());
      await addRecording(db);
      await db.update('practice_sessions', {'state': 'review'});
      await db.update('practice_sessions', {
        'state': 'saved',
        'duration_seconds': 1,
        'measured_duration_seconds': 0,
      });
      await db.insert('weekly_goals', {
        'profile_id': profileId,
        'updated_at': timestamp,
      });
      await db.insert('app_preferences', {
        'id': 1,
        'language': 'vi',
        'selected_profile_id': profileId,
        'updated_at': timestamp,
      });
      await db.delete('instrument_profiles');
      for (final table in ['practice_sessions', 'recordings', 'weekly_goals']) {
        expect(await db.query(table), isEmpty);
      }
      expect(
        (await db.query('app_preferences')).single['selected_profile_id'],
        isNull,
      );
      expect(
        (await db.query('file_cleanup_queue')).single['relative_path'],
        'recordings/test.m4a',
      );
    },
  );

  test(
    'failed deletion transaction keeps journal and rolls back cleanup',
    () async {
      await addProfile(db);
      await db.insert('practice_sessions', sessionRow());
      await addRecording(db);
      await expectLater(
        db.transaction((txn) async {
          await txn.delete('practice_sessions');
          throw StateError('Injected failure before commit');
        }),
        throwsStateError,
      );
      expect(await db.query('practice_sessions'), hasLength(1));
      expect(await db.query('recordings'), hasLength(1));
      expect(await db.query('file_cleanup_queue'), isEmpty);
    },
  );

  test(
    'path traversal and incomplete finalized recordings are rejected',
    () async {
      await addProfile(db);
      await db.insert('practice_sessions', sessionRow());
      for (final path in [
        '../outside.part',
        '/absolute.part',
        'C:\\outside.part',
        'a/../outside.part',
      ]) {
        await expectLater(
          db.insert('recordings', {
            'id': recordingId,
            'session_id': sessionId,
            'status': 'pending',
            'temp_relative_path': path,
            'created_at': timestamp,
            'updated_at': timestamp,
          }),
          throwsA(isA<DatabaseException>()),
        );
      }
      await expectLater(
        db.insert('recordings', {
          'id': recordingId,
          'session_id': sessionId,
          'status': 'ready',
          'created_at': timestamp,
          'updated_at': timestamp,
        }),
        throwsA(isA<DatabaseException>()),
      );
      await addRecording(db, pending: true);
      await db.delete('recordings');
      expect(
        (await db.query('file_cleanup_queue')).single['storage_namespace'],
        'audio_temp',
      );
    },
  );

  test(
    'settings defaults and bounds do not create sample journal data',
    () async {
      await db.insert('metronome_settings', {'id': 1, 'updated_at': timestamp});
      expect((await db.query('metronome_settings')).single['bpm'], 80);
      await expectLater(
        db.update('metronome_settings', {'bpm': 241}),
        throwsA(isA<DatabaseException>()),
      );
      await db.insert('reminder_settings', {'id': 1, 'updated_at': timestamp});
      await expectLater(
        db.update('reminder_settings', {'enabled': 1}),
        throwsA(isA<DatabaseException>()),
      );
      await db.update('reminder_settings', {'enabled': 1, 'weekdays_mask': 1});
      await expectLater(
        db.insert('app_preferences', {
          'id': 2,
          'language': 'vi',
          'updated_at': timestamp,
        }),
        throwsA(isA<DatabaseException>()),
      );
      expect(await db.query('instrument_profiles'), isEmpty);
    },
  );

  test(
    'v2 upgrade preserves draft, review input, BPM and recording links',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'meloop-v3-upgrade-',
      );
      final path = '${directory.path}/journal.db';
      const review = '{"title":"Review QA","duration_seconds":754}';
      try {
        final old = await databaseFactoryFfi.openDatabase(
          path,
          options: JournalDatabase.options(
            runner: MigrationRunner(const [initialSchema, sessionBpmSchema]),
          ),
        );
        await addProfile(old);
        await addProfile(old, id: otherProfileId, name: 'Flute');
        await old.insert('practice_sessions', {
          ...sessionRow(state: 'review'),
          'bpm': 90,
        });
        await old.update('session_drafts', {
          'accumulated_ms': 754000,
          'review_input_json': review,
        });
        await addRecording(old);
        await old.insert(
          'practice_sessions',
          sessionRow(
            id: otherSessionId,
            profile: otherProfileId,
            state: 'saved',
          ),
        );
        final sessions = await old.query('practice_sessions', orderBy: 'id');
        final drafts = await old.query('session_drafts');
        final recordings = await old.query('recordings');
        await old.close();
        final upgraded = await JournalDatabase.open(
          factory: databaseFactoryFfi,
          path: path,
        );
        try {
          expect(await upgraded.getVersion(), 3);
          expect(
            await upgraded.query('practice_sessions', orderBy: 'id'),
            sessions,
          );
          expect(await upgraded.query('session_drafts'), drafts);
          expect(await upgraded.query('recordings'), recordings);
          await upgraded.insert(
            'practice_sessions',
            sessionRow(
              id: '00000000-0000-4000-8000-000000000013',
              profile: otherProfileId,
              state: 'paused',
            ),
          );
          expect(await upgraded.query('session_drafts'), hasLength(2));
          expect(await upgraded.rawQuery('PRAGMA foreign_key_check'), isEmpty);
          expect(
            (await upgraded.rawQuery('PRAGMA integrity_check'))
                .single
                .values
                .single,
            'ok',
          );
        } finally {
          await upgraded.close();
        }
      } finally {
        await directory.delete(recursive: true);
      }
    },
  );

  test('reopen preserves data and does not rerun creation', () async {
    final directory = await Directory.systemTemp.createTemp(
      'meloop-schema-test-',
    );
    final path = '${directory.path}${Platform.pathSeparator}journal.db';
    try {
      final first = await JournalDatabase.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      await addProfile(first);
      await first.close();
      final reopened = await JournalDatabase.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      expect(await reopened.query('instrument_profiles'), hasLength(1));
      expect(await reopened.getVersion(), JournalDatabase.schemaVersion);
      await reopened.close();
    } finally {
      await directory.delete(recursive: true);
    }
  });

  test('failed initial migration rolls back DDL and user_version', () async {
    final directory = await Directory.systemTemp.createTemp(
      'meloop-rollback-test-',
    );
    final path = '${directory.path}${Platform.pathSeparator}journal.db';
    try {
      final runner = MigrationRunner([
        SchemaMigration(
          version: 1,
          statements: [...initialSchema.statements, 'THIS IS INVALID SQL'],
        ),
      ]);
      await expectLater(
        databaseFactoryFfi.openDatabase(
          path,
          options: JournalDatabase.options(runner: runner),
        ),
        throwsA(isA<DatabaseException>()),
      );
      final inspected = await databaseFactoryFfi.openDatabase(path);
      expect(await inspected.getVersion(), 0);
      expect(
        await inspected.rawQuery(
          "SELECT name FROM sqlite_master WHERE type = 'table'",
        ),
        isEmpty,
      );
      await inspected.close();
      final recovered = await JournalDatabase.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      expect(await recovered.getVersion(), JournalDatabase.schemaVersion);
      await recovered.close();
    } finally {
      await directory.delete(recursive: true);
    }
  });

  test('failed upgrade preserves v1 data and version', () async {
    final directory = await Directory.systemTemp.createTemp(
      'meloop-upgrade-test-',
    );
    final path = '${directory.path}${Platform.pathSeparator}journal.db';
    try {
      final original = await databaseFactoryFfi.openDatabase(
        path,
        options: JournalDatabase.options(
          runner: MigrationRunner(const [initialSchema]),
        ),
      );
      await addProfile(original);
      await original.close();
      final runner = MigrationRunner([
        initialSchema,
        const SchemaMigration(
          version: 2,
          statements: [
            'CREATE TABLE upgrade_probe (id INTEGER PRIMARY KEY)',
            'THIS IS INVALID SQL',
          ],
        ),
      ]);
      await expectLater(
        databaseFactoryFfi.openDatabase(
          path,
          options: JournalDatabase.options(runner: runner),
        ),
        throwsA(isA<DatabaseException>()),
      );
      final recovered = await databaseFactoryFfi.openDatabase(
        path,
        options: JournalDatabase.options(
          runner: MigrationRunner(const [initialSchema]),
        ),
      );
      try {
        expect(await recovered.getVersion(), 1);
        expect(
          (await recovered.query('instrument_profiles')).single['id'],
          profileId,
        );
        expect(
          await recovered.rawQuery(
            "SELECT name FROM sqlite_master WHERE name = 'upgrade_probe'",
          ),
          isEmpty,
        );
      } finally {
        await recovered.close();
      }
    } finally {
      await directory.delete(recursive: true);
    }
  });

  test(
    'newer databases are rejected without destroying existing data',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'meloop-downgrade-test-',
      );
      final path = '${directory.path}${Platform.pathSeparator}journal.db';
      try {
        final future = await databaseFactoryFfi.openDatabase(
          path,
          options: OpenDatabaseOptions(
            version: JournalDatabase.schemaVersion + 1,
            onCreate: (database, version) async {
              await database.execute('CREATE TABLE sentinel (value TEXT)');
              await database.insert('sentinel', {'value': 'preserved'});
            },
          ),
        );
        await future.close();
        await expectLater(
          JournalDatabase.open(factory: databaseFactoryFfi, path: path),
          throwsA(isA<UnsupportedSchemaVersion>()),
        );
        final inspected = await databaseFactoryFfi.openDatabase(path);
        expect(await inspected.getVersion(), JournalDatabase.schemaVersion + 1);
        expect(
          (await inspected.query('sentinel')).single['value'],
          'preserved',
        );
        await inspected.close();
      } finally {
        await directory.delete(recursive: true);
      }
    },
  );

  test('runner rejects gaps in migration history', () {
    expect(
      () =>
          MigrationRunner([const SchemaMigration(version: 2, statements: [])]),
      throwsArgumentError,
    );
  });

  test('v1 upgrade keeps existing sessions and adds nullable BPM without recreating journal', () async {
    final directory = await Directory.systemTemp.createTemp(
      'meloop-bpm-upgrade-',
    );
    final path = '${directory.path}/journal.db';
    try {
      final original = await databaseFactoryFfi.openDatabase(
        path,
        options: JournalDatabase.options(
          runner: MigrationRunner(const [initialSchema]),
        ),
      );
      await addProfile(original);
      await original.insert('practice_sessions', sessionRow(state: 'saved'));
      await original.close();
      final upgraded = await JournalDatabase.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      try {
        expect(await upgraded.getVersion(), JournalDatabase.schemaVersion);
        final saved = (await upgraded.query('saved_practice_sessions')).single;
        expect(saved['id'], sessionId);
        expect(saved['measured_duration_seconds'], 60);
        expect(saved['bpm'], isNull);
        await upgraded.update(
          'practice_sessions',
          {'bpm': 80},
          where: 'id = ?',
          whereArgs: [sessionId],
        );
        expect(
          (await upgraded.query('saved_practice_sessions')).single['bpm'],
          80,
        );
        expect(
          (await upgraded.rawQuery('PRAGMA integrity_check'))
              .single
              .values
              .single,
          'ok',
        );
      } finally {
        await upgraded.close();
      }
    } finally {
      await directory.delete(recursive: true);
    }
  });
}
