import 'dart:io';
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meloop/frontend/application/startup_controller.dart';
import 'package:meloop/frontend/application/practice_review_provider.dart';
import 'package:meloop/app/journal_practice_adapter.dart';
import 'package:meloop/app/meloop_app.dart';
import 'package:meloop/app/journal_providers.dart';
import 'package:meloop/app/profile_preview_app.dart';
import 'package:meloop/backend/database/journal_database.dart';
import 'package:meloop/backend/database/journal_database_owner.dart';
import 'package:meloop/backend/journal/practice_timer.dart';
import 'package:meloop/backend/journal/sqlite_instrument_profile_service.dart';
import 'package:meloop/backend/journal/sqlite_journal_readers.dart';
import 'package:meloop/backend/journal/sqlite_practice_timer_store.dart';
import 'package:meloop/frontend/components/meloop_ui.dart';
import 'package:meloop/frontend/practice_sessions/practice_session_card.dart';
import 'package:meloop/frontend/practice_sessions/practice_session_detail_page.dart';
import 'package:meloop/frontend/practice_sessions/practice_sessions_tab.dart';
import 'package:meloop/frontend/showcase/home_example.dart';
import 'package:meloop/frontend/showcase/session_form_example.dart';
import 'package:meloop/frontend/showcase/timer_example.dart';
import 'package:meloop/frontend/profiles/profile_screens.dart';
import 'package:meloop/shared/profiles/instrument_profile_service.dart';
import 'package:meloop/shared/journal/journal_models.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../backend/journal/practice_timer_test.dart'
    show TestAwake, TestMonotonicClock;

