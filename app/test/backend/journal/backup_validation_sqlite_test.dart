import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/backend/database/journal_database.dart';
import 'package:meloop/backend/database/journal_database_owner.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../support/backup_validation_journey.dart';

void main() {
  sqfliteFfiInit();
  test(
    'exported SQLite JSON validates and invalid input cannot change source',
    () async {
      final owner = JournalDatabaseOwner(
        open: () => JournalDatabase.open(
          factory: databaseFactoryFfi,
          path: inMemoryDatabasePath,
        ),
      );
      try {
        await runBackupValidationJourney(owner);
      } finally {
        await owner.close();
      }
    },
  );
}
