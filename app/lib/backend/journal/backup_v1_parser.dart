import '../../shared/journal/backup_validation.dart';
import '../../shared/journal/journal_backup.dart';
import '../../shared/journal/journal_models.dart';
import '../../shared/journal/journal_runtime.dart';
import '../../shared/journal/journal_text.dart';
import '../../shared/journal/practice_date.dart';

/// Strict schema-v1 parser, independent of SQLite and Android.
class BackupV1Parser {
  const BackupV1Parser();
  JournalBackupDocument parse(Object? value, {required PracticeDate today}) {
    if (value is! Map<String, dynamic> ||
        value['app'] != BackupRules.app ||
        value['schemaVersion'] is! int) {
      _invalid();
    }
    if (value['schemaVersion'] != BackupRules.schemaVersion) {
      throw const BackupValidationFailure(
        BackupValidationFailureCode.unsupportedVersion,
      );
    }
    final root = _object(value, {
      'app',
      'schemaVersion',
      'exportedAt',
      'profiles',
      'sessions',
      'goals',
      'settings',
    });
    final exportedAt = _utc(root['exportedAt']);
    final profileRows = _list(root['profiles'], BackupRules.maximumProfiles);
    final sessionRows = _list(root['sessions'], BackupRules.maximumSessions);
    final goalRows = _list(root['goals'], BackupRules.maximumProfiles);
    final ids = <String>{}, names = <String>{};
    final profiles = <JournalProfile>[];
    for (final value in profileRows) {
      final p = _object(value, {
        'id',
        'name',
        'instrumentType',
        'customType',
        'createdAt',
        'updatedAt',
      });
      final id = _id(p['id']);
      final name = JournalText.profileName(_text(p['name']));
      if (!ids.add(id) || !names.add(JournalText.profileKey(name))) _invalid();
      final instrument = JournalInstrument.values.byName(
        _text(p['instrumentType']),
      );
      final custom = _text(p['customType']);
      final customType = instrument == JournalInstrument.other
          ? JournalText.profileName(
              custom,
              maxCodePoints: ProfileRules.customTypeMaxCodePoints,
            )
          : custom;
      if (instrument != JournalInstrument.other && custom.isNotEmpty) {
        _invalid();
      }
      final created = _utc(p['createdAt']), updated = _utc(p['updatedAt']);
      if (updated.isBefore(created)) _invalid();
      profiles.add(
        JournalProfile(
          id: id,
          name: name,
          instrument: instrument,
          customType: customType,
          createdAt: created,
          updatedAt: updated,
        ),
      );
    }
    final sessionIds = <String>{};
    final sessions = <PracticeSession>[];
    for (final value in sessionRows) {
      final s = _object(
        value,
        {
          'id',
          'profileId',
          'title',
          'practiceDate',
          'durationSeconds',
          'measuredDurationSeconds',
          'startOffsetMinutes',
          'createdAt',
          'updatedAt',
        },
        optional: {'practiced', 'difficulty', 'next', 'mood', 'focus'},
      );
      final id = _id(s['id']), owner = _id(s['profileId']);
      if (!sessionIds.add(id) || !ids.contains(owner)) _invalid();
      final date = PracticeDate.parse(_text(s['practiceDate']));
      if (date.isAfter(today)) _invalid();
      final created = _utc(s['createdAt']), updated = _utc(s['updatedAt']);
      if (updated.isBefore(created)) _invalid();
      sessions.add(
        PracticeSession(
          id: id,
          profileId: owner,
          state: PracticeState.saved,
          title: JournalText.sessionTitle(_text(s['title'])),
          practiceDate: date,
          durationSeconds: _integer(
            s['durationSeconds'],
            PracticeRules.minimumDurationSeconds,
            PracticeRules.maximumDuration.inSeconds,
          ),
          measuredDurationSeconds: _integer(
            s['measuredDurationSeconds'],
            0,
            PracticeRules.maximumDuration.inSeconds,
          ),
          startOffsetMinutes: _integer(
            s['startOffsetMinutes'],
            -BackupRules.maximumStartOffsetMinutes,
            BackupRules.maximumStartOffsetMinutes,
          ),
          practiced: _note(s, 'practiced'),
          difficulty: _note(s, 'difficulty'),
          next: _note(s, 'next'),
          mood: _rating(s['mood']),
          focus: _rating(s['focus']),
          createdAt: created,
          updatedAt: updated,
        ),
      );
    }
    final goals = <String, BackupGoal>{};
    for (final value in goalRows) {
      final g = _object(value, {'profileId', 'enabled', 'targetDays'});
      final id = _id(g['profileId']);
      if (!ids.contains(id) || goals.containsKey(id)) _invalid();
      goals[id] = BackupGoal(
        profileId: id,
        enabled: _boolean(g['enabled']),
        targetDays: _integer(g['targetDays'], 1, DateTime.daysPerWeek),
      );
    }
    final settings = _object(root['settings'], {
      'language',
      'reminder',
      'metronome',
    });
    final language = JournalLanguage.values.byName(_text(settings['language']));
    final reminder = _object(settings['reminder'], {
      'enabled',
      'weekdays',
      'localTime',
    });
    final enabled = _boolean(reminder['enabled']);
    final weekdays = _list(
      reminder['weekdays'],
      DateTime.daysPerWeek,
    ).map((v) => _integer(v, 1, DateTime.daysPerWeek)).toList();
    if (weekdays.toSet().length != weekdays.length ||
        (enabled && weekdays.isEmpty)) {
      _invalid();
    }
    final localTime = _text(reminder['localTime']);
    if (!RegExp(r'^\d{2}:\d{2}$').hasMatch(localTime)) _invalid();
    final hours = int.parse(localTime.substring(0, 2)),
        minutes = int.parse(localTime.substring(3));
    if (hours >= Duration.hoursPerDay || minutes >= Duration.minutesPerHour) {
      _invalid();
    }
    final metronome = _object(settings['metronome'], {'bpm', 'beatsPerBar'});
    return JournalBackupDocument(
      exportedAt: exportedAt,
      profiles: profiles,
      sessions: sessions,
      goals: [
        for (final p in profiles)
          goals[p.id] ??
              BackupGoal(
                profileId: p.id,
                enabled: false,
                targetDays: BackupRules.defaultTargetDays,
              ),
      ],
      settings: BackupSettings(
        language: language,
        reminderEnabled: enabled,
        weekdays: weekdays,
        reminderMinutes: hours * Duration.minutesPerHour + minutes,
        metronomeBpm: _integer(
          metronome['bpm'],
          BackupRules.minimumMetronomeBpm,
          BackupRules.maximumMetronomeBpm,
        ),
        beatsPerBar: _integer(
          metronome['beatsPerBar'],
          BackupRules.minimumBeatsPerBar,
          BackupRules.maximumBeatsPerBar,
        ),
      ),
    );
  }

