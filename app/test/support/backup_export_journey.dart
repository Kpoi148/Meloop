import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/backend/database/journal_database_owner.dart';
import 'package:meloop/backend/journal/sqlite_journal_backup_exporter.dart';
import 'package:meloop/shared/journal/journal_backup.dart';
import 'package:meloop/shared/journal/journal_failure.dart';
import 'package:meloop/shared/journal/journal_models.dart';
import 'package:meloop/shared/journal/journal_runtime.dart';

class BackupTestClock implements JournalClock {
  const BackupTestClock();
  @override
  DateTime localNow() => DateTime(2026, 10, 3, 0, 30);
  @override
  DateTime utcNow() => DateTime.utc(2026, 10, 2, 17, 30);
}

Future<void> runBackupExportJourney(JournalDatabaseOwner owner) async {
  const profile = '00000000-0000-4000-8000-000000000001';
  const other = '00000000-0000-4000-8000-000000000002';
  const session = '00000000-0000-4000-8000-000000000011';
  const deleted = '00000000-0000-4000-8000-000000000012';
  const draft = '00000000-0000-4000-8000-000000000013';
  const clock = BackupTestClock();
  final time = clock.utcNow().millisecondsSinceEpoch;
  final exporter = SqliteJournalBackupExporter(
    owner: owner,
    initialLanguage: JournalLanguage.vi,
    clock: clock,
  );
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
  Future<Map<String, dynamic>> export() async =>
      jsonDecode(utf8.decode(await exporter.export())) as Map<String, dynamic>;
  final blank = await snapshot();
  final empty = await export();
  expect(empty.keys.toSet(), {
    'app',
    'schemaVersion',
    'exportedAt',
    'profiles',
    'sessions',
    'goals',
    'settings',
  });
  expect(empty['app'], 'Meloop');
  expect(empty['schemaVersion'], 1);
  expect(empty['exportedAt'], clock.utcNow().toIso8601String());
  expect(empty['profiles'], isEmpty);
  expect(empty['sessions'], isEmpty);
  expect(empty['goals'], isEmpty);
  expect(empty['settings'], {
    'language': 'vi',
    'reminder': {'enabled': false, 'weekdays': [], 'localTime': '19:30'},
    'metronome': {'bpm': 80, 'beatsPerBar': 4},
  });
  expect(await snapshot(), blank);
  await owner.transaction((db) async {
    for (final id in [profile, other]) {
      await db.insert('instrument_profiles', {
        'id': id,
        'name': id == profile ? 'Đàn QA' : 'Sáo QA',
        'name_key': id,
        'instrument_type': 'guitar',
        'created_at': time,
        'updated_at': time,
      });
    }
    for (final id in [session, deleted]) {
      await db.insert('practice_sessions', {
        'id': id,
        'profile_id': profile,
        'state': 'review',
        'title': 'Luyện 🎵 QA',
        'practice_date': '2026-10-03',
        'start_offset_minutes': 420,
        'practiced': '  Giữ nhịp\nChuyển hợp âm  ',
        'difficulty': 'Đổi dây',
        'next_note': 'Ôn đoạn cuối',
        'mood': 4,
        'focus': null,
        'bpm': 90,
        'title_search': 'derived-only',
        'created_at': time,
        'updated_at': time,
      });
      await db.insert('recordings', {
        'id': id.replaceFirst('00000000001', '00000000002'),
        'session_id': id,
        'status': 'ready',
        'local_relative_path': 'audio/$id.m4a',
        'filename': '$id.m4a',
        'duration_ms': 1000,
        'size_bytes': 1024,
        'sample_rate_hz': 44100,
        'channel_count': 1,
        'created_at': time,
        'updated_at': time,
      });
      await db.update(
        'session_drafts',
        {'accumulated_ms': 60000},
        where: 'session_id = ?',
        whereArgs: [id],
      );
      await db.update(
        'practice_sessions',
        {
          'state': 'saved',
          'duration_seconds': 90,
          'measured_duration_seconds': 60,
          if (id == deleted) 'deleted_at': time,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    await db.insert('weekly_goals', {
      'profile_id': profile,
      'enabled': 1,
      'target_days': 5,
      'updated_at': time,
    });
    await db.insert('app_preferences', {
      'id': 1,
      'language': 'en',
      'selected_profile_id': other,
      'updated_at': time,
    });
    await db.insert('reminder_settings', {
      'id': 1,
      'enabled': 1,
      'weekdays_mask': 65,
      'local_time_minutes': 65,
      'applied_revision': 1,
      'last_delivered_local_date': '2026-10-02',
      'updated_at': time,
    });
    await db.insert('metronome_settings', {
      'id': 1,
      'bpm': 120,
      'beats_per_bar': 3,
      'updated_at': time,
    });
  });
  final before = await snapshot();
  final full = await export();
  expect(full['profiles'], hasLength(2));
  final saved = (full['sessions'] as List).single as Map;
  expect(saved, {
    'id': session,
    'profileId': profile,
    'title': 'Luyện 🎵 QA',
    'practiceDate': '2026-10-03',
    'durationSeconds': 90,
    'measuredDurationSeconds': 60,
    'startOffsetMinutes': 420,
    'createdAt': clock.utcNow().toIso8601String(),
    'updatedAt': clock.utcNow().toIso8601String(),
    'practiced': '  Giữ nhịp\nChuyển hợp âm  ',
    'difficulty': 'Đổi dây',
    'next': 'Ôn đoạn cuối',
    'mood': 4,
    'focus': null,
  });
  expect(full['goals'], [
    {'profileId': profile, 'enabled': true, 'targetDays': 5},
    {'profileId': other, 'enabled': false, 'targetDays': 4},
  ]);
  expect(full['settings'], {
    'language': 'en',
    'reminder': {
      'enabled': true,
      'weekdays': [1, 7],
      'localTime': '01:05',
    },
    'metronome': {'bpm': 120, 'beatsPerBar': 3},
  });
  final encoded = jsonEncode(full);
  for (final forbidden in [
    'recordings',
    'audio/',
    'selectedProfileId',
    'title_search',
    'state',
    'deleted_at',
    'schedule_revision',
    'applied_revision',
    'last_delivered',
    'entitlement',
    'purchase',
  ]) {
    expect(encoded, isNot(contains('"$forbidden')));
  }
  expect(await snapshot(), before);
  // Any owner draft, including another profile, blocks export without changes.
  for (final state in ['running', 'paused', 'review']) {
    await owner.transaction(
      (db) => db.insert('practice_sessions', {
        'id': draft,
        'profile_id': other,
        'state': state,
        'title': 'Raw draft QA',
        'practice_date': '2026-10-03',
        'start_offset_minutes': 420,
        'created_at': time,
        'updated_at': time,
      }),
    );
    final withDraft = await snapshot();
    await expectLater(
      exporter.export(),
      throwsA(
        isA<BackupFailure>().having(
          (e) => e.code,
          'code',
          BackupFailureCode.unfinishedSession,
        ),
      ),
    );
    expect(await snapshot(), withDraft);
    await owner.transaction(
      (db) =>
          db.delete('practice_sessions', where: 'id = ?', whereArgs: [draft]),
    );
  }
  // Calendar validation is device-local, not the UTC date. A future date fails.
  await owner.transaction(
    (db) => db.update(
      'practice_sessions',
      {'practice_date': '2026-10-04'},
      where: 'id = ?',
      whereArgs: [session],
    ),
  );
  final invalid = await snapshot();
  await expectLater(
    exporter.export(),
    throwsA(
      isA<JournalFailure>().having(
        (e) => e.code,
        'code',
        JournalFailureCode.corruptData,
      ),
    ),
  );
  expect(await snapshot(), invalid);
  await owner.transaction(
    (db) => db.update(
      'practice_sessions',
      {'practice_date': '2026-10-03'},
      where: 'id = ?',
      whereArgs: [session],
    ),
  );
  // Export completes its snapshot before the next owner mutation is accepted.
  final pending = export();
  final change = owner.transaction(
    (db) => db.update(
      'weekly_goals',
      {'target_days': 2},
      where: 'profile_id = ?',
      whereArgs: [profile],
    ),
  );
  expect(((await pending)['goals'] as List).first['targetDays'], 5);
  await change;
  expect(((await export())['goals'] as List).first['targetDays'], 2);
  await owner.close();
  await expectLater(
    exporter.export(),
    throwsA(
      isA<JournalFailure>().having(
        (e) => e.code,
        'code',
        JournalFailureCode.closed,
      ),
    ),
  );
}
