import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meloop/backend/database/journal_database.dart';
import 'package:meloop/backend/database/journal_database_owner.dart';
import 'package:meloop/shared/journal/journal_runtime.dart';
import 'package:sqflite/sqflite.dart';

import '../test/support/practice_statistics_journey.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Android SQLite: Home statistics after Save/Edit/Delete', (
    tester,
  ) async {
    final path =
        '${await getDatabasesPath()}/statistics-${const UuidJournalIdentifiers().newId()}.db';
    final owner = JournalDatabaseOwner(
      open: () => JournalDatabase.open(path: path),
    );
    try {
      await runPracticeStatisticsJourney(owner);
    } finally {
      await owner.close();
      await deleteDatabase(path);
    }
  });
}
