import 'package:flutter/material.dart';

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/app/meloop_app.dart';
import 'package:meloop/app/journal_practice_lifecycle.dart';
import 'package:meloop/backend/journal/practice_timer.dart';
import 'package:meloop/frontend/application/app_settings_controller.dart';
import 'package:meloop/frontend/application/practice_timer_service.dart';
import 'package:meloop/frontend/application/startup_controller.dart';
import 'package:meloop/frontend/components/meloop_ui.dart';
import 'package:meloop/frontend/showcase/home_example.dart';
import 'package:meloop/frontend/showcase/meloop_ui_showcase.dart';
import 'package:meloop/frontend/showcase/timer_example.dart';
import 'package:meloop/frontend/showcase/session_form_example.dart';
import 'package:meloop/shared/journal/journal_failure.dart';
import 'package:meloop/shared/journal/journal_models.dart';
import 'package:meloop/shared/journal/practice_date.dart';
import 'package:meloop/shared/journal/practice_timer_service.dart';
import 'package:meloop/shared/settings/app_settings_store.dart';

import '../backend/journal/profile_create_test.dart' show id;
import '../backend/journal/practice_timer_test.dart'
    show TestMonotonicClock, TestAwake;

class UiTimerStore implements PracticeTimerStore {
  bool fail = false;
  String? observedSessionId, observedProfileId;
  int elapsed = 0;
  PracticeState phase = PracticeState.running;
  final now = DateTime.utc(2026, 10, 1);
  PracticeDraft get draft => PracticeDraft(
    session: PracticeSession(
      id: id(10),
      profileId: id(1),
      state: phase,
      title: 'Timer UI QA',
      practiceDate: PracticeDate.parse('2026-10-01'),
      startOffsetMinutes: 420,
      createdAt: now,
      updatedAt: now,
    ),
    accumulatedMilliseconds: elapsed,
    checkpointAt: now,
    updatedAt: now,
  );
  @override
  Future<PracticeDraft> checkpoint({
    required String sessionId,
    required String profileId,
    required int accumulatedMilliseconds,
    required PracticeState state,
  }) async {
    if (fail) throw const JournalFailure(JournalFailureCode.storage);
    observedSessionId = sessionId;
    observedProfileId = profileId;
    elapsed = accumulatedMilliseconds;
    phase = state;
    return draft;
  }
}