void main() {
  sqfliteFfiInit();
  for (final (browseDifferentProfile, disposeDuringSave) in [
    (false, false),
    (true, false),
    (false, true),
  ]) {
    testWidgets(
      'real journal Save refreshes history/Home (other profile: $browseDifferentProfile, disposed: $disposeDuringSave)',
      (tester) async {
        await tester.runAsync(() async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(411, 1100);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetPhysicalSize);
          const profileId = '00000000-0000-4000-8000-000000000001';
          const otherProfileId = '00000000-0000-4000-8000-000000000002';
          const title = 'Buổi luyện QA';
          final profileName = browseDifferentProfile
              ? 'Guitar của tôi'
              : 'Sáo của tôi';
          final instrument = browseDifferentProfile
              ? InstrumentType.guitar
              : InstrumentType.flute;
          final boundary = GlobalKey();
          final fonts = FontLoader(TempoType.fontFamily);
          for (final weight in [400, 500, 600, 700]) {
            fonts.addFont(
              rootBundle.load('assets/fonts/be-vietnam-pro-$weight.ttf'),
            );
          }
          await fonts.load();
          late Directory temp;
          late JournalDatabaseOwner owner;
          late PracticeTimer timer;
          final mono = TestMonotonicClock();
          final committed = Completer<void>();
          final releaseSave = Completer<void>();
          temp = await Directory.systemTemp.createTemp('meloop-save-flow-');
          owner = JournalDatabaseOwner(
            open: () => JournalDatabase.open(
              factory: databaseFactoryFfi,
              path: '${temp.path}/journal.db',
            ),
          );
          final profiles = SqliteInstrumentProfileService(
            owner: owner,
            initialLanguage: 'vi',
          );
          await profiles.create(
            requestId: profileId,
            name: profileName,
            instrumentType: instrument,
            customType: '',
          );
          if (browseDifferentProfile) {
            await profiles.create(
              requestId: otherProfileId,
              name: 'Piano QA',
              instrumentType: InstrumentType.piano,
              customType: '',
            );
          }
          timer = PracticeTimer(
            store: SqlitePracticeTimerStore(owner: owner),
            clock: mono,
            screenAwake: TestAwake(),
            schedulePulses: false,
          );
          Future<void> waitFor(Finder finder) async {
            for (var i = 0; i < 100; i++) {
              await Future<void>.delayed(const Duration(milliseconds: 20));
              await tester.pump(const Duration(milliseconds: 50));
              // The page can exist before its SQLite read finishes. Allow real
              // I/O to complete before pumpAndSettle advances fake frame time.
              if (finder.evaluate().isNotEmpty &&
                  find.byType(CircularProgressIndicator).evaluate().isEmpty &&
                  timer.snapshot?.busy != true) {
                break;
              }
            }
            await tester.pumpAndSettle();
            expect(finder, findsOneWidget);
          }

          Future<void> tap(Finder finder) async {
            if (timer.snapshot?.busy == true) {
              await timer.changes.firstWhere((snapshot) => !snapshot.busy);
            }
            await tester.pump();
            await tester.ensureVisible(finder);
            await tester.tap(finder);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 400));
          }

          Finder tab(String text) => find.descendant(
            of: find.byType(MeloopBottomNavigation),
            matching: find.text(text),
          );
          Future<void> mount() async {
            final app = createJournalProfileApp(
              overrides: [
                journalDatabaseOwnerProvider.overrideWithValue(owner),
                journalPracticeTimerProvider.overrideWithValue(timer),
              ],
            );
            await tester.pumpWidget(
              MeloopApp(
                overrides: app.overrides,
                home: disposeDuringSave
                    ? ProviderScope(
                        overrides: [
                          if (disposeDuringSave)
                            practiceReviewSaveProvider.overrideWith((ref) {
                              final review = ref.read(
                                journalReviewServiceProvider,
                              );
                              return (id, values) async {
                                final saved = presentPracticeSession(
                                  await review.save(
                                    id,
                                    journalReviewValues(values),
                                  ),
                                );
                                committed.complete();
                                await releaseSave.future;
                                return saved;
                              };
                            }),
                        ],
                        child: app.home,
                      )
                    : app.home,
                builder: (_, child) =>
                    RepaintBoundary(key: boundary, child: child!),
              ),
            );
            if (browseDifferentProfile) {
              await waitFor(find.byType(ProfilePickerScreen));
              await tap(find.byKey(const Key('select-profile-$profileId')));
            }
            await waitFor(find.byType(HomeExample));
          }

          try {
            await mount();
            await tap(tab('Buổi luyện'));
            await waitFor(find.text('Chưa có buổi luyện'));
            // Saving a new session must show it even when an old search was active.
            await tester.enterText(find.byType(TextField), 'Từ khóa trước đó');
            await tester.pump();
            await tap(find.byKey(const Key('practice-create')));
            await waitFor(find.byType(TextFormField));
            await tester.enterText(find.byType(TextFormField), title);
            await tap(find.text('Bắt đầu luyện'));
            await waitFor(find.byType(TimerExample));
            if (browseDifferentProfile) {
              await tap(find.byTooltip('Quay lại'));
              await waitFor(find.byType(PracticeSessionsTab));
              await tap(
                find.descendant(
                  of: find.byType(PracticeSessionsTab),
                  matching: find.text('Guitar'),
                ),
              );
              await waitFor(find.byType(ProfilePickerScreen));
              await tap(
                find.byKey(const Key('select-profile-$otherProfileId')),
              );
              await waitFor(find.byType(HomeExample));
              expect(find.text('Tiếp tục · $profileName'), findsNothing);
              await tap(find.byKey(const Key('choose-profile')));
              await waitFor(find.byType(ProfilePickerScreen));
              await tap(find.byKey(const Key('select-profile-$profileId')));
              await waitFor(find.byType(HomeExample));
              await tap(find.text('Tiếp tục · $profileName'));
              await waitFor(find.byType(TimerExample));
            }
            if (timer.snapshot!.state == PracticeState.paused) {
              await tap(find.text('Tiếp tục'));
            }
            if (timer.snapshot!.busy) {
              await timer.changes.firstWhere((snapshot) => !snapshot.busy);
            }
            mono.advance(5000);
            await tap(find.text('Kết thúc'));
            await waitFor(find.byType(SessionFormExample));
            await tap(find.widgetWithText(MeloopButton, 'Lưu buổi luyện'));
            if (disposeDuringSave) {
              await committed.future;
              final context = tester.element(find.byType(SessionFormExample));
              Navigator.of(context).removeRoute(ModalRoute.of(context)!);
              await tester.pump();
              expect(find.byType(SessionFormExample), findsNothing);
              releaseSave.complete();
              await waitFor(find.byType(HomeExample));
              final shell = ProviderScope.containerOf(
                tester.element(find.byType(HomeExample)),
              ).read(meloopShellControllerProvider);
              expect(shell.profiles.single.savedSessionCount, 1);
              expect(shell.draft, isNull);
              expect(timer.snapshot, isNull);
              expect(
                await SqliteJournalSessionReader(owner)
                    .saved(profileId: profileId),
                hasLength(1),
              );
              expect(find.byType(PracticeSessionDetailPage), findsNothing);
              expect(tester.takeException(), isNull);
              return;
            }
            await waitFor(find.byType(PracticeSessionDetailPage));
            expect(find.text(title), findsOneWidget);
            expect(find.text('$profileName · 5 giây'), findsOneWidget);
            expect(find.text('— / 5', findRichText: true), findsNWidgets(2));
            expect(find.text('Chưa có ghi chú.'), findsNWidgets(2));
            expect(timer.snapshot, isNull);
            final shell = ProviderScope.containerOf(
              tester.element(find.byType(PracticeSessionDetailPage)),
            ).read(meloopShellControllerProvider);
            expect(
              shell.profiles
                  .firstWhere((p) => p.id == profileId)
                  .savedSessionCount,
              1,
            );
            expect(shell.draft, isNull);
            if (browseDifferentProfile) {
              expect(
                shell.profiles
                    .firstWhere((p) => p.id == otherProfileId)
                    .savedSessionCount,
                0,
              );
            }
            for (final asset in [
              'illustrations.png',
              'instruments-v2.png',
              'tools-v2.png',
            ]) {
              await precacheImage(
                AssetImage('assets/illustrations/$asset'),
                boundary.currentContext!,
              );
            }
            await tester.pumpAndSettle();
            final render =
                boundary.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final snapshot = await render.toImage();
            final bytes = await snapshot.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final output = File(
              'build/ui-review/saved-detail-${instrument.name}.png',
            );
            await output.parent.create(recursive: true);
            await output.writeAsBytes(bytes!.buffer.asUint8List());
            snapshot.dispose();
            expect(
              await SqliteJournalSessionReader(owner)
                  .saved(profileId: profileId),
              hasLength(1),
            );
            await tap(find.byTooltip('Trang chủ'));
            await waitFor(find.byType(HomeExample));
            await tap(tab('Buổi luyện'));
            await waitFor(find.widgetWithText(PracticeSessionCard, title));
            await tap(find.widgetWithText(PracticeSessionCard, title));
            await waitFor(find.byType(PracticeSessionDetailPage));
            await tap(find.byTooltip('Quay lại'));
            await waitFor(find.widgetWithText(PracticeSessionCard, title));
            expect(find.text('Buổi luyện chưa hoàn tất'), findsNothing);
            await tap(tab('Trang chủ'));
            await waitFor(find.byType(HomeExample));
            await tap(tab('Buổi luyện'));
            await waitFor(find.widgetWithText(PracticeSessionCard, title));
            await tap(find.widgetWithText(PracticeSessionCard, title));
            await waitFor(find.byType(PracticeSessionDetailPage));
            await tap(find.byTooltip('Trang chủ'));
            await waitFor(find.byType(HomeExample));
            // Remount the real app against the same storage (cold entry).
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pumpAndSettle();
            await timer.close();
            await owner.close();
            owner = JournalDatabaseOwner(
              open: () => JournalDatabase.open(
                factory: databaseFactoryFfi,
                path: '${temp.path}/journal.db',
              ),
            );
            timer = PracticeTimer(
              store: SqlitePracticeTimerStore(owner: owner),
              clock: TestMonotonicClock(),
              screenAwake: TestAwake(),
              schedulePulses: false,
            );
            await mount();
            await tap(tab('Buổi luyện'));
            await waitFor(find.widgetWithText(PracticeSessionCard, title));
            expect(find.byType(PracticeSessionsTab), findsOneWidget);
            expect(tester.takeException(), isNull);
          } finally {
            await tester.pumpWidget(const SizedBox.shrink());
            await timer.close();
            await owner.close();
            await temp.delete(recursive: true);
          }
        });
      },
    );
  }
}
