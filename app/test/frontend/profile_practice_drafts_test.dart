import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/backend/database/journal_database.dart';
import 'package:meloop/backend/database/journal_database_owner.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../backend/journal/practice_timer_test.dart' show TestAwake;
import '../support/profile_draft_journey.dart';

void main() {
  sqfliteFfiInit();
  testWidgets(
    'Guitar and Flute keep independent drafts, recovery, timers and saved histories',
    (tester) async {
      await tester.runAsync(() async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(411, 1100);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        final temp = await Directory.systemTemp.createTemp(
          'meloop-profile-drafts-',
        );
        try {
          await runProfileDraftJourney(
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
