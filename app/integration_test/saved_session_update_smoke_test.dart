import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meloop/backend/database/journal_database.dart';
import 'package:meloop/backend/database/journal_database_owner.dart';
import 'package:meloop/backend/journal/practice_screen_awake.dart';
import 'package:meloop/shared/journal/journal_runtime.dart';
import 'package:sqflite/sqflite.dart';

import '../test/support/saved_session_update_journey.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Android saved edit retry and durable reopen', (tester) async {
    final path =
        '${await getDatabasesPath()}/edit-test-${const UuidJournalIdentifiers().newId()}.db';
    try {
      await runSavedSessionUpdateJourney(
        tester,
        createOwner: () =>
            JournalDatabaseOwner(open: () => JournalDatabase.open(path: path)),
        createScreenAwake: AndroidPracticeScreenAwake.new,
      );
    } finally {
      await deleteDatabase(path);
    }
  });
}
