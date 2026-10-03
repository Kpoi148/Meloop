import 'dart:typed_data';

import 'package:sqflite/sqflite.dart';

import '../../shared/journal/journal_backup.dart';
import '../../shared/journal/journal_failure.dart';
import '../../shared/journal/journal_models.dart';
import '../../shared/journal/journal_runtime.dart';
import '../../shared/journal/journal_text.dart';
import '../../shared/journal/practice_date.dart';
import '../../shared/journal/practice_review_service.dart';
import '../database/journal_database_owner.dart';
import 'journal_row_mapper.dart';
import 'practice_review_validation.dart';

class SqliteJournalBackupExporter implements JournalBackupExporter {
  const SqliteJournalBackupExporter({
    required this.owner,
    required this.initialLanguage,
    this.clock = const DeviceJournalClock(),
  });
  final JournalDatabaseOwner owner;
  final JournalLanguage initialLanguage;
  final JournalClock clock;

  @override
  Future<Uint8List> export() async {
    try {
      final document = await owner.transaction((db) async {
        final draft = await db.query(
          'practice_sessions',
          columns: ['id'],
          where: "state <> 'saved'",
          limit: 1,
        );
        if (draft.isNotEmpty) {
          throw const BackupFailure(BackupFailureCode.unfinishedSession);
        }
        final profileRows = await db.query(
          'instrument_profiles',
          orderBy: 'id',
          limit: BackupRules.maximumProfiles + 1,
        );
        final sessionRows = await db.query(
          'saved_practice_sessions',
          orderBy: 'id',
          limit: BackupRules.maximumSessions + 1,
        );
        if (profileRows.length > BackupRules.maximumProfiles ||
            sessionRows.length > BackupRules.maximumSessions) {
          throw const BackupFailure(BackupFailureCode.capacityExceeded);
        }
        final profiles = profileRows.map(profileFromRow).toList();
        final sessions = sessionRows.map(sessionFromRow).toList();
        final profileIds = profiles.map((p) => p.id).toSet();
        for (final p in profiles) {
          JournalText.profileName(p.name);
          if (p.instrument == JournalInstrument.other) {
            JournalText.profileName(
              p.customType,
              maxCodePoints: ProfileRules.customTypeMaxCodePoints,
            );
          } else if (p.customType.isNotEmpty) {
            throw const FormatException('Invalid predefined instrument');
          }
          if (p.updatedAt.isBefore(p.createdAt)) {
            throw const FormatException('Invalid profile timestamps');
          }
        }
        // Freeze the local date once for the complete snapshot validation.
        final snapshotClock = _BackupClock(clock.localNow(), clock.utcNow());
        for (final s in sessions) {
          if (!profileIds.contains(s.profileId) ||
              s.state != PracticeState.saved ||
              s.durationSeconds == null ||
              s.measuredDurationSeconds == null ||
              s.measuredDurationSeconds! < 0 ||
              s.measuredDurationSeconds! >
                  PracticeRules.maximumDuration.inSeconds ||
              s.startOffsetMinutes < -BackupRules.maximumStartOffsetMinutes ||
              s.startOffsetMinutes > BackupRules.maximumStartOffsetMinutes ||
              s.updatedAt.isBefore(s.createdAt)) {
            throw const FormatException('Invalid saved session');
          }
          validatedReviewFields(
            PracticeReviewValues(
              title: s.title,
              date: PracticeDate.parse(s.practiceDate.value),
              durationSeconds: s.durationSeconds!,
              practiced: s.practiced,
              difficulty: s.difficulty,
              next: s.next,
              mood: s.mood,
              focus: s.focus,
            ),
            snapshotClock,
          );
        }
        final goalRows = await db.query('weekly_goals', orderBy: 'profile_id');
        final goalByProfile = <String, BackupGoal>{};
        for (final row in goalRows) {
          final id = storedId(row['profile_id']);
          final target = row['target_days'] as int;
          if (!profileIds.contains(id) ||
              target < 1 ||
              target > DateTime.daysPerWeek ||
              (row['enabled'] != 0 && row['enabled'] != 1)) {
            throw const FormatException('Invalid goal');
          }
          goalByProfile[id] = BackupGoal(
            profileId: id,
            enabled: row['enabled'] == 1,
            targetDays: target,
          );
        }
        final preferences = await db.query('app_preferences');
        final reminders = await db.query('reminder_settings');
        final metronome = await db.query('metronome_settings');
        final language = preferences.isEmpty
            ? initialLanguage
            : JournalLanguage.values.byName(
                preferences.single['language'] as String,
              );
        final reminder = reminders.isEmpty ? null : reminders.single;
        final mask = reminder?['weekdays_mask'] as int? ?? 0;
        final time =
            reminder?['local_time_minutes'] as int? ??
            BackupRules.defaultReminderMinutes;
        final enabled = reminder?['enabled'] ?? 0;
        final bpm = metronome.isEmpty
            ? BackupRules.defaultMetronomeBpm
            : metronome.single['bpm'] as int;
        final beats = metronome.isEmpty
            ? BackupRules.defaultBeatsPerBar
            : metronome.single['beats_per_bar'] as int;
        if (mask < 0 ||
            mask >= 1 << DateTime.daysPerWeek ||
            time < 0 ||
            time >= Duration.minutesPerDay ||
            (enabled != 0 && enabled != 1) ||
            (enabled == 1 && mask == 0) ||
            bpm < BackupRules.minimumMetronomeBpm ||
            bpm > BackupRules.maximumMetronomeBpm ||
            beats < BackupRules.minimumBeatsPerBar ||
            beats > BackupRules.maximumBeatsPerBar) {
          throw const FormatException('Invalid settings');
        }
        return JournalBackupDocument(
          exportedAt: snapshotClock.utcNow(),
          profiles: profiles,
          sessions: sessions,
          goals: [
            for (final p in profiles)
              goalByProfile[p.id] ??
                  BackupGoal(
                    profileId: p.id,
                    enabled: false,
                    targetDays: BackupRules.defaultTargetDays,
                  ),
          ],
          settings: BackupSettings(
            language: language,
            reminderEnabled: enabled == 1,
            weekdays: [
              for (var day = 1; day <= DateTime.daysPerWeek; day++)
                if (mask & (1 << (day - 1)) != 0) day,
            ],
            reminderMinutes: time,
            metronomeBpm: bpm,
            beatsPerBar: beats,
          ),
        );
      });
      return document.encode();
    } on DatabaseException {
      throw const JournalFailure(JournalFailureCode.storage);
    } on FormatException {
      throw const JournalFailure(JournalFailureCode.corruptData);
    } on TypeError {
      throw const JournalFailure(JournalFailureCode.corruptData);
    } on ArgumentError {
      throw const JournalFailure(JournalFailureCode.corruptData);
    } on JournalFailure catch (error) {
      if (error.code == JournalFailureCode.invalidInput) {
        throw const JournalFailure(JournalFailureCode.corruptData);
      }
      rethrow;
    }
  }
}

class _BackupClock implements JournalClock {
  const _BackupClock(this.local, this.utc);
  final DateTime local, utc;
  @override
  DateTime localNow() => local;
  @override
  DateTime utcNow() => utc;
}
