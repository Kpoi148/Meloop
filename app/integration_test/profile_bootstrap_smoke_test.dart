import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meloop/app/journal_providers.dart';
import 'package:meloop/app/profile_preview_app.dart';
import 'package:meloop/backend/database/journal_database.dart';
import 'package:meloop/backend/database/journal_database_owner.dart';
import 'package:meloop/backend/journal/sqlite_instrument_profile_service.dart';
import 'package:meloop/backend/journal/sqlite_journal_bootstrap.dart';
import 'package:meloop/frontend/profiles/profile_screens.dart';
import 'package:meloop/frontend/showcase/timer_example.dart';
import 'package:meloop/shared/journal/journal_runtime.dart';
import 'package:meloop/shared/profiles/instrument_profile_service.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Android bootstrap preserves selection and draft ownership across processes',
    (tester) async {
      const phase = String.fromEnvironment('BOOTSTRAP_TEST_PHASE');
      const file = String.fromEnvironment('BOOTSTRAP_TEST_DB');
      if (file.isNotEmpty &&
          !RegExp(r'^bootstrap-process-[0-9a-f-]+\.db$').hasMatch(file)) {
        throw ArgumentError(
          'Only isolated bootstrap process files are allowed.',
        );
      }
      final path =
          '${await getDatabasesPath()}/${file.isEmpty ? 'bootstrap-test-${const UuidJournalIdentifiers().newId()}.db' : file}';
      final owner = JournalDatabaseOwner(
        open: () => JournalDatabase.open(path: path),
      );
      final service = SqliteInstrumentProfileService(
        owner: owner,
        initialLanguage: 'vi',
      );
      Future<void> tap(Finder finder) async {
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      try {
        if (phase != 'reopen') {
          for (final (id, name, type) in [
            (
              '00000000-0000-4000-8000-000000000001',
              'Guitar QA',
              InstrumentType.guitar,
            ),
            (
              '00000000-0000-4000-8000-000000000002',
              'Piano QA',
              InstrumentType.piano,
            ),
          ]) {
            await service.create(
              requestId: id,
              name: name,
              instrumentType: type,
              customType: '',
            );
          }
          final now = DateTime.now().toUtc().millisecondsSinceEpoch;
          await owner.transaction((db) async {
            await db.insert('practice_sessions', {
              'id': '00000000-0000-4000-8000-000000000010',
              'profile_id': '00000000-0000-4000-8000-000000000001',
              'state': 'running',
              'title': 'Checkpoint QA',
              'practice_date': '2026-10-01',
              'start_offset_minutes': 420,
              'created_at': now,
              'updated_at': now,
            });
            await db.update(
              'session_drafts',
              {'accumulated_ms': 754000},
              where: 'session_id=?',
              whereArgs: ['00000000-0000-4000-8000-000000000010'],
            );
          });
        }
        await tester.pumpWidget(
          createJournalProfileApp(
            overrides: [journalDatabaseOwnerProvider.overrideWithValue(owner)],
          ),
        );
        for (
          var attempt = 0;
          attempt < 100 && find.byType(TimerExample).evaluate().isEmpty;
          attempt++
        ) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.pumpAndSettle();
        expect(find.byType(TimerExample), findsOneWidget);
        expect(find.text('12:34'), findsOneWidget);
        expect(find.text('Guitar QA'), findsOneWidget);
        await tap(find.byTooltip('Quay lại'));
        await tap(find.byKey(const Key('choose-profile')));
        expect(find.byType(ProfilePickerScreen), findsOneWidget);
        await tap(
          find.byKey(
            const Key('select-profile-00000000-0000-4000-8000-000000000002'),
          ),
        );
        for (
          var attempt = 0;
          attempt < 100 && find.text('Tiếp tục · Guitar QA').evaluate().isEmpty;
          attempt++
        ) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.pumpAndSettle();
        expect(find.text('Tiếp tục · Guitar QA'), findsOneWidget);
        final snapshot = await SqliteJournalBootstrap(
          owner: owner,
          clock: const DeviceJournalClock(),
          initialLanguage: 'vi',
        ).read();
        expect(
          snapshot.directory.selectedProfileId,
          '00000000-0000-4000-8000-000000000002',
        );
        expect(
          snapshot.draft!.session.profileId,
          '00000000-0000-4000-8000-000000000001',
        );
        expect(snapshot.draft!.accumulatedMilliseconds, 754000);
        expect(
          await owner.read((db) => db.query('practice_sessions')),
          hasLength(1),
        );
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await owner.close();
        if (phase != 'create') await deleteDatabase(path);
      }
    },
  );
}