void main() {
  setUpAll(() async {
    final fonts = FontLoader(TempoType.fontFamily);
    for (final weight in [400, 500, 600, 700]) {
      fonts.addFont(rootBundle.load('assets/fonts/be-vietnam-pro-$weight.ttf'));
    }
    await fonts.load();
  });
  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  for (final size in [(390.0, 1.0), (320.0, 2.0)]) {
    testWidgets(
      'timer UI error/retry, Back and lifecycle at ${size.$1}px ${size.$2}x text',
      (tester) async {
        tester.view.physicalSize = Size(size.$1, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final store = UiTimerStore();
        final mono = TestMonotonicClock();
        final awake = TestAwake();
        final timer = PracticeTimer(
          store: store,
          clock: mono,
          screenAwake: awake,
          schedulePulses: false,
        );
        final boundaryKey = GlobalKey();
        await timer.open(store.draft);
        try {
          await tester.pumpWidget(
            MeloopApp(
              overrides: [
                appSettingsStoreProvider.overrideWithValue(
                  InMemoryAppSettingsStore(languageCode: 'vi'),
                ),
                practiceTimerServiceProvider.overrideWithValue(timer),
                startupSnapshotProvider.overrideWithValue(
                  StartupSnapshot(
                    profiles: [
                      PreviewInstrumentProfile(
                        id: id(1),
                        name: 'Guitar UI QA',
                        instrument: MeloopInstrument.guitar,
                      ),
                    ],
                    selectedProfileId: id(1),
                    draft: PreviewPracticeDraft(
                      sessionId: id(10),
                      profileId: id(1),
                      title: 'Timer UI QA',
                      instrumentName: 'Guitar UI QA',
                    ),
                  ),
                ),
              ],
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(size.$2)),
                child: child!,
              ),
              home: RepaintBoundary(
                key: boundaryKey,
                child: const JournalPracticeLifecycle(
                  child: MeloopUiShowcase(
                    developmentTools: false,
                    journalRecoveryReadOnly: false,
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            MediaQuery.textScalerOf(tester.element(find.byType(TimerExample)))
                .scale(10),
            10 * size.$2,
          );
          await tap(tester, find.text('Tiếp tục'));
          mono.advance(6700);
          await timer.pulse();
          await tester.pumpAndSettle();
          expect(find.text('00:06'), findsOneWidget);
          expect(awake.enabled.last, true);
          await tap(tester, find.text('Tạm dừng'));
          expect(store.elapsed, 6700);
          mono.advance(50000);
          await tester.pumpAndSettle();
          expect(find.text('00:06'), findsOneWidget);
          await tap(tester, find.text('Tiếp tục'));
          store.fail = true;
          mono.advance(5400);
          try {
            await timer.pulse();
          } catch (_) {}
          await tester.pumpAndSettle();
          expect(find.text('00:12'), findsOneWidget);
          expect(
            find.text(
              'Buổi luyện đã tạm dừng do lỗi. Thời gian mới chưa được xác nhận lưu; hãy thử lại.',
            ),
            findsOneWidget,
          );
          await tester.runAsync(() async {
            final boundary =
                boundaryKey.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final rendered = await boundary.toImage();
            final bytes = await rendered.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final directory = Directory('build/ui-review')
              ..createSync(recursive: true);
            File(
              '${directory.path}/timer-error-${size.$1.toInt()}-${size.$2.toInt()}x.png',
            ).writeAsBytesSync(bytes!.buffer.asUint8List());
            rendered.dispose();
          });
          expect(
            tester
                .widget<MeloopButton>(
                  find.widgetWithText(MeloopButton, 'Tiếp tục'),
                )
                .onPressed,
            isNull,
          );
          store.fail = false;
          await tap(tester, find.text('Thử lại'));
          await tester.pump();
          await tester.pumpAndSettle();
          expect(store.elapsed, 12100);
          expect(timer.snapshot!.failed, false);
          expect(
            tester
                .widget<MeloopButton>(
                  find.widgetWithText(MeloopButton, 'Tiếp tục'),
                )
                .onPressed,
            isNotNull,
          );
          await tap(tester, find.text('Tiếp tục'));
          expect(timer.snapshot!.state, PracticeState.running);
          if (timer.snapshot!.busy) {
            await timer.changes.firstWhere((snapshot) => !snapshot.busy);
          }
          mono.advance(1200);
          expect(
            timer.snapshot!.elapsedMilliseconds,
            13300,
            reason: 'Resumed interval advances before background',
          );
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.inactive,
          );
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.paused,
          );
          await tester.pumpAndSettle();
          expect(timer.snapshot!.state, PracticeState.paused);
          expect(
            timer.snapshot!.elapsedMilliseconds,
            13300,
            reason: 'Background freezes elapsed immediately',
          );
          expect(timer.snapshot!.failed, false);
          if (timer.snapshot!.busy) {
            await timer.changes.firstWhere((snapshot) => !snapshot.busy);
          }
          expect(awake.enabled.last, false);
          expect(store.elapsed, 13300);
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.resumed,
          );
          mono.advance(30000);
          await tester.pumpAndSettle();
          expect(find.text('00:13'), findsOneWidget);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(find.byType(HomeExample), findsOneWidget);
          await tap(tester, find.text('Tiếp tục · Guitar UI QA'));
          expect(find.text('00:13'), findsOneWidget);
          expect(
            tester
                .widget<MeloopButton>(
                  find.widgetWithText(MeloopButton, 'Kết thúc'),
                )
                .onPressed,
            isNotNull,
          );
          await tap(tester, find.text('Tiếp tục'));
          if (timer.snapshot!.busy) {
            await timer.changes.firstWhere((snapshot) => !snapshot.busy);
          }
          mono.advance(2000);
          await tap(tester, find.text('Kết thúc'));
          final form = tester.widget<SessionFormExample>(
            find.byType(SessionFormExample),
          );
          expect(form.sessionId, id(10));
          expect(form.initialDurationSeconds, 15);
          expect(timer.snapshot!.state, PracticeState.paused);
          expect(store.elapsed, 15300);
          mono.advance(30000);
          expect(timer.snapshot!.elapsedMilliseconds, 15300);
          expect(timer.snapshot!.sessionId, id(10));
          expect(store.observedSessionId, id(10));
          expect(store.observedProfileId, id(1));
          expect(tester.takeException(), isNull);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
          await timer.close();
        }
      },
    );
  }
}
