import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/backend/database/journal_database_owner.dart';
import 'package:meloop/backend/journal/sqlite_journal_backup_exporter.dart';
import 'package:meloop/backend/journal/stream_journal_backup_validator.dart';
import 'package:meloop/shared/journal/backup_validation.dart';
import 'package:meloop/shared/journal/journal_models.dart';

import 'backup_export_journey.dart' show BackupTestClock;

Future<void> runBackupValidationJourney(JournalDatabaseOwner owner) async {
  const id = '00000000-0000-4000-8000-000000000001';
  const session = '00000000-0000-4000-8000-000000000011';
  const clock = BackupTestClock();
  final time = clock.utcNow().millisecondsSinceEpoch;
  await owner.transaction((db) async {
    await db.insert('instrument_profiles', {
      'id': id,
      'name': 'Guitar QA',
      'name_key': 'guitar qa',
      'instrument_type': 'guitar',
      'created_at': time,
      'updated_at': time,
    });
    await db.insert('practice_sessions', {
      'id': session,
      'profile_id': id,
      'state': 'saved',
      'title': 'Luyện 🎵 QA',
      'practice_date': '2026-10-03',
      'start_offset_minutes': 420,
      'duration_seconds': 90,
      'measured_duration_seconds': 60,
      'practiced': '  Giữ nhịp\nĐổi dây  ',
      'mood': 4,
      'focus': null,
      'created_at': time,
      'updated_at': time,
    });
    await db.insert('weekly_goals', {
      'profile_id': id,
      'enabled': 0,
      'target_days': 6,
      'updated_at': time,
    });
    await db.insert('app_preferences', {
      'id': 1,
      'language': 'en',
      'selected_profile_id': id,
      'updated_at': time,
    });
  });
  Future<Map<String, Object?>> snapshot() => owner.read((db) async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name",
    );
    return {
      for (final table in tables)
        table['name'] as String: await db.query(
          table['name'] as String,
          orderBy: 'rowid',
        ),
    };
  });
  final before = await snapshot();
  final bytes = await SqliteJournalBackupExporter(
    owner: owner,
    initialLanguage: JournalLanguage.vi,
    clock: clock,
  ).export();
  const validator = StreamJournalBackupValidator(clock: clock);
  final preview = await validator.validate(
    Stream.fromIterable([bytes.sublist(0, 7), bytes.sublist(7)]),
  );
  expect(preview.profileCount, 1);
  expect(preview.sessionCount, 1);
  expect(preview.document.toJson(), jsonDecode(utf8.decode(bytes)));
  expect(preview.document.sessions.single.practiced, '  Giữ nhịp\nĐổi dây  ');
  expect(preview.document.goals.single.enabled, isFalse);
  expect(preview.document.goals.single.targetDays, 6);
  expect(preview.document.settings.language, JournalLanguage.en);
  expect(await snapshot(), before);
  final bad = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
  bad['sessions'][0]['profileId'] = '00000000-0000-4000-8000-000000000002';
  await expectLater(
    validator.validate(Stream.value(utf8.encode(jsonEncode(bad)))),
    throwsA(
      isA<BackupValidationFailure>().having(
        (e) => e.code,
        'code',
        BackupValidationFailureCode.invalidBackup,
      ),
    ),
  );
  expect(await snapshot(), before);
  final retry = await validator.validate(Stream.value(bytes));
  expect(retry.document.toJson(), preview.document.toJson());
  expect(await snapshot(), before);
}
