import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meloop/app/journal_providers.dart';
import 'package:meloop/app/profile_preview_app.dart';
import 'package:meloop/backend/database/journal_database.dart';
import 'package:meloop/backend/database/journal_database_owner.dart';
import 'package:meloop/backend/journal/practice_timer.dart';
import 'package:meloop/backend/journal/practice_screen_awake.dart';
import 'package:meloop/backend/journal/sqlite_practice_timer_store.dart';
import 'package:meloop/backend/journal/sqlite_instrument_profile_service.dart';
import 'package:meloop/backend/journal/sqlite_journal_readers.dart';
import 'package:meloop/frontend/profiles/profile_screens.dart';
import 'package:meloop/frontend/showcase/home_example.dart';
import 'package:meloop/frontend/showcase/timer_example.dart';
import 'package:meloop/shared/journal/journal_models.dart';
import 'package:meloop/shared/journal/journal_runtime.dart';
import 'package:meloop/shared/profiles/instrument_profile_service.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Android monotonic timer checkpoint/retry/background/process recovery',
    (tester) async {
      const phase = String.fromEnvironment('TIMER_TEST_PHASE');
      const file = String.fromEnvironment('TIMER_TEST_DB');
      const externalBackground = bool.fromEnvironment(
        'TIMER_TEST_EXTERNAL_BACKGROUND',
      );
      const externalTerminate = bool.fromEnvironment(
        'TIMER_TEST_EXTERNAL_TERMINATE',
      );
      if (file.isNotEmpty &&
          !RegExp(r'^timer-process-[0-9a-f-]+\.db$').hasMatch(file)) {
        throw ArgumentError('Only isolated timer test files are allowed.');
      }
      final path =
          '${await getDatabasesPath()}/${file.isEmpty ? 'timer-test-${const UuidJournalIdentifiers().newId()}.db' : file}';
      final owner = JournalDatabaseOwner(
        open: () => JournalDatabase.open(path: path),
      );
      final reader = SqliteJournalSessionReader(owner);
      final timer = PracticeTimer(
        store: SqlitePracticeTimerStore(owner: owner),
        clock: StopwatchMonotonicClock(),
        screenAwake: AndroidPracticeScreenAwake(),
      );
      Future<void> waitFor(bool Function() predicate) async {
        for (var i = 0; i < 150 && !predicate(); i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(predicate(), isTrue);
        await tester.pumpAndSettle();
      }

      Future<void> tap(Finder finder) async {
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        await tester.tap(finder);
        await tester.pumpAndSettle();
        await waitFor(() => timer.snapshot?.busy != true);
      }

      try {
        if (phase != 'reopen') {
          final profiles = SqliteInstrumentProfileService(
            owner: owner,
            initialLanguage: 'vi',
          );
          for (final (id, name, type) in [
            (
              '00000000-0000-4000-8000-000000000001',
              'Guitar Timer QA',
              InstrumentType.guitar,
            ),
            (
              '00000000-0000-4000-8000-000000000002',
              'Piano Timer QA',
              InstrumentType.piano,
            ),
          ]) {
            await profiles.create(
              requestId: id,
              name: name,
              instrumentType: type,
              customType: '',
            );
          }
        }
        final before = await reader.unfinished();
        await tester.pumpWidget(
          createJournalProfileApp(
            overrides: [
              journalDatabaseOwnerProvider.overrideWithValue(owner),
              journalPracticeTimerProvider.overrideWithValue(timer),
            ],
          ),
        );
        if (phase != 'reopen') {
          await waitFor(
            () => find.byType(ProfilePickerScreen).evaluate().isNotEmpty,
          );
          await tap(
            find.byKey(
              const Key('select-profile-00000000-0000-4000-8000-000000000001'),
            ),
          );
          await waitFor(() => find.byType(HomeExample).evaluate().isNotEmpty);
          await tap(find.text('Tạo buổi luyện'));
          await tester.enterText(
            find.byType(TextFormField),
            'Timer Android QA',
          );
          await tap(find.text('Bắt đầu luyện'));
          await waitFor(() => find.byType(TimerExample).evaluate().isNotEmpty);
          expect(timer.snapshot!.state, PracticeState.running);
          await Future<void>.delayed(const Duration(seconds: 6));
          await tester.pump();
          expect(
            (await reader.unfinished())!.accumulatedMilliseconds,
            greaterThanOrEqualTo(5000),
          );
          await tap(find.text('Tạm dừng'));
          final paused = timer.snapshot!.elapsedMilliseconds;
          await Future<void>.delayed(const Duration(seconds: 2));
          await tester.pump();
          expect(timer.snapshot!.elapsedMilliseconds, paused);
          expect(
            (await reader.unfinished())!.session.state,
            PracticeState.paused,
          );
          await tap(find.text('Tiếp tục'));
          await Future<void>.delayed(const Duration(milliseconds: 1200));
          await owner.read(
            (db) => db.execute(
              "CREATE TRIGGER injected_timer_android BEFORE UPDATE ON session_drafts BEGIN SELECT RAISE(ABORT,'injected'); END",
            ),
          );
          await tap(find.text('Tạm dừng'));
          expect(timer.snapshot!.failed, isTrue);
          expect(timer.snapshot!.state, PracticeState.paused);
          final retained = timer.snapshot!.elapsedMilliseconds;
          expect(
            (await reader.unfinished())!.accumulatedMilliseconds,
            lessThan(retained),
          );
          await owner.read(
            (db) => db.execute('DROP TRIGGER injected_timer_android'),
          );
          await tap(find.text('Thử lại'));
          expect(timer.snapshot!.failed, isFalse);
          expect(
            (await reader.unfinished())!.accumulatedMilliseconds,
            retained,
          );
          await tap(find.text('Tiếp tục'));
          if (externalBackground) {
            debugPrint('MELOOP_TIMER_QA_BACKGROUND_READY');
            await waitFor(
              () =>
                  timer.snapshot!.state == PracticeState.paused &&
                  !timer.snapshot!.busy,
            );
            final backgroundTime = timer.snapshot!.elapsedMilliseconds;
            await Future<void>.delayed(const Duration(seconds: 4));
            await tester.pump();
            expect(timer.snapshot!.state, PracticeState.paused);
            expect(timer.snapshot!.elapsedMilliseconds, backgroundTime);
            expect(
              (await reader.unfinished())!.session.state,
              PracticeState.paused,
            );
          } else {
            await tap(find.text('Tạm dừng'));
          }
          await tap(find.byTooltip('Quay lại'));
          await tap(find.byKey(const Key('choose-profile')));
          await waitFor(
            () => find.byType(ProfilePickerScreen).evaluate().isNotEmpty,
          );
          await tap(
            find.byKey(
              const Key('select-profile-00000000-0000-4000-8000-000000000002'),
            ),
          );
          await waitFor(
            () => find.text('Tiếp tục · Guitar Timer QA').evaluate().isNotEmpty,
          );
          await tap(find.text('Tiếp tục · Guitar Timer QA'));
          // Leave a Running checkpoint so recovery is tested independently of normal pause.
          await tap(find.text('Tiếp tục'));
          await Future<void>.delayed(const Duration(seconds: 6));
          await tester.pump();
          expect(
            (await reader.unfinished())!.session.state,
            PracticeState.running,
          );
        } else {
          await waitFor(
            () =>
                find.byType(TimerExample).evaluate().isNotEmpty &&
                !timer.snapshot!.busy,
          );
          expect(timer.snapshot!.state, PracticeState.paused);
          expect(
            timer.snapshot!.elapsedMilliseconds,
            before!.accumulatedMilliseconds,
          );
          expect(timer.snapshot!.sessionId, before.session.id);
          expect(
            (await reader.unfinished())!.session.state,
            PracticeState.paused,
          );
          await Future<void>.delayed(const Duration(seconds: 2));
          await tester.pump();
          expect(
            timer.snapshot!.elapsedMilliseconds,
            before.accumulatedMilliseconds,
          );
        }
        expect(
          timer.snapshot!.profileId,
          '00000000-0000-4000-8000-000000000001',
        );
        expect(find.text('Guitar Timer QA'), findsOneWidget);
        expect(
          await owner.read((db) => db.query('practice_sessions')),
          hasLength(1),
        );
        expect(
          await owner.read((db) => db.query('session_drafts')),
          hasLength(1),
        );
        expect(
          await reader.saved(profileId: timer.snapshot!.profileId),
          isEmpty,
        );
        if (phase == 'create') {
          if (externalTerminate) {
            final checkpoint = (await reader.unfinished())!;
            expect(checkpoint.session.state, PracticeState.running);
            expect(
              timer.snapshot!.elapsedMilliseconds -
                  checkpoint.accumulatedMilliseconds,
              lessThanOrEqualTo(5000),
            );
            debugPrint(
              'MELOOP_TIMER_QA_KILL_READY ${checkpoint.session.id} ${checkpoint.accumulatedMilliseconds}',
            );
            await Future<void>.delayed(const Duration(seconds: 30));
            fail('External force-stop did not occur.');
          }
          // Model the absence of a final write on abnormal termination. The DB is
          // test-only; suppress teardown's pause and retain the last periodic checkpoint.
          await owner.read(
            (db) => db.execute(
              "CREATE TRIGGER simulate_termination BEFORE UPDATE ON session_drafts BEGIN SELECT RAISE(ABORT,'injected'); END",
            ),
          );
          await tester.pumpWidget(const SizedBox.shrink());
          await timer.close();
          await owner.read(
            (db) => db.execute('DROP TRIGGER simulate_termination'),
          );
        }
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await timer.close();
        await owner.close();
        if (phase != 'create') await deleteDatabase(path);
      }
    },
  );
}
