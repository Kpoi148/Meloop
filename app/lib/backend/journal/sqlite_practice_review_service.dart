import 'dart:convert';
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
import 'practice_review_validation.dart';

class SqlitePracticeReviewService implements PracticeReviewService {
  const SqlitePracticeReviewService({
    required this.owner,
    this.clock = const DeviceJournalClock(),
  });
  final JournalDatabaseOwner owner;
  final JournalClock clock;

  @override
  Future<void> persistInput(String sessionId, ReviewInput input) async {
    if (!JournalId.isValid(sessionId) ||
        !validPracticeRating(input.mood) ||
        !validPracticeRating(input.focus)) {
      throw const JournalFailure(JournalFailureCode.invalidInput);
    }
    final json = jsonEncode({
      'title': input.title,
      'practiceDate': input.practiceDate,
      'durationHoursInput': input.durationHoursInput,
      'durationMinutesInput': input.durationMinutesInput,
      'durationSecondsInput': input.durationSecondsInput,
      'practiced': input.practiced,
      'difficulty': input.difficulty,
      'next': input.next,
      'mood': input.mood,
      'focus': input.focus,
      if (input.bpmInput != null) 'bpmInput': input.bpmInput,
    });
    try {
      await owner.transaction((db) async {
        final draft = await readUnfinishedDraft(db, sessionId: sessionId);
        if (draft == null || draft.session.state != PracticeState.review) {
          throw const JournalFailure(JournalFailureCode.invalidInput);
        }
        await db.update(
          'session_drafts',
          {
            'review_input_json': json,
            'updated_at': math.max(
              clock.utcNow().millisecondsSinceEpoch,
              draft.updatedAt.millisecondsSinceEpoch,
            ),
          },
          where: 'session_id = ?',
          whereArgs: [sessionId],
        );
      });
    } on DatabaseException {
      throw const JournalFailure(JournalFailureCode.storage);
    }
  }

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
        final fields = validatedReviewFields(values, clock);
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
            ...fields,
            'measured_duration_seconds':
                draft.accumulatedMilliseconds ~/ Duration.millisecondsPerSecond,
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
