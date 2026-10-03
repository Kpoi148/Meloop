import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/backend/database/journal_database.dart';
import 'package:meloop/backend/database/journal_database_owner.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/home_overview_journey.dart';

void main() {
  sqfliteFfiInit();
  testWidgets(
    'real journal: switch profiles, match Progress, edit and delete latest Home record',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(411, 1000);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.runAsync(
        () => runHomeOverviewJourney(
          tester,
          owner: JournalDatabaseOwner(
            open: () => JournalDatabase.open(
              factory: databaseFactoryFfi,
              path: inMemoryDatabasePath,
            ),
          ),
        ),
      );
    },
  );
}
