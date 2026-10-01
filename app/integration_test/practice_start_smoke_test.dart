import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meloop/app/journal_providers.dart';
import 'package:meloop/app/profile_preview_app.dart';
import 'package:meloop/backend/database/journal_database.dart';
import 'package:meloop/backend/database/journal_database_owner.dart';
import 'package:meloop/backend/journal/sqlite_instrument_profile_service.dart';
import 'package:meloop/backend/journal/sqlite_journal_readers.dart';
import 'package:meloop/frontend/showcase/home_example.dart';
import 'package:meloop/frontend/application/startup_controller.dart';
import 'package:meloop/frontend/application/practice_timer_service.dart';
import 'package:meloop/frontend/showcase/setup_example.dart';
import 'package:meloop/frontend/showcase/timer_example.dart';
import 'package:meloop/shared/journal/journal_runtime.dart';
import 'package:meloop/shared/profiles/instrument_profile_service.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Android Start rollback/retry and process recovery keep one real draft',
    (tester) async {
      const phase = String.fromEnvironment('START_TEST_PHASE');
      const file = String.fromEnvironment('START_TEST_DB');
      if (file.isNotEmpty &&
          !RegExp(r'^start-process-[0-9a-f-]+\.db$').hasMatch(file)) {
        throw ArgumentError('Only isolated Start test files are allowed.');
      }
      final path =
          '${await getDatabasesPath()}/${file.isEmpty ? 'start-test-${const UuidJournalIdentifiers().newId()}.db' : file}';
      final owner = JournalDatabaseOwner(
        open: () => JournalDatabase.open(path: path),
      );
      final reader = SqliteJournalSessionReader(owner);
      Future<void> waitFor(Finder finder) async {
        for (
          var attempt = 0;
          attempt < 100 && finder.evaluate().isEmpty;
          attempt++
        ) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.pumpAndSettle();
        expect(finder, findsOneWidget);
      }

      Future<void> tap(Finder finder) async {
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      try {
        if (phase != 'reopen') {
          await SqliteInstrumentProfileService(
            owner: owner,
            initialLanguage: 'vi',
          ).create(
            requestId: '00000000-0000-4000-8000-000000000001',
            name: 'Guitar Start QA',
            instrumentType: InstrumentType.guitar,
            customType: '',
          );
        }
        final before = await reader.unfinished();
        await tester.pumpWidget(
          createJournalProfileApp(
            overrides: [
              journalDatabaseOwnerProvider.overrideWithValue(owner),
              // B04 is tested independently; B05 has real timer integration QA.
              practiceTimerServiceProvider.overrideWithValue(null),
            ],
          ),
        );
        if (phase != 'reopen') {
          await waitFor(find.byType(HomeExample));
          await tap(find.text('Tạo buổi luyện'));
          await waitFor(find.byType(SetupExample));
          expect(await reader.unfinished(), isNull);
          await tap(find.byTooltip('Quay lại'));
          expect(await reader.unfinished(), isNull);
          await tap(find.text('Tạo buổi luyện'));
          await tester.enterText(
            find.byType(TextFormField),
            'Start persisted QA',
          );
          await owner.read(
            (db) => db.execute(
              "CREATE TRIGGER injected_start BEFORE INSERT ON session_drafts BEGIN SELECT RAISE(ABORT,'injected'); END",
            ),
          );
          await tap(find.text('Bắt đầu luyện'));
          await waitFor(
            find.text(
              'Chưa thể bắt đầu buổi luyện. Tiêu đề vẫn được giữ; hãy thử lại.',
            ),
          );
          expect(find.byType(SetupExample), findsOneWidget);
          expect(find.text('Start persisted QA'), findsOneWidget);
          expect(await reader.unfinished(), isNull);
          await owner.read((db) => db.execute('DROP TRIGGER injected_start'));
          await tap(find.text('Bắt đầu luyện'));
        }
        await waitFor(find.byType(TimerExample));
        expect(find.text('Start persisted QA'), findsOneWidget);
        expect(find.text('Guitar Start QA'), findsOneWidget);
        final draft = (await reader.unfinished())!;
        final shell = ProviderScope.containerOf(
          tester.element(find.byType(TimerExample)),
        ).read(meloopShellControllerProvider);
        expect(shell.draft!.sessionId, draft.session.id);
        expect(JournalId.isValid(draft.session.id), isTrue);
        expect(draft.session.profileId, '00000000-0000-4000-8000-000000000001');
        expect(draft.accumulatedMilliseconds, 0);
        if (before != null) expect(draft.session.id, before.session.id);
        await tap(find.byTooltip('Quay lại'));
        await tap(find.text('Tiếp tục · Guitar Start QA'));
        await waitFor(find.byType(TimerExample));
        expect((await reader.unfinished())!.session.id, draft.session.id);
        expect(
          await owner.read((db) => db.query('practice_sessions')),
          hasLength(1),
        );
        expect(
          await owner.read((db) => db.query('session_drafts')),
          hasLength(1),
        );
        expect(await reader.saved(profileId: draft.session.profileId), isEmpty);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await owner.close();
        if (phase != 'create') await deleteDatabase(path);
      }
    },
  );
}
