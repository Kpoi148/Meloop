import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/backend/database/journal_database.dart';
import 'package:meloop/backend/database/journal_database_owner.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../backend/journal/practice_timer_test.dart' show TestAwake;
import '../support/saved_session_update_journey.dart';

void main() {
  sqfliteFfiInit();
  testWidgets(
    'real edit retains input on failure, retries, refreshes and reopens',
    (tester) async {
      await tester.runAsync(() async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(411, 1000);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        final temp = await Directory.systemTemp.createTemp('meloop-edit-ui-');
        try {
          await runSavedSessionUpdateJourney(
            tester,
            createOwner: () => JournalDatabaseOwner(
              open: () => JournalDatabase.open(
                factory: databaseFactoryFfi,
                path: '${temp.path}/journal.db',
              ),
            ),
            createScreenAwake: TestAwake.new,
          );
        } finally {
          await temp.delete(recursive: true);
        }
      });
    },
  );
}