  Map<String, dynamic> _object(
    Object? value,
    Set<String> required, {
    Set<String> optional = const {},
  }) {
    if (value is! Map<String, dynamic> ||
        !value.keys.toSet().containsAll(required) ||
        value.keys.any(
          (key) => !required.contains(key) && !optional.contains(key),
        )) {
      _invalid();
    }
    return value;
  }

  List<dynamic> _list(Object? value, int maximum) {
    if (value is! List) _invalid();
    final list = value;
    if (list.length > maximum) {
      throw const BackupValidationFailure(
        BackupValidationFailureCode.capacityExceeded,
      );
    }
    return list;
  }

  String _text(Object? value) {
    if (value is! String) _invalid();
    return value;
  }

  String _id(Object? value) {
    final id = _text(value);
    if (!JournalId.isValid(id)) _invalid();
    return id;
  }

  bool _boolean(Object? value) {
    if (value is! bool) _invalid();
    return value;
  }

  int _integer(Object? value, int minimum, int maximum) {
    if (value is! int || value < minimum || value > maximum) _invalid();
    return value;
  }

  String _note(Map<String, dynamic> value, String key) =>
      value.containsKey(key) ? JournalText.note(_text(value[key])) : '';
  int? _rating(Object? value) => value == null
      ? null
      : _integer(
          value,
          PracticeRules.minimumRating,
          PracticeRules.maximumRating,
        );
  static final _timestamp = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(?:\.\d{1,6})?Z$',
  );
  DateTime _utc(Object? value) {
    final text = _text(value), match = _timestamp.firstMatch(_text(value));
    if (match == null) _invalid();
    final parsed = DateTime.tryParse(text);
    if (parsed == null || parsed.millisecondsSinceEpoch < 0) _invalid();
    final parts = [for (var i = 1; i <= 6; i++) int.parse(match.group(i)!)];
    if ([
      parsed.year,
      parsed.month,
      parsed.day,
      parsed.hour,
      parsed.minute,
      parsed.second,
    ].asMap().entries.any((entry) => entry.value != parts[entry.key])) {
      _invalid();
    }
    return parsed;
  }

  Never _invalid() => throw const BackupValidationFailure(
    BackupValidationFailureCode.invalidBackup,
  );
}
