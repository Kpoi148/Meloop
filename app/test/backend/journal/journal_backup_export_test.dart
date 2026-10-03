import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/backend/database/journal_database.dart';
import 'package:meloop/backend/database/journal_database_owner.dart';
import 'package:meloop/backend/journal/sqlite_journal_backup_exporter.dart';
import 'package:meloop/shared/journal/journal_failure.dart';
import 'package:meloop/shared/journal/journal_models.dart';
import 'package:meloop/shared/journal/journal_backup.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../support/backup_export_journey.dart';

void main() {
  sqfliteFfiInit();
  test(
    'export snapshot is portable, draft-safe and does not mutate journal',
    () async {
      final temp = await Directory.systemTemp.createTemp('meloop-backup-');
      final owner = JournalDatabaseOwner(
        open: () => JournalDatabase.open(
          factory: databaseFactoryFfi,
          path: '${temp.path}/journal.db',
        ),
      );
      try {
        await runBackupExportJourney(owner);
      } finally {
        await owner.close();
        await temp.delete(recursive: true);
      }
    },
  );
  test(
    'a SQLite read failure reports storage and never returns backup bytes',
    () async {
      final database = await JournalDatabase.open(
        factory: databaseFactoryFfi,
        path: inMemoryDatabasePath,
      );
      final owner = JournalDatabaseOwner(open: () async => database);
      final exporter = SqliteJournalBackupExporter(
        owner: owner,
        initialLanguage: JournalLanguage.en,
      );
      try {
        await database.execute('DROP TABLE metronome_settings');
        await expectLater(
          exporter.export(),
          throwsA(
            isA<JournalFailure>().having(
              (e) => e.code,
              'code',
              JournalFailureCode.storage,
            ),
          ),
        );
        expect(
          await owner.read((db) => db.query('instrument_profiles')),
          isEmpty,
        );
      } finally {
        await owner.close();
      }
    },
  );
  test('1000 profiles export without a plan gate; 1001 reject without truncation', () async {
    final owner = JournalDatabaseOwner(
      open: () => JournalDatabase.open(
        factory: databaseFactoryFfi,
        path: inMemoryDatabasePath,
      ),
    );
    final exporter = SqliteJournalBackupExporter(
      owner: owner,
      initialLanguage: JournalLanguage.en,
      clock: const BackupTestClock(),
    );
    Future<void> insert(int value) => owner.transaction((db) async {
      await db.insert('instrument_profiles', {
        'id':
            '00000000-0000-4000-8000-${value.toRadixString(16).padLeft(12, '0')}',
        'name': 'QA $value',
        'name_key': 'qa $value',
        'instrument_type': 'guitar',
        'created_at': 0,
        'updated_at': 0,
      });
    });
    try {
      await owner.transaction((db) async {
        for (var i = 0; i < BackupRules.maximumProfiles; i++) {
          await db.insert('instrument_profiles', {
            'id':
                '00000000-0000-4000-8000-${i.toRadixString(16).padLeft(12, '0')}',
            'name': 'QA $i',
            'name_key': 'qa $i',
            'instrument_type': 'guitar',
            'created_at': 0,
            'updated_at': 0,
          });
        }
      });
      final result = jsonDecode(utf8.decode(await exporter.export())) as Map;
      expect(result['profiles'], hasLength(BackupRules.maximumProfiles));
      expect(result['settings']['language'], 'en');
      await insert(BackupRules.maximumProfiles);
      await expectLater(
        exporter.export(),
        throwsA(
          isA<BackupFailure>().having(
            (e) => e.code,
            'code',
            BackupFailureCode.capacityExceeded,
          ),
        ),
      );
      expect(
        await owner.read((db) => db.query('instrument_profiles')),
        hasLength(BackupRules.maximumProfiles + 1),
      );
    } finally {
      await owner.close();
    }
  });
}
