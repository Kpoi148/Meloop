import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/backend/journal/stream_journal_backup_validator.dart';
import 'package:meloop/shared/journal/backup_validation.dart';
import 'package:meloop/shared/journal/journal_backup.dart';

import '../../support/backup_export_journey.dart' show BackupTestClock;

Map<String, dynamic> validBackupFixture() => jsonDecode(
  jsonEncode({
    'app': 'Meloop',
    'schemaVersion': 1,
    'exportedAt': '2026-10-02T17:30:00.000Z',
    'profiles': [
      {
        'id': '00000000-0000-4000-8000-000000000001',
        'name': 'Đàn QA',
        'instrumentType': 'guitar',
        'customType': '',
        'createdAt': '2026-10-01T00:00:00Z',
        'updatedAt': '2026-10-02T00:00:00Z',
      },
    ],
    'sessions': [
      {
        'id': '00000000-0000-4000-8000-000000000011',
        'profileId': '00000000-0000-4000-8000-000000000001',
        'title': 'Luyện 🎵 QA',
        'practiceDate': '2026-10-03',
        'durationSeconds': 60,
        'measuredDurationSeconds': 0,
        'startOffsetMinutes': 420,
        'createdAt': '2026-10-01T00:00:00Z',
        'updatedAt': '2026-10-02T00:00:00Z',
      },
    ],
    'goals': [],
    'settings': {
      'language': 'vi',
      'reminder': {'enabled': false, 'weekdays': [], 'localTime': '19:30'},
      'metronome': {'bpm': 80, 'beatsPerBar': 4},
    },
  }),
) as Map<String, dynamic>;

