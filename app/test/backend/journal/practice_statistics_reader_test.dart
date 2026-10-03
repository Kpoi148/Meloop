import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/backend/database/journal_database.dart';
import 'package:meloop/backend/database/journal_database_owner.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../support/practice_statistics_journey.dart';

void main() {
  sqfliteFfiInit();
  test(
    'SQLite statistics recompute after Save/Edit/Delete without writing data',
    () async {
      final temp = await Directory.systemTemp.createTemp('meloop-statistics-');
      final owner = JournalDatabaseOwner(
        open: () => JournalDatabase.open(
          factory: databaseFactoryFfi,
          path: '${temp.path}/journal.db',
        ),
      );
      try {
        await runPracticeStatisticsJourney(owner);
      } finally {
        await owner.close();
        await temp.delete(recursive: true);
      }
    },
  );
}
