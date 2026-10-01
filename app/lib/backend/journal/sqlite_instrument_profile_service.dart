import 'package:sqflite/sqflite.dart';

import '../../shared/journal/journal_failure.dart';
import '../../shared/journal/journal_runtime.dart';
import '../../shared/journal/journal_text.dart';
import '../../shared/profiles/instrument_profile_service.dart';
import '../database/journal_database_owner.dart';

/// Journal profile mutations share one serialized owner with settings/readers.
/// Payment is not implemented: preview entitlement never grants journal Pro.
class SqliteInstrumentProfileService implements InstrumentProfileService {
  const SqliteInstrumentProfileService({
    required this.owner,
    this.clock = const DeviceJournalClock(),
    required this.initialLanguage,
  });
  final JournalDatabaseOwner owner;
  final JournalClock clock;
  final String initialLanguage;

  Future<T> _stored<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ProfileServiceException {
      rethrow;
    } on JournalFailure catch (error) {
      throw ProfileServiceException(
        error.code == JournalFailureCode.invalidInput
            ? ProfileServiceError.invalidInput
            : ProfileServiceError.storage,
      );
    } on DatabaseException {
      throw const ProfileServiceException(ProfileServiceError.storage);
    } on FormatException {
      throw const ProfileServiceException(ProfileServiceError.storage);
    } on TypeError {
      throw const ProfileServiceException(ProfileServiceError.storage);
    } on ArgumentError {
      throw const ProfileServiceException(ProfileServiceError.storage);
    }
  }

  void _id(String id) {
    if (!JournalId.isValid(id)) {
      throw const ProfileServiceException(ProfileServiceError.invalidInput);
    }
  }

  Future<void> _select(DatabaseExecutor db, String id) async {
    if (initialLanguage != 'vi' && initialLanguage != 'en') {
      throw const ProfileServiceException(ProfileServiceError.invalidInput);
    }
    await db.rawInsert(
      '''
INSERT INTO app_preferences(id, language, selected_profile_id, updated_at)
VALUES(1, ?, ?, ?) ON CONFLICT(id) DO UPDATE SET
selected_profile_id=excluded.selected_profile_id, updated_at=excluded.updated_at
''',
      [initialLanguage, id, clock.utcNow().millisecondsSinceEpoch],
    );
  }

  Future<Map<String, Object?>> _find(DatabaseExecutor db, String id) async {
    final rows = await db.query(
      'instrument_profiles',
      where: 'id=?',
      whereArgs: [id],
    );
    if (rows.isEmpty) {
      throw const ProfileServiceException(ProfileServiceError.missingProfile);
    }
    return rows.single;
  }

  Future<void> _unique(
    DatabaseExecutor db,
    String key, {
    String? except,
  }) async {
    final rows = await db.query(
      'instrument_profiles',
      columns: ['id'],
      where: 'name_key=?',
      whereArgs: [key],
    );
    if (rows.any((r) => r['id'] != except)) {
      throw const ProfileServiceException(ProfileServiceError.duplicateName);
    }
  }

  @override
  Future<ProfileDirectory> load() =>
      _stored(() => owner.read(readProfileDirectory));

  @override
  Future<ProfileDirectory> create({
    required String requestId,
    required String name,
    required InstrumentType instrumentType,
    required String customType,
  }) => _stored(() async {
    _id(requestId);
    final normalized = JournalText.profileName(name);
    final custom = instrumentType == InstrumentType.other
        ? JournalText.profileName(
            customType,
            maxCodePoints: ProfileRules.customTypeMaxCodePoints,
          )
        : '';
    return owner.transaction((db) async {
      // The request UUID is the durable profile identity, including after restart.
      final existing = await db.query(
        'instrument_profiles',
        where: 'id=?',
        whereArgs: [requestId],
      );
      if (existing.isNotEmpty) {
        final row = existing.single;
        if (row['name'] != normalized ||
            row['instrument_type'] != instrumentType.name ||
            row['custom_type'] != custom) {
          throw const ProfileServiceException(ProfileServiceError.invalidInput);
        }
      } else {
        final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM instrument_profiles'),
        )!;
        if (count >= ProfileRules.freeProfileLimit) {
          throw const ProfileServiceException(ProfileServiceError.freeLimit);
        }
        final key = JournalText.profileKey(normalized);
        await _unique(db, key);
        final now = clock.utcNow().millisecondsSinceEpoch;
        await db.insert('instrument_profiles', {
          'id': requestId,
          'name': normalized,
          'name_key': key,
          'instrument_type': instrumentType.name,
          'custom_type': custom,
          'created_at': now,
          'updated_at': now,
        });
        // Target default belongs to schema v1; goal remains disabled until configured.
        await db.insert('weekly_goals', {
          'profile_id': requestId,
          'enabled': 0,
          'updated_at': now,
        });
      }
      await _select(db, requestId);
      return readProfileDirectory(db);
    });
  });

  @override
  Future<ProfileDirectory> select(String profileId) => _stored(() async {
    _id(profileId);
    return owner.transaction((db) async {
      await _find(db, profileId);
      await _select(db, profileId);
      return readProfileDirectory(db);
    });
  });

  @override
  Future<ProfileDirectory> rename({
    required String profileId,
    required String name,
  }) => _stored(() async {
    _id(profileId);
    final normalized = JournalText.profileName(name);
    return owner.transaction((db) async {
      final original = await _find(db, profileId);
      final key = JournalText.profileKey(normalized);
      await _unique(db, key, except: profileId);
      final now = clock.utcNow().millisecondsSinceEpoch;
      await db.update(
        'instrument_profiles',
        {
          'name': normalized,
          'name_key': key,
          'updated_at': now < (original['created_at'] as int)
              ? original['created_at']
              : now,
        },
        where: 'id=?',
        whereArgs: [profileId],
      );
      return readProfileDirectory(db);
    });
  });

  Future<ProfileDeletionImpact> _impact(DatabaseExecutor db, String id) async {
    await _find(db, id);
    final unfinished = await db.query(
      'practice_sessions',
      columns: ['id'],
      where: "profile_id=? AND state<>'saved'",
      whereArgs: [id],
      limit: 1,
    );
    if (unfinished.isNotEmpty) {
      throw const ProfileServiceException(
        ProfileServiceError.unfinishedSession,
      );
    }
    final directory = await readProfileDirectory(db);
    final profile = directory.byId(id)!;
    return ProfileDeletionImpact(
      savedSessionCount: profile.savedSessionCount,
      recordingCount: profile.recordingCount,
    );
  }

  @override
  Future<ProfileDeletionImpact> deletionImpact(String profileId) =>
      _stored(() async {
        _id(profileId);
        return owner.read((db) => _impact(db, profileId));
      });

  @override
  Future<ProfileDirectory> delete(String profileId) => _stored(() async {
    _id(profileId);
    return owner.transaction((db) async {
      final impact = await _impact(db, profileId);
      // File cleanup worker is B10. Do not claim deletion of recording files yet.
      if (impact.recordingCount != 0) {
        throw const ProfileServiceException(ProfileServiceError.storage);
      }
      await db.delete(
        'instrument_profiles',
        where: 'id=?',
        whereArgs: [profileId],
      );
      return readProfileDirectory(db);
    });
  });
}

Future<ProfileDirectory> readProfileDirectory(DatabaseExecutor db) async {
  final rows = await db.rawQuery('''
SELECT p.*, (SELECT COUNT(*) FROM practice_sessions s
 WHERE s.profile_id=p.id AND s.state='saved') AS saved_count,
 (SELECT COUNT(*) FROM recordings r JOIN practice_sessions s ON s.id=r.session_id
 WHERE s.profile_id=p.id) AS recording_count
FROM instrument_profiles p ORDER BY p.created_at ASC, p.id ASC
''');
  final preferences = await db.query(
    'app_preferences',
    columns: ['selected_profile_id'],
  );
  return ProfileDirectory(
    profiles: List.unmodifiable(
      rows.map(
        (row) => InstrumentProfile(
          id: row['id'] as String,
          name: row['name'] as String,
          instrumentType: InstrumentType.values.byName(
            row['instrument_type'] as String,
          ),
          customType: row['custom_type'] as String,
          savedSessionCount: row['saved_count'] as int,
          recordingCount: row['recording_count'] as int,
        ),
      ),
    ),
    selectedProfileId: preferences.isEmpty
        ? null
        : preferences.single['selected_profile_id'] as String?,
    isPro: false,
  );
}
