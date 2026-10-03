import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/app/meloop_app.dart';
import 'package:meloop/frontend/application/app_settings_controller.dart';
import 'package:meloop/frontend/components/meloop_ui.dart';
import 'package:meloop/frontend/progress/practice_progress_page.dart';
import 'package:meloop/frontend/progress/progress_data.dart';
import 'package:meloop/frontend/progress/progress_filter_popup.dart';
import 'package:meloop/frontend/practice_sessions/practice_session.dart';
import 'package:meloop/frontend/showcase/progress_examples.dart';
import 'package:meloop/shared/settings/app_settings_store.dart';

void main() {
  setUpAll(() async {
    final font = FontLoader(TempoType.fontFamily);
    for (final weight in [400, 500, 600, 700]) {
      font.addFont(rootBundle.load('assets/fonts/be-vietnam-pro-$weight.ttf'));
    }
    await font.load();
  });
  final today = DateTime(2026, 9, 23);
  final profile = ProgressExamples.profiles.first;
  PracticeSession session(
    String id,
    DateTime date, {
    int minutes = 20,
    int? mood,
    int? focus,
    String? profileId,
  }) => PracticeSession(
    id: id,
    profileId: profileId ?? profile.id,
    date: date,
    title: 'Luyện gam C',
    duration: Duration(minutes: minutes),
    mood: mood,
    focus: focus,
  );

  test(
    'range includes both boundaries and ratings use only evaluated sessions',
    () {
      final data = ProgressData.fromSessions(
        [
          session('start', DateTime(2026, 9, 17), mood: 5),
          session('same-day', DateTime(2026, 9, 17, 20), mood: 3, focus: 4),
          session('unrated', DateTime(2026, 9, 18)),
          session('end', today, mood: 4, focus: 2),
          session('before', DateTime(2026, 9, 16), mood: 1),
          session('future', DateTime(2026, 9, 24), mood: 1),
          session('other-profile', today, profileId: 'other', mood: 1),
        ],
        profileId: profile.id,
        today: today,
      );
      expect(data.minutes, 80);
      expect(data.count, 4);
      expect(data.mood.count, 3);
      expect(data.mood.average, 4);
      expect(data.focus.average, 3);
      expect(data.days.first.minutes, 40);
      expect(data.days.first.mood, 4);
      expect(data.days[1].mood, isNull);
      expect(data.days[2].focus, isNull);
      final range = ProgressData.fromSessions(
        [
          session('old', DateTime(2026, 9, 16), mood: 1),
          session('current', today, mood: 5),
        ],
        profileId: profile.id,
        today: today,
        range: DateTimeRange(
          start: DateTime(2026, 9, 16),
          end: DateTime(2026, 9, 16),
        ),
      );
      expect(range.days, hasLength(1));
      expect(range.minutes, 20);
      expect(range.mood.average, 1);
    },
  );

  Widget app(
    List<PracticeSession> Function() records, {
    String locale = 'vi',
    double scale = 1,
    bool isPro = true,
    VoidCallback? onViewPro,
  }) => MeloopApp(
    overrides: [
      appSettingsStoreProvider.overrideWithValue(
        InMemoryAppSettingsStore(languageCode: locale),
      ),
      practiceSessionsClockProvider.overrideWithValue(() => today),
      practiceSessionsLoaderProvider.overrideWithValue((_) async => records()),
    ],
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: MeloopPage(
      child: PracticeProgressPage(
        profile: profile,
        isPro: isPro,
        onViewPro: onViewPro,
        onRetry: () {},
        onHistory: () {},
        onInstrument: () {},
      ),
    ),
  );

  testWidgets('missing ratings have no bars and readable descriptions', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      app(
        () => [
          session('rated', today, mood: 5),
          session('unrated', DateTime(2026, 9, 22)),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('progress-mood-card')),
    );
    expect(
      find.byKey(ValueKey('progress-mood-bar-${today.toIso8601String()}')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        ValueKey(
          'progress-mood-bar-${DateTime(2026, 9, 22).toIso8601String()}',
        ),
      ),
      findsNothing,
    );
    expect(
      find.byKey(ValueKey('progress-focus-bar-${today.toIso8601String()}')),
      findsNothing,
    );
    expect(
      find.bySemanticsLabel(RegExp('22/9/2026: Cảm xúc, chưa có đánh giá')),
      findsOneWidget,
    );
    expect(find.text('Trung bình · 1 buổi có đánh giá'), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'source refresh updates totals and all ratings after edit/delete/restore',
    (tester) async {
      var records = [session('original', today, mood: 5, focus: 4)];
      await tester.pumpWidget(app(() => records));
      await tester.pumpAndSettle();
      final scope = ProviderScope.containerOf(
        tester.element(find.byType(PracticeProgressPage)),
      );
      records = [session('original', today, minutes: 35, mood: 2)];
      scope.invalidate(practiceSessionsProvider(profile));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.byKey(const Key('overview-minutes'))).data,
        '35',
      );
      expect(
        find.byKey(ValueKey('progress-focus-bar-${today.toIso8601String()}')),
        findsNothing,
      );
      records = [];
      scope.invalidate(practiceSessionsProvider(profile));
      await tester.pumpAndSettle();
      expect(find.text('Chưa có dữ liệu tiến độ.'), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('overview-count'))).data,
        '0',
      );
      records = [session('restored', today, mood: 3, focus: 5)];
      scope.invalidate(practiceSessionsProvider(profile));
      await tester.pumpAndSettle();
      expect(find.text('Chưa có dữ liệu tiến độ.'), findsNothing);
      expect(
        tester.widget<Text>(find.byKey(const Key('overview-count'))).data,
        '1',
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('filter stays within Progress and updates the period', (
    tester,
  ) async {
    await tester.pumpWidget(app(() => [session('current', today)]));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('progress-filter')));
    await tester.pumpAndSettle();
    expect(find.byType(ProgressFilterPopup), findsOneWidget);
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byKey(const Key('progress-range-calendar')), findsNothing);
    await tester.tap(find.byKey(const Key('progress-preset-custom')));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(DateRangePickerDialog), findsNothing);
    final day = find.byKey(
      ValueKey('progress-calendar-day-${today.toIso8601String()}'),
    );
    await tester.ensureVisible(day);
    await tester.tap(day);
    await tester.tap(day);
    await tester.tap(find.byKey(const Key('progress-filter-apply')));
    await tester.pumpAndSettle();
    expect(find.byType(ProgressFilterPopup), findsNothing);
    expect(find.byType(PracticeProgressPage), findsOneWidget);
    expect(
      find.byKey(ValueKey('progress-minutes-bar-${today.toIso8601String()}')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        ValueKey(
          'progress-minutes-bar-${DateTime(2026, 9, 17).toIso8601String()}',
        ),
      ),
      findsNothing,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'tapping outside the popup dismisses without applying draft changes',
    (tester) async {
      await tester.pumpWidget(app(() => [session('current', today)]));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('progress-filter')));
      await tester.pumpAndSettle();
      final popup = tester.getRect(find.byType(ProgressFilterPopup));
      final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
      expect(popup.left, greaterThan(0));
      expect(popup.top, greaterThan(0));
      expect(popup.right, lessThan(screen.width));
      expect(popup.bottom, lessThan(screen.height));
      await tester.tap(find.byKey(const Key('progress-preset-thirtyDays')));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(1, 1));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(find.byType(PracticeProgressPage), findsOneWidget);
      await tester.tap(find.byKey(const Key('progress-filter')));
      await tester.pumpAndSettle();
      expect(find.text('7 ngày trong khoảng đã chọn'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'advanced filter requires Pro and opens the existing Pro action',
    (tester) async {
      var openedPro = false;
      await tester.pumpWidget(
        app(
          () => [session('current', today)],
          isPro: false,
          onViewPro: () => openedPro = true,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('progress-filter')));
      await tester.pumpAndSettle();
      expect(find.byType(ProgressFilterPopup), findsNothing);
      expect(find.text('Meloop Pro'), findsOneWidget);
      expect(find.byKey(const Key('progress-range-calendar')), findsNothing);
      await tester.tap(find.byKey(const Key('progress-filter-upgrade')));
      await tester.pumpAndSettle();
      expect(openedPro, isTrue);
      expect(find.byKey(const Key('progress-filter-upgrade')), findsNothing);
      expect(find.byType(PracticeProgressPage), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'presets update every chart only after apply and cancel preserves the range',
    (tester) async {
      final older = DateTime(2026, 8, 30);
      await tester.pumpWidget(
        app(
          () => [
            session('older', older, minutes: 35, mood: 2, focus: 3),
            session('current', today, mood: 4, focus: 5),
          ],
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('progress-filter')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('progress-preset-thirtyDays')));
      await tester.pumpAndSettle();
      expect(find.text('30 ngày trong khoảng đã chọn'), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('overview-minutes'))).data,
        '20',
      );
      await tester.tap(find.byKey(const Key('progress-filter-apply')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.byKey(const Key('overview-minutes'))).data,
        '55',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('overview-count'))).data,
        '2',
      );
      for (final chart in ['minutes', 'mood', 'focus']) {
        expect(
          find.byKey(
            ValueKey('progress-$chart-bar-${older.toIso8601String()}'),
          ),
          findsOneWidget,
        );
      }
      await tester.tap(find.byKey(const Key('progress-filter')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('progress-preset-thisMonth')));
      await tester.pumpAndSettle();
      expect(find.text('23 ngày trong khoảng đã chọn'), findsOneWidget);
      await tester.tap(find.byKey(const Key('progress-filter-close')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.byKey(const Key('overview-minutes'))).data,
        '55',
      );
      await tester.tap(find.byKey(const Key('progress-filter')));
      await tester.pumpAndSettle();
      expect(find.text('30 ngày trong khoảng đã chọn'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('custom range crosses months and does not allow future days', (
    tester,
  ) async {
    await tester.pumpWidget(app(() => [session('current', today)]));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('progress-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('progress-preset-custom')));
    await tester.pumpAndSettle();
    final future = find.byKey(
      ValueKey(
        'progress-calendar-day-${DateTime(2026, 9, 24).toIso8601String()}',
      ),
    );
    expect(tester.widget<InkWell>(future).onTap, isNull);
    expect(
      tester
          .widget<IconButton>(find.byKey(const Key('progress-calendar-next')))
          .onPressed,
      isNull,
    );
    await tester.ensureVisible(
      find.byKey(const Key('progress-calendar-previous')),
    );
    await tester.tap(find.byKey(const Key('progress-calendar-previous')));
    await tester.pumpAndSettle();
    final start = find.byKey(
      ValueKey(
        'progress-calendar-day-${DateTime(2026, 8, 30).toIso8601String()}',
      ),
    );
    await tester.ensureVisible(start);
    await tester.tap(start);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('progress-range-end')));
    await tester.tap(find.byKey(const Key('progress-range-end')));
    await tester.pumpAndSettle();
    final end = find.byKey(
      ValueKey(
        'progress-calendar-day-${DateTime(2026, 9, 3).toIso8601String()}',
      ),
    );
    await tester.ensureVisible(end);
    await tester.tap(end);
    await tester.pumpAndSettle();
    expect(find.text('5 ngày trong khoảng đã chọn'), findsOneWidget);
    await tester.tap(find.byKey(const Key('progress-filter-apply')));
    await tester.pumpAndSettle();
    expect(find.text('Chưa có dữ liệu tiến độ.'), findsOneWidget);
    expect(
      find.byKey(ValueKey('progress-minutes-bar-${today.toIso8601String()}')),
      findsNothing,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('filter and paid introduction remain usable with large text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final locale in ['vi', 'en']) {
      for (final scale in [1.0, 2.0, 3.0]) {
        for (final isPro in [true, false]) {
          await tester.pumpWidget(
            app(
              () => [session('rated', today, mood: 4, focus: 5)],
              locale: locale,
              scale: scale,
              isPro: isPro,
              onViewPro: () {},
            ),
          );
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.byKey(const Key('progress-filter')));
          await tester.tap(find.byKey(const Key('progress-filter')));
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '$locale/$scale/$isPro',
          );
          final action = find.byKey(
            Key(isPro ? 'progress-filter-apply' : 'progress-filter-upgrade'),
          );
          await tester.ensureVisible(action);
          await tester.tap(action);
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: 'apply $locale/$scale/$isPro',
          );
          await tester.pumpWidget(const SizedBox.shrink());
        }
      }
    }
  });

  testWidgets(
    'small screens and enlarged text preserve readable charts in vi/en',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final locale in ['vi', 'en']) {
        for (final width in [320.0, 390.0, 460.0]) {
          for (final scale in [1.0, 2.0, 3.0]) {
            tester.view.physicalSize = Size(width, 640);
            await tester.pumpWidget(
              app(
                () => [session('rated', today, mood: 4, focus: 5)],
                locale: locale,
                scale: scale,
              ),
            );
            await tester.pumpAndSettle();
            expect(
              tester.takeException(),
              isNull,
              reason: '$locale/$width/$scale',
            );
            await tester.ensureVisible(
              find.byKey(const ValueKey('progress-focus-card')),
            );
            await tester.pumpAndSettle();
            expect(
              tester.takeException(),
              isNull,
              reason: 'charts $locale/$width/$scale',
            );
            await tester.pumpWidget(const SizedBox.shrink());
          }
        }
      }
    },
  );
}
