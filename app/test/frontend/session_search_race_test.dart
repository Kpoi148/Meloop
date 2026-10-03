import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/app/meloop_app.dart';
import 'package:meloop/frontend/application/startup_controller.dart';
import 'package:meloop/frontend/components/meloop_ui.dart';
import 'package:meloop/frontend/practice_sessions/practice_session.dart';
import 'package:meloop/frontend/practice_sessions/practice_session_card.dart';
import 'package:meloop/frontend/practice_sessions/practice_sessions_controller.dart';
import 'package:meloop/frontend/showcase/meloop_ui_showcase.dart';

void main() {
  const a = PreviewInstrumentProfile(
    id: 'race-a',
    name: 'Guitar race',
    instrument: MeloopInstrument.guitar,
  );
  const b = PreviewInstrumentProfile(
    id: 'race-b',
    name: 'Piano race',
    instrument: MeloopInstrument.piano,
  );
  final today = DateTime(2026, 10, 3);
  PracticeSession record(String id, String owner, String title) =>
      PracticeSession(
        id: id,
        profileId: owner,
        title: title,
        date: today,
        duration: const Duration(minutes: 1),
      );
  final old = record('old', a.id, 'Alpha old owner');
  final current = record('current', b.id, 'Beta current owner');
  Finder tab(String label) => find.descendant(
    of: find.byType(MeloopBottomNavigation),
    matching: find.text(label),
  );
  for (final lateError in [false, true]) {
    testWidgets(
      'late ${lateError ? 'error' : 'data'} cannot overwrite current owner; retry keeps query/filter',
      (tester) async {
        final previous = Completer<List<PracticeSession>>();
        final pending = Completer<List<PracticeSession>>();
        var reads = 0;
        var oldReads = 0;
        await tester.pumpWidget(
          MeloopApp(
            overrides: [
              startupSnapshotProvider.overrideWithValue(
                StartupSnapshot(
                  profiles: [a, b],
                  selectedProfileId: a.id,
                  hasChosenProfile: true,
                ),
              ),
              practiceSessionsClockProvider.overrideWithValue(() => today),
              practiceSessionsLoaderProvider.overrideWithValue((profile) {
                if (profile.id == a.id) {
                  oldReads++;
                  return previous.future;
                }
                return ++reads == 1
                    ? pending.future
                    : Future.value([old, current]);
              }),
            ],
            home: const MeloopUiShowcase(developmentTools: false),
          ),
        );
        await tester.pump();
        for (var i = 0; i < 10 && oldReads == 0; i++) {
          await tester.pump();
        }
        expect(oldReads, greaterThan(0));
        final scope = ProviderScope.containerOf(
          tester.element(find.byType(MeloopUiShowcase)),
        );
        scope.read(meloopShellControllerProvider.notifier).selectProfile(b.id);
        await tester.pump();
        await tester.tap(tab('Buổi luyện'));
        await tester.pump();
        expect(find.text('Đang tải buổi luyện…'), findsOneWidget);
        await tester.ensureVisible(find.byType(TextField));
        await tester.enterText(find.byType(TextField), 'beta');
        scope
            .read(practiceSessionsControllerProvider.notifier)
            .applyFilters(
              b.id,
              const PracticeSessionFilters(
                period: PracticePeriod.week,
                order: PracticeOrder.oldest,
              ),
            );
        await tester.pump();
        if (lateError) {
          previous.completeError(StateError('test_old_owner_read_error'));
        } else {
          previous.complete([old]);
        }
        await tester.pump();
        expect(find.text('Chưa thể tải buổi luyện.'), findsNothing);
        expect(find.byType(PracticeSessionCard), findsNothing);
        pending.completeError(StateError('test_current_owner_read_error'));
        await tester.pumpAndSettle();
        expect(find.text('Chưa thể tải buổi luyện.'), findsOneWidget);
        expect(find.text('Chưa có buổi luyện'), findsNothing);
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          'beta',
        );
        await tester.ensureVisible(find.text('Thử lại'));
        await tester.tap(find.text('Thử lại'));
        await tester.pumpAndSettle();
        final card = tester.widget<PracticeSessionCard>(
          find.byType(PracticeSessionCard),
        );
        expect(card.session.id, 'current');
        expect(card.session.profileId, b.id);
        expect(find.text(old.title), findsNothing);
        final state = scope
            .read(practiceSessionsControllerProvider.notifier)
            .forProfile(b.id);
        expect(state.query, 'beta');
        expect(state.filters.period, PracticePeriod.week);
        expect(state.filters.order, PracticeOrder.oldest);
        await tester.tap(tab('Cài đặt'));
        await tester.pumpAndSettle();
        await tester.tap(tab('Buổi luyện'));
        await tester.pumpAndSettle();
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          'beta',
        );
        expect(find.byType(PracticeSessionCard), findsOneWidget);
        await tester.enterText(find.byType(TextField), 'không khớp');
        await tester.pumpAndSettle();
        expect(find.text('Không có buổi luyện phù hợp.'), findsOneWidget);
        await tester.ensureVisible(find.text('Xóa tìm kiếm và bộ lọc'));
        await tester.tap(find.text('Xóa tìm kiếm và bộ lọc'));
        await tester.pumpAndSettle();
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          isEmpty,
        );
        expect(
          scope
              .read(practiceSessionsControllerProvider.notifier)
              .forProfile(b.id)
              .filters
              .isActive,
          isFalse,
        );
        expect(find.byType(PracticeSessionCard), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
