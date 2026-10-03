import 'package:sqflite/sqflite.dart';

import '../../shared/journal/journal_backup.dart';
import '../../shared/journal/journal_text.dart';
import '../database/journal_database.dart';

typedef BackupStagingOpener = Future<Database> Function();

/// A private SQLite database per operation, never the live connection or a
/// shared ':memory:' singleton. Closing it discards all staging data.
Future<Database> openBackupStagingDatabase({DatabaseFactory? factory}) =>
    (factory ?? databaseFactory).openDatabase(
      inMemoryDatabasePath,
      options: JournalDatabase.options(singleInstance: false),
    );

const _batchRows = 256;
const backupReplacementTables = [
  'instrument_profiles',
  'practice_sessions',
  'weekly_goals',
  'app_preferences',
  'reminder_settings',
  'metronome_settings',
];

Future<void> populateBackupStagingDatabase(
  Database stage,
  JournalBackupDocument document,
  int now,
) async {
  await stage.transaction((db) async {
    var batch = db.batch();
    var pending = 0;
    Future<void> add(String table, Map<String, Object?> row) async {
      batch.insert(table, row);
      if (++pending == _batchRows) {
        await batch.commit(noResult: true);
        batch = db.batch();
        pending = 0;
      }
    }

    for (final p in document.profiles) {
      await add('instrument_profiles', {
        'id': p.id,
        'name': p.name,
        'name_key': JournalText.profileKey(p.name),
        'instrument_type': p.instrument.name,
        'custom_type': p.customType,
        'created_at': p.createdAt.millisecondsSinceEpoch,
        'updated_at': p.updatedAt.millisecondsSinceEpoch,
      });
    }
    for (final s in document.sessions) {
      await add('practice_sessions', {
        'id': s.id,
        'profile_id': s.profileId,
        'state': 'saved',
        'title': s.title,
        'practice_date': s.practiceDate.value,
        'duration_seconds': s.durationSeconds,
        'measured_duration_seconds': s.measuredDurationSeconds,
        'start_offset_minutes': s.startOffsetMinutes,
        'practiced': s.practiced,
        'difficulty': s.difficulty,
        'next_note': s.next,
        'mood': s.mood,
        'focus': s.focus,
        'title_search': JournalText.searchKey(s.title),
        'practiced_search': JournalText.searchKey(s.practiced),
        'difficulty_search': JournalText.searchKey(s.difficulty),
        'next_search': JournalText.searchKey(s.next),
        'created_at': s.createdAt.millisecondsSinceEpoch,
        'updated_at': s.updatedAt.millisecondsSinceEpoch,
      });
    }
    for (final g in document.goals) {
      await add('weekly_goals', {
        'profile_id': g.profileId,
        'enabled': g.enabled ? 1 : 0,
        'target_days': g.targetDays,
        'updated_at': now,
      });
    }
    final settings = document.settings;
    await add('app_preferences', {
      'id': 1,
      'language': settings.language.name,
      'selected_profile_id': document.profiles.length == 1
          ? document.profiles.single.id
          : null,
      'updated_at': now,
    });
    await add('reminder_settings', {
      'id': 1,
      'enabled': settings.reminderEnabled ? 1 : 0,
      'weekdays_mask': settings.weekdays.fold<int>(
        0,
        (mask, day) => mask | (1 << (day - 1)),
      ),
      'local_time_minutes': settings.reminderMinutes,
      // The live revision is replaced at commit, never copied from the backup.
      'schedule_revision': 1,
      'applied_revision': null,
      'updated_at': now,
    });
    await add('metronome_settings', {
      'id': 1,
      'bpm': settings.metronomeBpm,
      'beats_per_bar': settings.beatsPerBar,
      'updated_at': now,
    });
    if (pending != 0) await batch.commit(noResult: true);
    if ((await db.rawQuery('PRAGMA foreign_key_check')).isNotEmpty ||
        (await db.rawQuery('PRAGMA quick_check')).single.values.single !=
            'ok') {
      throw const FormatException('Invalid staging database');
    }
  });
}

Future<void> copyBackupStagingDatabase(
  Database stage,
  DatabaseExecutor live,
  int reminderRevision,
) async {
  for (final table in backupReplacementTables) {
    var offset = 0;
    while (true) {
      final rows = await stage.query(
        table,
        orderBy: 'rowid',
        limit: _batchRows,
        offset: offset,
      );
      if (rows.isEmpty) break;
      final batch = live.batch();
      for (final row in rows) {
        batch.insert(table, {
          ...row,
          if (table == 'reminder_settings')
            'schedule_revision': reminderRevision,
        });
      }
      await batch.commit(noResult: true);
      offset += rows.length;
    }
  }
}
