import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/backend/database/journal_database.dart';
import 'package:meloop/backend/database/journal_database_owner.dart';
import 'package:meloop/backend/journal/sqlite_practice_review_service.dart';
import 'package:meloop/backend/journal/sqlite_practice_session_update_service.dart';
import 'package:meloop/shared/journal/journal_failure.dart';
import 'package:meloop/shared/journal/journal_runtime.dart';
import 'package:meloop/shared/journal/practice_date.dart';
import 'package:meloop/shared/journal/practice_review_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../database/journal_database_test.dart'
    show
        addProfile,
        addRecording,
        sessionRow,
        profileId,
        otherProfileId,
        sessionId,
        otherSessionId;

// A local date already advanced to Oct 1 while UTC is still Sep 30.
class MidnightClock implements JournalClock {
  @override
  DateTime localNow() => DateTime(2026, 10, 1, 0, 30);
  @override
  DateTime utcNow() => DateTime.utc(2026, 9, 30, 17, 30);
}

PracticeReviewValues values({
  String title = 'Luyện sáo',
  String date = '2026-10-01',
  int seconds = 60,
  String practiced = '',
  String difficulty = '',
  String next = '',
  int? mood,
  int? focus,
  int? bpm,
}) => PracticeReviewValues(
  title: title,
  date: PracticeDate.parse(date),
  durationSeconds: seconds,
  practiced: practiced,
  difficulty: difficulty,
  next: next,
  mood: mood,
  focus: focus,
  bpm: bpm,
);

