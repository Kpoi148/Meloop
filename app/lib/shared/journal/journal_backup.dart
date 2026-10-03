import 'dart:convert';
import 'dart:typed_data';

import 'journal_models.dart';

class BackupRules {
  BackupRules._();
  static const app = 'Meloop';
  static const schemaVersion = 1;
  static const maximumBytes = 20 * 1024 * 1024;
  static const maximumProfiles = 1000;
  static const maximumSessions = 100000;
  static const maximumJsonDepth = 16;
  static const defaultTargetDays = 4;
  static const defaultReminderMinutes = 19 * 60 + 30;
  static const defaultMetronomeBpm = 80;
  static const defaultBeatsPerBar = 4;
  static const minimumMetronomeBpm = 40;
  static const maximumMetronomeBpm = 240;
  static const minimumBeatsPerBar = 1;
  static const maximumBeatsPerBar = 12;
  static const maximumStartOffsetMinutes = 14 * Duration.minutesPerHour;
}

enum BackupFailureCode { unfinishedSession, capacityExceeded }

/// Contains no journal text; callers map codes to localized messages.
class BackupFailure implements Exception {
  const BackupFailure(this.code);
  final BackupFailureCode code;
  @override
  String toString() => 'BackupFailure(${code.name})';
}

abstract interface class JournalBackupExporter {
  /// Returns UTF-8 JSON, not a file-write success. The caller owns destination
  /// selection, plaintext/audio warnings, cancellation and stream completion.
  Future<Uint8List> export();
}

class BackupGoal {
  const BackupGoal({
    required this.profileId,
    required this.enabled,
    required this.targetDays,
  });
  final String profileId;
  final bool enabled;
  final int targetDays;
  Map<String, Object?> toJson() => {
    'profileId': profileId,
    'enabled': enabled,
    'targetDays': targetDays,
  };
}

class BackupSettings {
  BackupSettings({
    required this.language,
    required this.reminderEnabled,
    required List<int> weekdays,
    required this.reminderMinutes,
    required this.metronomeBpm,
    required this.beatsPerBar,
  }) : weekdays = List.unmodifiable(weekdays);
  final JournalLanguage language;
  final bool reminderEnabled;
  final List<int> weekdays;
  final int reminderMinutes, metronomeBpm, beatsPerBar;
  Map<String, Object?> toJson() => {
    'language': language.name,
    'reminder': {
      'enabled': reminderEnabled,
      'weekdays': weekdays,
      'localTime':
          '${(reminderMinutes ~/ Duration.minutesPerHour).toString().padLeft(2, '0')}:${(reminderMinutes % Duration.minutesPerHour).toString().padLeft(2, '0')}',
    },
    'metronome': {'bpm': metronomeBpm, 'beatsPerBar': beatsPerBar},
  };
}

/// Schema v1 whitelist; database-only fields never enter portable JSON.
class JournalBackupDocument {
  JournalBackupDocument({
    required this.exportedAt,
    required List<JournalProfile> profiles,
    required List<PracticeSession> sessions,
    required List<BackupGoal> goals,
    required this.settings,
  }) : profiles = List.unmodifiable(profiles),
       sessions = List.unmodifiable(sessions),
       goals = List.unmodifiable(goals);
  final DateTime exportedAt;
  final List<JournalProfile> profiles;
  final List<PracticeSession> sessions;
  final List<BackupGoal> goals;
  final BackupSettings settings;

  Map<String, Object?> toJson() => {
    'app': BackupRules.app,
    'schemaVersion': BackupRules.schemaVersion,
    'exportedAt': exportedAt.toUtc().toIso8601String(),
    'profiles': [
      for (final p in profiles)
        {
          'id': p.id,
          'name': p.name,
          'instrumentType': p.instrument.name,
          'customType': p.customType,
          'createdAt': p.createdAt.toUtc().toIso8601String(),
          'updatedAt': p.updatedAt.toUtc().toIso8601String(),
        },
    ],
    'sessions': [
      for (final s in sessions)
        {
          'id': s.id,
          'profileId': s.profileId,
          'title': s.title,
          'practiceDate': s.practiceDate.value,
          'durationSeconds': s.durationSeconds,
          'measuredDurationSeconds': s.measuredDurationSeconds,
          'startOffsetMinutes': s.startOffsetMinutes,
          'createdAt': s.createdAt.toUtc().toIso8601String(),
          'updatedAt': s.updatedAt.toUtc().toIso8601String(),
          'practiced': s.practiced,
          'difficulty': s.difficulty,
          'next': s.next,
          'mood': s.mood,
          'focus': s.focus,
        },
    ],
    'goals': goals.map((goal) => goal.toJson()).toList(),
    'settings': settings.toJson(),
  };

  Uint8List encode() {
    if (profiles.length > BackupRules.maximumProfiles ||
        sessions.length > BackupRules.maximumSessions) {
      throw const BackupFailure(BackupFailureCode.capacityExceeded);
    }
    final output = _BoundedBackupBytes();
    final encoder = JsonUtf8Encoder().startChunkedConversion(output);
    encoder.add(toJson());
    encoder.close();
    return output.bytes.takeBytes();
  }
}

/// Stops encoding before an over-limit output can grow without bound.
class _BoundedBackupBytes implements Sink<List<int>> {
  final bytes = BytesBuilder(copy: false);
  @override
  void add(List<int> chunk) {
    if (bytes.length + chunk.length > BackupRules.maximumBytes) {
      throw const BackupFailure(BackupFailureCode.capacityExceeded);
    }
    bytes.add(chunk);
  }

  @override
  void close() {}
}
