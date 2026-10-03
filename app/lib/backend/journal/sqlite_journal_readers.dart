import 'package:sqflite/sqflite.dart';

import '../../shared/journal/journal_failure.dart';
import '../../shared/journal/journal_models.dart';
import '../../shared/journal/journal_readers.dart';
import '../../shared/journal/journal_runtime.dart';
import '../../shared/journal/journal_text.dart';
import '../../shared/journal/practice_date.dart';
import '../../shared/journal/weekly_practice_goal.dart';
import '../database/journal_database_owner.dart';
import 'journal_row_mapper.dart';

void _requireId(String value) {
  if (!JournalId.isValid(value)) {
    throw const JournalFailure(JournalFailureCode.invalidInput);
  }
}

Future<T> _readStored<T>(
  JournalDatabaseOwner owner,
  Future<T> Function(DatabaseExecutor) read,
) async {
  try {
    return await owner.read((db) async {
      try {
        return await read(db);
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
    });
  } on DatabaseException {
    throw const JournalFailure(JournalFailureCode.storage);
  }
}

class SqliteJournalProfileReader implements JournalProfileReader {
  const SqliteJournalProfileReader(this.owner);
  final JournalDatabaseOwner owner;

  @override
  Future<List<JournalProfile>> list() => _readStored(
    owner,
    (db) async => List.unmodifiable(
      (await db.query(
        'instrument_profiles',
        orderBy: 'created_at ASC, id ASC',
      )).map(profileFromRow),
    ),
  );

  @override
  Future<JournalProfile?> find(String profileId) {
    _requireId(profileId);
    return _readStored(owner, (db) async {
      final rows = await db.query(
        'instrument_profiles',
        where: 'id = ?',
        whereArgs: [profileId],
        limit: 1,
      );
      return rows.isEmpty ? null : profileFromRow(rows.single);
    });
  }
}

class SqliteJournalSessionReader implements JournalSessionReader {
  const SqliteJournalSessionReader(this.owner);
  final JournalDatabaseOwner owner;

  @override
  Future<PracticeSession?> findSaved({
    required String profileId,
    required String sessionId,
  }) {
    _requireId(profileId);
    _requireId(sessionId);
    return _readStored(owner, (db) async {
      final rows = await db.query(
        'saved_practice_sessions',
        where: 'id = ? AND profile_id = ?',
        whereArgs: [sessionId, profileId],
        limit: 1,
      );
      return rows.isEmpty ? null : sessionFromRow(rows.single);
    });
  }

  @override
  Future<List<PracticeSession>> saved({
    required String profileId,
    PracticeDate? from,
    PracticeDate? through,
    String query = '',
  }) {
    _requireId(profileId);
    if (from != null && through != null && from.isAfter(through)) {
      throw const JournalFailure(JournalFailureCode.invalidInput);
    }
    final clauses = ['profile_id = ?'];
    final args = <Object?>[profileId];
    if (from != null) {
      clauses.add('practice_date >= ?');
      args.add(from.value);
    }
    if (through != null) {
      clauses.add('practice_date <= ?');
      args.add(through.value);
    }
    final queryText = query.trim();
    if (queryText.isNotEmpty) {
      clauses.add(
        r"(title_search LIKE ? ESCAPE '\' OR practiced_search LIKE ? ESCAPE '\' OR difficulty_search LIKE ? ESCAPE '\' OR next_search LIKE ? ESCAPE '\')",
      );
      args.addAll(List.filled(4, JournalText.literalLikePattern(queryText)));
    }
    return _readStored(
      owner,
      (db) async => List.unmodifiable(
        (await db.query(
          'saved_practice_sessions',
          where: clauses.join(' AND '),
          whereArgs: args,
          orderBy: 'practice_date DESC, created_at DESC, id DESC',
        )).map(sessionFromRow),
      ),
    );
  }

  @override
  Future<PracticeDraft?> unfinished({String? profileId, String? sessionId}) {
    if (profileId != null) _requireId(profileId);
    if (sessionId != null) _requireId(sessionId);
    return _readStored(
      owner,
      (db) =>
          readUnfinishedDraft(db, profileId: profileId, sessionId: sessionId),
    );
  }
}

class SqliteJournalPreferencesReader implements JournalPreferencesReader {
  const SqliteJournalPreferencesReader(this.owner);
  final JournalDatabaseOwner owner;

  @override
  Future<JournalPreferences?> read() => _readStored(owner, (db) async {
    final rows = await db.query(
      'app_preferences',
      where: 'id = ?',
      whereArgs: const [1],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final row = rows.single;
    return JournalPreferences(
      language: JournalLanguage.values.byName(row['language'] as String),
      selectedProfileId: row['selected_profile_id'] == null
          ? null
          : storedId(row['selected_profile_id']),
      updatedAt: storedUtc(row['updated_at']),
    );
  });
}

class SqliteWeeklyPracticeGoalReader implements WeeklyPracticeGoalReader {
  const SqliteWeeklyPracticeGoalReader(this.owner);
  final JournalDatabaseOwner owner;

  @override
  Future<WeeklyPracticeGoal?> read(String profileId) {
    _requireId(profileId);
    return _readStored(owner, (db) async {
      final rows = await db.query(
        'weekly_goals',
        where: 'profile_id = ?',
        whereArgs: [profileId],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      final row = rows.single;
      if (row['enabled'] != 0 && row['enabled'] != 1) {
        throw const FormatException('Invalid weekly goal state');
      }
      return WeeklyPracticeGoal(
        enabled: row['enabled'] == 1,
        targetDays: row['target_days'] as int,
      );
    });
  }
}

Future<PracticeDraft?> readUnfinishedDraft(
  DatabaseExecutor db, {
  String? profileId,
  String? sessionId,
}) async {
  if (profileId != null) _requireId(profileId);
  if (sessionId != null) _requireId(sessionId);
  final clauses = ["s.state <> 'saved'"];
  final args = <Object?>[];
  if (profileId != null) {
    clauses.add('s.profile_id = ?');
    args.add(profileId);
  }
  if (sessionId != null) {
    clauses.add('s.id = ?');
    args.add(sessionId);
  }
  final rows = await db.rawQuery('''
SELECT s.*, d.accumulated_ms, d.checkpoint_at, d.review_input_json,
       d.updated_at AS draft_updated_at
FROM practice_sessions s LEFT JOIN session_drafts d ON d.session_id = s.id
WHERE ${clauses.join(' AND ')}
ORDER BY (s.state = 'running') DESC, s.updated_at DESC, s.created_at DESC, s.id DESC
''', args);
  if (rows.isEmpty) return null;
  if (((profileId != null || sessionId != null) && rows.length != 1) ||
      rows.first['accumulated_ms'] == null) {
    throw const JournalFailure(JournalFailureCode.corruptData);
  }
  final row = rows.first;
  return PracticeDraft(
    session: sessionFromRow(row),
    accumulatedMilliseconds: row['accumulated_ms'] as int,
    checkpointAt: storedUtc(row['checkpoint_at']),
    updatedAt: storedUtc(row['draft_updated_at']),
    reviewInput: reviewFromJson(row['review_input_json']),
  );
}