void main() {
  sqfliteFfiInit();
  for (final editing in [false, true]) {
    group(editing ? 'Edit SRS' : 'Save SRS', () {
      late Directory temp;
      late JournalDatabaseOwner owner;
      Future<void> mutate(PracticeReviewValues input) async {
        if (editing) {
          await SqlitePracticeSessionUpdateService(
            owner: owner,
            clock: MidnightClock(),
          ).update(profileId: profileId, sessionId: sessionId, values: input);
        } else {
          await SqlitePracticeReviewService(
            owner: owner,
            clock: MidnightClock(),
          ).save(sessionId, input);
        }
      }

      Future<Map<String, List<Map<String, Object?>>>> snapshot() => owner.read(
        (db) async => {
          for (final table in [
            'instrument_profiles',
            'practice_sessions',
            'session_drafts',
            'recordings',
          ])
            table: await db.query(table),
        },
      );
      Future<Map<String, Object?>> row() => owner.read(
        (db) async => (await db.query(
          'practice_sessions',
          where: 'id = ?',
          whereArgs: [sessionId],
        )).single,
      );
      setUp(() async {
        temp = await Directory.systemTemp.createTemp('meloop-srs-');
        owner = JournalDatabaseOwner(
          open: () => JournalDatabase.open(
            factory: databaseFactoryFfi,
            path: '${temp.path}/journal.db',
          ),
        );
        await owner.read((executor) async {
          final db = executor as Database;
          await addProfile(db);
          await addProfile(db, id: otherProfileId, name: 'Flute');
          await db.insert('practice_sessions', {
            ...sessionRow(state: 'review'),
            'mood': 4,
            'focus': 5,
            'bpm': 80,
          });
          await db.update(
            'session_drafts',
            {'accumulated_ms': 60000},
            where: 'session_id = ?',
            whereArgs: [sessionId],
          );
          await addRecording(db);
          if (editing) {
            await db.update(
              'practice_sessions',
              {
                'state': 'saved',
                'duration_seconds': 60,
                'measured_duration_seconds': 60,
              },
              where: 'id = ?',
              whereArgs: [sessionId],
            );
          }
          await db.insert(
            'practice_sessions',
            sessionRow(
              id: otherSessionId,
              profile: otherProfileId,
              state: 'paused',
            ),
          );
        });
      });
      tearDown(() async {
        await owner.close();
        await temp.delete(recursive: true);
      });

      test('invalid fields do not change saved data, raw drafts or recording links', () async {
        final before = await snapshot();
        final invalid = <PracticeReviewValues Function()>[
          () => values(title: ''),
          () => values(title: '   '),
          () => values(title: '\u200b'),
          () => values(title: 'Bad\nTitle'),
          () => values(title: List.filled(101, '😀').join()),
          () => values(date: '1999-12-31'),
          () => values(date: '2026-02-30'),
          () => values(date: 'not-a-date'),
          () => values(date: '2026-10-02'),
          () => values(seconds: -1),
          () => values(seconds: 0),
          () => values(seconds: 86401),
          () => values(mood: 0),
          () => values(mood: 6),
          () => values(focus: 0),
          () => values(focus: 6),
          () => values(bpm: 19),
          () => values(bpm: 401),
          for (final badNote in [
            List.filled(2001, '😀').join(),
            List.filled(2001, ' ').join(),
            'bad\u0000',
          ]) ...[
            () => values(practiced: badNote),
            () => values(difficulty: badNote),
            () => values(next: badNote),
          ],
        ];
        for (var i = 0; i < invalid.length; i++) {
          await expectLater(
            Future<void>(() async => mutate(invalid[i]())),
            throwsA(
              isA<JournalFailure>().having(
                (e) => e.code,
                'code',
                JournalFailureCode.invalidInput,
              ),
            ),
            reason: 'invalid case $i',
          );
          expect(
            await snapshot(),
            before,
            reason: 'invalid case $i must not write',
          );
        }
        // Failed Save must keep Review available for a valid retry; Edit keeps one row.
        await mutate(values());
        expect((await row())['title'], 'Luyện sáo');
        final after = await snapshot();
        expect(after['recordings'], before['recordings']);
        expect(
          after['practice_sessions']!.where((r) => r['id'] == sessionId),
          hasLength(1),
        );
        expect(
          after['session_drafts']!.where(
            (r) => r['session_id'] == otherSessionId,
          ),
          before['session_drafts']!.where(
            (r) => r['session_id'] == otherSessionId,
          ),
        );
      });

      test('inclusive minimum date/duration/BPM, normalized title and nullable ratings', () async {
        await mutate(
          values(
            title: '  a\u0301  ',
            date: '2000-01-01',
            seconds: 1,
            practiced: ' \t\r\n ',
            difficulty: 'Dòng 1\r\nDòng 2',
            next: '  lần sau  ',
            bpm: 20,
          ),
        );
        final saved = await row();
        expect(saved['title'], 'á');
        expect(saved['title_search'], 'a');
        expect(saved['practice_date'], '2000-01-01');
        expect(saved['duration_seconds'], 1);
        expect(saved['measured_duration_seconds'], 60);
        expect(saved['practiced'], '');
        expect(saved['difficulty'], 'Dòng 1\r\nDòng 2');
        expect(saved['next_note'], '  lần sau  ');
        expect(saved['mood'], isNull);
        expect(saved['focus'], isNull);
        expect(saved['bpm'], 20);
      });

      test('inclusive Unicode maxima, duration/rating/BPM bounds and device-local today', () async {
        final title = List.filled(100, '😀').join();
        final note = List.filled(2000, '😀').join();
        final before = await row();
        await mutate(
          values(
            title: title,
            seconds: 86400,
            practiced: note,
            difficulty: note,
            next: note,
            mood: 1,
            focus: 5,
            bpm: 400,
          ),
        );
        final saved = await row();
        expect(saved['title'], title);
        expect(saved['practice_date'], '2026-10-01');
        expect(saved['duration_seconds'], 86400);
        for (final field in ['practiced', 'difficulty', 'next_note']) {
          expect(saved[field], note);
        }
        expect(saved['mood'], 1);
        expect(saved['focus'], 5);
        expect(saved['bpm'], 400);
        expect(saved['measured_duration_seconds'], 60);
        for (final field in [
          'id',
          'profile_id',
          'created_at',
          'start_offset_minutes',
        ]) {
          expect(saved[field], before[field]);
        }
      });

      test(
        'both opposite rating bounds and optional BPM null persist',
        () async {
          await mutate(values(mood: 5, focus: 1));
          final saved = await row();
          expect(saved['mood'], 5);
          expect(saved['focus'], 1);
          expect(saved['bpm'], isNull);
        },
      );
    });
  }
}
