import 'dart:math' as math;

import 'package:sqflite/sqflite.dart';

import '../../shared/journal/journal_failure.dart';
import '../../shared/journal/journal_models.dart';
import '../../shared/journal/journal_runtime.dart';
import '../../shared/journal/journal_text.dart';
import '../../shared/journal/practice_review_service.dart';
import '../database/journal_database_owner.dart';
import 'journal_row_mapper.dart';
import 'sqlite_journal_readers.dart';

class SqlitePracticeReviewService implements PracticeReviewService {
  const SqlitePracticeReviewService({
    required this.owner,
    this.clock = const DeviceJournalClock(),
  });
  final JournalDatabaseOwner owner;
  final JournalClock clock;

  @override
  Future<String> rename(String sessionId, String title) async {
    final normalized = JournalText.sessionTitle(title);
    try {
      return await owner.transaction((db) async {
        final draft = await readUnfinishedDraft(db, sessionId: sessionId);
        if (draft == null || draft.session.id != sessionId) {
          throw const JournalFailure(JournalFailureCode.invalidInput);
        }
        await db.update(
          'practice_sessions',
          {
            'title': normalized,
            'title_search': JournalText.searchKey(normalized),
            'updated_at': math.max(
              clock.utcNow().millisecondsSinceEpoch,
              draft.session.updatedAt.millisecondsSinceEpoch,
            ),
          },
          where: 'id = ?',
          whereArgs: [sessionId],
        );
        return normalized;
      });
    } on DatabaseException {
      throw const JournalFailure(JournalFailureCode.storage);
    }
  }

  @override
  Future<PracticeDraft> read(String sessionId) async {
    final draft = await SqliteJournalSessionReader(owner)
        .unfinished(sessionId: sessionId);
    if (draft == null ||
        draft.session.id != sessionId ||
        draft.session.state != PracticeState.review) {
      throw const JournalFailure(JournalFailureCode.invalidInput);
    }
    return draft;
  }

  @override
  Future<PracticeSession> save(
    String sessionId,
    PracticeReviewValues values,
  ) async {
    if (!JournalId.isValid(sessionId)) {
      throw const JournalFailure(JournalFailureCode.invalidInput);
    }
    try {
      return await owner.transaction((db) async {
        final rows = await db.query(
          'practice_sessions',
          where: 'id = ?',
          whereArgs: [sessionId],
        );
        if (rows.isEmpty || rows.single['deleted_at'] != null) {
          throw const JournalFailure(JournalFailureCode.invalidInput);
        }
        final session = sessionFromRow(rows.single);
        // A retry after a successful commit must not create or overwrite a row.
        if (session.state == PracticeState.saved) return session;
        final draft = await readUnfinishedDraft(db, sessionId: sessionId);
        if (draft == null ||
            draft.session.id != sessionId ||
            session.state != PracticeState.review) {
          throw const JournalFailure(JournalFailureCode.invalidInput);
        }
        final title = JournalText.sessionTitle(values.title);
        bool validRating(int? value) =>
            value == null ||
            (value >= PracticeRules.minimumRating &&
                value <= PracticeRules.maximumRating);
        if (values.durationSeconds < 1 ||
            values.durationSeconds > PracticeRules.maximumDuration.inSeconds ||
            !validRating(values.mood) ||
            !validRating(values.focus) ||
            (values.bpm != null &&
                (values.bpm! < PracticeRules.minimumBpm ||
                    values.bpm! > PracticeRules.maximumBpm)) ||
            [values.practiced, values.difficulty, values.next].any(
              (text) =>
                  text.runes.length > PracticeRules.noteMaxCodePoints ||
                  text.contains('\u0000'),
            )) {
          throw const JournalFailure(JournalFailureCode.invalidInput);
        }
        final now = math.max(
          clock.utcNow().millisecondsSinceEpoch,
          math.max(
            draft.updatedAt.millisecondsSinceEpoch,
            session.updatedAt.millisecondsSinceEpoch,
          ),
        );
        await db.update(
          'practice_sessions',
          {
            'state': PracticeState.saved.name,
            'title': title,
            'practice_date': values.date.value,
            'duration_seconds': values.durationSeconds,
            'measured_duration_seconds':
                draft.accumulatedMilliseconds ~/ Duration.millisecondsPerSecond,
            'practiced': values.practiced,
            'difficulty': values.difficulty,
            'next_note': values.next,
            'mood': values.mood,
            'focus': values.focus,
            'bpm': values.bpm,
            'title_search': JournalText.searchKey(title),
            'practiced_search': JournalText.searchKey(values.practiced),
            'difficulty_search': JournalText.searchKey(values.difficulty),
            'next_search': JournalText.searchKey(values.next),
            'updated_at': now,
          },
          where: 'id = ? AND state = ?',
          whereArgs: [sessionId, PracticeState.review.name],
        );
        // The schema removes the sidecar in the same transaction as Save.
        return sessionFromRow(
          (await db.query(
            'practice_sessions',
            where: 'id = ?',
            whereArgs: [sessionId],
          )).single,
        );
      });
    } on DatabaseException {
      throw const JournalFailure(JournalFailureCode.storage);
    }
  }
}
