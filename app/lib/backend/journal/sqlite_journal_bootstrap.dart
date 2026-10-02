import 'package:sqflite/sqflite.dart';

import '../../shared/journal/journal_bootstrap.dart';
import '../../shared/journal/journal_failure.dart';
import '../../shared/journal/journal_runtime.dart';
import '../database/journal_database_owner.dart';
import 'sqlite_instrument_profile_service.dart';
import 'sqlite_journal_readers.dart';

/// Read one consistent snapshot. Repair selection only; never mutate a draft.
class SqliteJournalBootstrap implements JournalBootstrapReader {
  const SqliteJournalBootstrap({
    required this.owner,
    required this.clock,
    required this.initialLanguage,
  });
  final JournalDatabaseOwner owner;
  final JournalClock clock;
  final String initialLanguage;
  @override
  Future<JournalBootstrapSnapshot> read() async {
    try {
      return await owner.transaction((db) async {
        var directory = await readProfileDirectory(db);
        final selected = directory.profiles.length == 1
            ? directory.profiles.single.id
            : directory.selectedProfile?.id;
        if (selected != directory.selectedProfileId) {
          if (initialLanguage != 'vi' && initialLanguage != 'en') {
            throw const JournalFailure(JournalFailureCode.invalidInput);
          }
          await db.rawInsert(
            '''
INSERT INTO app_preferences(id,language,selected_profile_id,updated_at)
VALUES(1,?,?,?) ON CONFLICT(id) DO UPDATE SET
selected_profile_id=excluded.selected_profile_id, updated_at=excluded.updated_at
''',
            [initialLanguage, selected, clock.utcNow().millisecondsSinceEpoch],
          );
          directory = await readProfileDirectory(db);
        }
        final draft = selected == null
            ? null
            : await readUnfinishedDraft(db, profileId: selected);
        return JournalBootstrapSnapshot(directory: directory, draft: draft);
      });
    } on JournalFailure {
      rethrow;
    } on DatabaseException {
      throw const JournalFailure(JournalFailureCode.storage);
    } on FormatException {
      throw const JournalFailure(JournalFailureCode.corruptData);
    } on TypeError {
      throw const JournalFailure(JournalFailureCode.corruptData);
    } on ArgumentError {
      throw const JournalFailure(JournalFailureCode.corruptData);
    }
  }
}
