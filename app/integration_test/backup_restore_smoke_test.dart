import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meloop/backend/database/journal_database.dart';
import 'package:meloop/backend/database/journal_database_owner.dart';
import 'package:meloop/backend/journal/backup_staging_database.dart';
import 'package:meloop/shared/journal/journal_runtime.dart';
import 'package:sqflite/sqflite.dart';

import '../test/support/backup_restore_journey.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Android: isolated staging, rollback and restore SQLite journal', (
    tester,
  ) async {
    final path =
        '${await getDatabasesPath()}/restore-${const UuidJournalIdentifiers().newId()}.db';
    final owner = JournalDatabaseOwner(
      open: () => JournalDatabase.open(path: path),
    );
    try {
      await runBackupRestoreJourney(owner, openBackupStagingDatabase);
    } finally {
      await owner.close();
      await deleteDatabase(path);
    }
  });
}
