import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/backend/database/journal_database.dart';
import 'package:meloop/backend/database/migration_runner.dart';
import 'package:meloop/backend/database/migrations/v001_initial_schema.dart';
import 'package:meloop/backend/database/migrations/v002_session_bpm.dart';
import 'package:meloop/backend/database/migrations/v003_profile_practice_drafts.dart';
import 'package:meloop/backend/database/migrations/v004_saved_session_deletion.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'journal_database_test.dart'
    show
        addProfile,
        addRecording,
        sessionRow,
        profileId,
        otherProfileId,
        sessionId,
        otherSessionId,
        timestamp;

void main() {
  sqfliteFfiInit();
  for (final failFirst in [false, true]) {
    test(
      'v3 to v4 retains every existing row; migration rollback: $failFirst',
      () async {
        final temp = await Directory.systemTemp.createTemp(
          'meloop-delete-upgrade-',
        );
        final path = '${temp.path}/journal.db';
        const previous = [
          initialSchema,
          sessionBpmSchema,
          profilePracticeDraftsSchema,
        ];
        try {
          final old = await databaseFactoryFfi.openDatabase(
            path,
            options: JournalDatabase.options(runner: MigrationRunner(previous)),
          );
          await addProfile(old);
          await addProfile(old, id: otherProfileId, name: 'Flute');
          await old.insert('practice_sessions', {
            ...sessionRow(state: 'review'),
            'bpm': 83,
            'practiced': 'Audio QA',
          });
          await addRecording(old);
          await old.update('session_drafts', {'accumulated_ms': 60000});
          await old.update('practice_sessions', {
            'state': 'saved',
            'duration_seconds': 60,
            'measured_duration_seconds': 60,
          });
          await old.insert(
            'practice_sessions',
            sessionRow(
              id: otherSessionId,
              profile: otherProfileId,
              state: 'paused',
            ),
          );
          await old.update('session_drafts', {
            'accumulated_ms': 12000,
            'review_input_json': '{"title":"Draft QA"}',
          });
          await old.insert('weekly_goals', {
            'profile_id': profileId,
            'enabled': 1,
            'target_days': 3,
            'updated_at': timestamp,
          });
          await old.insert('app_preferences', {
            'id': 1,
            'language': 'vi',
            'selected_profile_id': otherProfileId,
            'updated_at': timestamp,
          });
          await old.insert('metronome_settings', {
            'id': 1,
            'bpm': 100,
            'updated_at': timestamp,
          });
          await old.insert('reminder_settings', {
            'id': 1,
            'updated_at': timestamp,
          });
          final tables = (await old.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name",
          )).map((row) => row['name'] as String).toList();
          final before = <String, List<Map<String, Object?>>>{};
          for (final table in tables) {
            before[table] = await old.query(table, orderBy: 'rowid');
          }
          await old.close();
          if (failFirst) {
            await expectLater(
              databaseFactoryFfi.openDatabase(
                path,
                options: JournalDatabase.options(
                  runner: MigrationRunner([
                    ...previous,
                    SchemaMigration(
                      version: 4,
                      statements: [
                        ...savedSessionDeletionSchema.statements,
                        'THIS IS INVALID SQL',
                      ],
                    ),
                  ]),
                ),
              ),
              throwsA(isA<DatabaseException>()),
            );
            final inspected = await databaseFactoryFfi.openDatabase(path);
            expect(await inspected.getVersion(), 3);
            for (final table in tables) {
              expect(
                await inspected.query(table, orderBy: 'rowid'),
                before[table],
              );
            }
            expect(
              (await inspected.rawQuery('PRAGMA table_info(practice_sessions)'))
                  .map((row) => row['name']),
              isNot(contains('deleted_at')),
            );
            await inspected.close();
          }
          final upgraded = await JournalDatabase.open(
            factory: databaseFactoryFfi,
            path: path,
          );
          try {
            expect(await upgraded.getVersion(), 4);
            for (final table in tables) {
              final expected = table == 'practice_sessions'
                  ? before[table]!
                        .map((row) => {...row, 'deleted_at': null})
                        .toList()
                  : before[table];
              expect(
                await upgraded.query(table, orderBy: 'rowid'),
                expected,
                reason: table,
              );
            }
            expect(
              (await upgraded.query('saved_practice_sessions')).single['id'],
              sessionId,
            );
            expect(
              await upgraded.rawQuery('PRAGMA foreign_key_check'),
              isEmpty,
            );
            expect(
              (await upgraded.rawQuery('PRAGMA integrity_check'))
                  .single
                  .values
                  .single,
              'ok',
            );
            await expectLater(
              upgraded.update(
                'practice_sessions',
                {'deleted_at': timestamp},
                where: 'id = ?',
                whereArgs: [otherSessionId],
              ),
              throwsA(isA<DatabaseException>()),
            );
          } finally {
            await upgraded.close();
          }
        } finally {
          await temp.delete(recursive: true);
        }
      },
    );
  }
}
