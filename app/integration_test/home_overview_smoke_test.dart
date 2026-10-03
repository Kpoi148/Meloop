import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meloop/backend/database/journal_database.dart';
import 'package:meloop/backend/database/journal_database_owner.dart';
import 'package:meloop/shared/journal/journal_runtime.dart';
import 'package:sqflite/sqflite.dart';

import '../test/support/home_overview_journey.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Android: Home and Progress follow the selected instrument and saved mutations',
    (tester) async {
      final path =
          '${await getDatabasesPath()}/home-test-${const UuidJournalIdentifiers().newId()}.db';
      var converted = false;
      try {
        await runHomeOverviewJourney(
          tester,
          owner: JournalDatabaseOwner(
            open: () => JournalDatabase.open(path: path),
          ),
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
    },
  );
}
