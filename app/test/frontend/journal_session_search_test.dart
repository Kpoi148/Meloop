import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/backend/database/journal_database.dart';
import 'package:meloop/backend/database/journal_database_owner.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/session_search_journey.dart';
import '../support/session_search_acceptance_journey.dart';

void main() {
  sqfliteFfiInit();
  testWidgets(
    'journal filtered list refreshes Save/Edit/Delete and resets on owner change',
    (tester) async {
      await tester.runAsync(() async {
        final temp = await Directory.systemTemp.createTemp(
          'meloop-search-mutations-',
        );
        final owner = JournalDatabaseOwner(
          open: () => JournalDatabase.open(
            factory: databaseFactoryFfi,
            path: '${temp.path}/journal.db',
          ),
        );
        try {
          await runSessionSearchAcceptanceJourney(tester, owner);
        } finally {
          await owner.close();
          await temp.delete(recursive: true);
        }
      });
    },
  );
  testWidgets('journal search matches SQLite and the existing search UI', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final temp = await Directory.systemTemp.createTemp('meloop-search-');
      final owner = JournalDatabaseOwner(
        open: () => JournalDatabase.open(
          factory: databaseFactoryFfi,
          path: '${temp.path}/journal.db',
        ),
      );
      try {
        await runSessionSearchJourney(tester, owner);
      } finally {
        await owner.close();
        await temp.delete(recursive: true);
      }
    });
  });
}