void main() {
  const validator = StreamJournalBackupValidator(clock: BackupTestClock());
  Future<BackupPreview> validate(Object? input) =>
      validator.validate(Stream.value(utf8.encode(jsonEncode(input))));
  final invalid = throwsA(
    isA<BackupValidationFailure>().having(
      (e) => e.code,
      'code',
      BackupValidationFailureCode.invalidBackup,
    ),
  );
  test('v1 preview uses local calendar, defaults optional fields, preserves Unicode', () async {
    final fixture = validBackupFixture();
    final preview = await validate(fixture);
    expect(preview.profileCount, 1);
    expect(preview.sessionCount, 1);
    expect(preview.exportedAt, DateTime.utc(2026, 10, 2, 17, 30));
    final session = preview.document.sessions.single;
    expect(session.title, 'Luyện 🎵 QA');
    expect(session.practiced, '');
    expect(session.mood, isNull);
    expect(preview.document.goals.single.targetDays, 4);
    expect(preview.document.goals.single.enabled, isFalse);
    expect(() => preview.document.profiles.clear(), throwsUnsupportedError);
    final again = await validator.validate(
      Stream.value(preview.document.encode()),
    );
    expect(again.document.toJson(), preview.document.toJson());
    fixture['profiles'] = [];
    fixture['sessions'] = [];
    final empty = await validate(fixture);
    expect(empty.profileCount, 0);
    expect(empty.sessionCount, 0);
  });
  test('reject invalid types, fields, identities and ownership without skipping rows', () async {
    final mutations = <void Function(Map<String, dynamic>)>[
      (v) => v['app'] = 'Other',
      (v) => v['schemaVersion'] = '1',
      (v) => v['schemaVersion'] = 1.0,
      (v) => v['schemaVersion'] = true,
      (v) => v.remove('settings'),
      (v) => v['pro'] = true,
      (v) => v['profiles'] = '[]',
      (v) => v['profiles'].add(Map.of(v['profiles'][0])),
      (v) => v['profiles'][0]['id'] = 'not-uuid',
      (v) => v['profiles'][0]['name'] = ' ',
      (v) => v['profiles'][0]['instrumentType'] = 'unknown',
      (v) => v['profiles'][0]['customType'] = 'unexpected',
      (v) => v['profiles'][0]['localPath'] = '/private/audio',
      (v) => v['sessions'].add(Map.of(v['sessions'][0])),
      (v) => v['sessions'][0]['profileId'] =
          '00000000-0000-4000-8000-000000000002',
      (v) => v['sessions'][0]['title'] = '',
      (v) => v['sessions'][0]['state'] = 'saved',
      (v) => v['sessions'][0]['bpm'] = 80,
      (v) => v['sessions'][0]['recordings'] = [],
      (v) => v['sessions'][0]['durationSeconds'] = '60',
      (v) => v['sessions'][0]['durationSeconds'] = 60.0,
      (v) => v['sessions'][0]['durationSeconds'] = true,
      (v) => v['sessions'][0]['durationSeconds'] = 0,
      (v) => v['sessions'][0]['durationSeconds'] = 86401,
      (v) => v['sessions'][0]['measuredDurationSeconds'] = null,
      (v) => v['sessions'][0]['measuredDurationSeconds'] = -1,
      (v) => v['sessions'][0]['startOffsetMinutes'] = 841,
      (v) => v['sessions'][0]['practiceDate'] = '2026-02-30',
      (v) => v['sessions'][0]['practiceDate'] = '1999-12-31',
      (v) => v['sessions'][0]['practiceDate'] = '2026-10-04',
      (v) => v['sessions'][0]['practiced'] = null,
      (v) => v['sessions'][0]['difficulty'] = 'x' * 2001,
      (v) => v['sessions'][0]['next'] = 'a\u0000b',
      (v) => v['sessions'][0]['mood'] = 0,
      (v) => v['sessions'][0]['focus'] = 6,
      (v) => v['sessions'][0]['focus'] = 1.0,
      (v) => v['sessions'][0]['mood'] = false,
      (v) => v['exportedAt'] = '2026-02-30T00:00:00Z',
      (v) => v['exportedAt'] = '2026-10-01T24:00:00Z',
      (v) => v['exportedAt'] = '2026-10-01T00:00:00+00:00',
      (v) => v['profiles'][0]['updatedAt'] = '2026-09-01T00:00:00Z',
      (v) => v['settings']['permission'] = true,
      (v) => v['settings']['language'] = 'xx',
      (v) => v['settings']['reminder']['enabled'] = 1,
      (v) => v['settings']['reminder']['enabled'] = true,
      (v) => v['settings']['reminder']['weekdays'] = [1, 1],
      (v) => v['settings']['reminder']['weekdays'] = [0],
      (v) => v['settings']['reminder']['weekdays'] = [true],
      (v) => v['settings']['reminder']['localTime'] = '24:00',
      (v) => v['settings']['metronome']['bpm'] = 241,
      (v) => v['settings']['metronome']['beatsPerBar'] = 0,
    ];
    for (var i = 0; i < mutations.length; i++) {
      final input = validBackupFixture();
      mutations[i](input);
      await expectLater(
        validate(input),
        invalid,
        reason: 'invalid fixture case $i',
      );
    }
  });
  test(
    'goals reject duplicate/orphan/type/range errors; retain disabled target',
    () async {
      final input = validBackupFixture();
      final goal = {
        'profileId': input['profiles'][0]['id'],
        'enabled': false,
        'targetDays': 7,
      };
      input['goals'] = [goal];
      expect((await validate(input)).document.goals.single.targetDays, 7);
      for (final patch in [
        {'profileId': '00000000-0000-4000-8000-000000000002'},
        {'enabled': 0},
        {'targetDays': 0},
        {'targetDays': 8},
        {'targetDays': 4.0},
        {'extra': true},
      ]) {
        input['goals'] = [
          {...goal, ...patch},
        ];
        await expectLater(validate(input), invalid);
      }
      input['goals'] = [goal, goal];
      await expectLater(validate(input), invalid);
      input['goals'] = [];
      input['profiles'].add({
        ...input['profiles'][0],
        'id': '00000000-0000-4000-8000-000000000002',
        'name': 'đÀN qa',
      });
      await expectLater(validate(input), invalid);
    },
  );
  test(
    'newer versions and collection capacity have distinct safe failures',
    () async {
      await expectLater(
        validate({'app': 'Meloop', 'schemaVersion': 2, 'newSchema': {}}),
        throwsA(
          isA<BackupValidationFailure>().having(
            (e) => e.code,
            'code',
            BackupValidationFailureCode.unsupportedVersion,
          ),
        ),
      );
      for (final entry in [
        ('profiles', BackupRules.maximumProfiles),
        ('sessions', BackupRules.maximumSessions),
      ]) {
        final input = validBackupFixture();
        input[entry.$1] = List.filled(entry.$2 + 1, {});
        await expectLater(
          validate(input),
          throwsA(
            isA<BackupValidationFailure>().having(
              (e) => e.code,
              'code',
              BackupValidationFailureCode.capacityExceeded,
            ),
          ),
        );
      }
    },
  );
  test(
    'bounded stream cancels on overflow and accepts exactly 20 MiB',
    () async {
      final payload = utf8.encode(jsonEncode(validBackupFixture()));
      final padding = List<int>.filled(
        BackupRules.maximumBytes - payload.length,
        0x20,
      );
      expect(
        (await validator.validate(Stream.fromIterable([payload, padding])))
            .sessionCount,
        1,
      );
      var reads = 0;
      var closed = false;
      Stream<List<int>> oversized() async* {
        try {
          reads++;
          yield payload;
          reads++;
          yield padding;
          reads++;
          yield [0x20];
          reads++;
          yield [0x20];
        } finally {
          closed = true;
        }
      }

      await expectLater(
        validator.validate(oversized()),
        throwsA(
          isA<BackupValidationFailure>().having(
            (e) => e.code,
            'code',
            BackupValidationFailureCode.capacityExceeded,
          ),
        ),
      );
      expect(reads, 3);
      expect(closed, isTrue);
    },
  );
  test('malformed UTF8/JSON, nonfinite values, deep nesting and read errors fail safely', () async {
    for (final bytes in <List<int>>[
      [],
      [0xff],
      utf8.encode('{'),
      utf8.encode('null'),
      utf8.encode('${'[' * 1000}${']' * 1000}'),
      utf8.encode(
        jsonEncode(validBackupFixture())
            .replaceFirst('"durationSeconds":60', '"durationSeconds":1e309'),
      ),
    ]) {
      await expectLater(validator.validate(Stream.value(bytes)), invalid);
    }
    await expectLater(
      validator.validate(Stream.error(StateError('injected read error'))),
      throwsA(
        isA<BackupValidationFailure>().having(
          (e) => e.code,
          'code',
          BackupValidationFailureCode.readFailure,
        ),
      ),
    );
    final bytes = utf8.encode(jsonEncode(validBackupFixture()));
    final preview = await validator.validate(
      Stream.fromIterable([
        for (var i = 0; i < bytes.length; i++) [bytes[i]],
      ]),
    );
    expect(preview.document.sessions.single.title, 'Luyện 🎵 QA');
  });
}
