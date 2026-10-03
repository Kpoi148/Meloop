import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meloop/backend/database/journal_database.dart';
import 'package:meloop/backend/database/journal_database_owner.dart';
import 'package:meloop/backend/journal/practice_screen_awake.dart';
import 'package:meloop/shared/journal/journal_runtime.dart';
import 'package:sqflite/sqflite.dart';

import '../test/support/session_form_journey.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Android: Review draft recovery, exact seconds, Edit and retry', (
    tester,
  ) async {
    final path =
        '${await getDatabasesPath()}/session-form-test-${const UuidJournalIdentifiers().newId()}.db';
    var converted = false;
    try {
      await runSessionFormJourney(
        tester,
        createOwner: () =>
            JournalDatabaseOwner(open: () => JournalDatabase.open(path: path)),
        createScreenAwake: AndroidPracticeScreenAwake.new,
        failCompletionOnce: true,
        screenshot: (name) async {
          if (!converted) {
            await binding.convertFlutterSurfaceToImage();
            converted = true;
            await tester.pump();
          }
          await binding.takeScreenshot(name);
        },
      );
    } finally {
      await deleteDatabase(path);
    }
  });
}
