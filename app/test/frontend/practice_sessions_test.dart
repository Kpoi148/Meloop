import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/app/meloop_app.dart';
import 'package:meloop/app/profile_preview_app.dart';
import 'package:meloop/l10n/app_localizations.dart';
import 'package:meloop/frontend/application/app_settings_controller.dart';
import 'package:meloop/frontend/application/instrument_profile_service.dart';
import 'package:meloop/frontend/application/startup_controller.dart';
import 'package:meloop/frontend/components/meloop_ui.dart';
import 'package:meloop/frontend/practice_sessions/practice_session.dart';
import 'package:meloop/frontend/practice_sessions/practice_session_card.dart';
import 'package:meloop/frontend/practice_sessions/practice_session_detail_page.dart';
import 'package:meloop/frontend/practice_sessions/practice_sessions_controller.dart';
import 'package:meloop/frontend/practice_sessions/practice_sessions_tab.dart';
import 'package:meloop/frontend/showcase/meloop_ui_showcase.dart';
import 'package:meloop/frontend/showcase/profile_preview_service.dart';
import 'package:meloop/frontend/showcase/practice_session_examples.dart';
import 'package:meloop/frontend/showcase/setup_example.dart';
import 'package:meloop/frontend/showcase/timer_example.dart';
import 'package:meloop/frontend/showcase/welcome_example.dart';
import 'package:meloop/shared/settings/app_settings_store.dart';

import 'support/profile_preview_test_storage.dart';

const _profile = PreviewInstrumentProfile(
  id: 'profile-a',
  name: 'Guitar của tôi',
  instrument: MeloopInstrument.guitar,
);
final _today = DateTime(2026, 10, 1);

PracticeSession _session(
  String id,
  String title,
  DateTime date, {
  String profileId = 'profile-a',
  int recordingCount = 0,
  String difficulty = '',
}) => PracticeSession(
  id: id,
  profileId: profileId,
  title: title,
  date: date,
  duration: const Duration(minutes: 35),
  practiced: 'Luyện chậm từng đoạn, giữ nhịp đều.',
  difficulty: difficulty,
  nextPractice: 'Giữ nhịp ở 80 BPM.',
  mood: 4,
  focus: 5,
  recordingCount: recordingCount,
);

List<PracticeSession> _records() => [
  _session('today', 'Luyện gam C', _today, recordingCount: 2),
  _session('today-2', 'Nhịp điệu cơ bản', _today),
  _session('yesterday', 'Ôn bài nhạc', DateTime(2026, 9, 30)),
  _session('week-edge', 'Luyện gam Am', DateTime(2026, 9, 25, 23, 59)),
  _session('outside-week', 'Chuyển hợp âm', DateTime(2026, 9, 24, 23, 59)),
  _session('month-edge', 'Luyện kỹ thuật', DateTime(2026, 9, 2)),
  _session('old', 'Ôn đoạn khó', DateTime(2026, 9, 1)),
  _session('other-profile', 'Buổi riêng Piano', _today, profileId: 'profile-b'),
];

Finder _tab(String label) => find.descendant(
  of: find.byType(MeloopBottomNavigation),
  matching: find.text(label),
);

Future<void> _openFilters(WidgetTester tester) async {
  final filter = find.byTooltip('Bộ lọc');
  await tester.ensureVisible(filter);
  await tester.tap(filter);
  await tester.pumpAndSettle();
}

Future<void> _applyFilters(
  WidgetTester tester, {
  String? period,
  String? order,
}) async {
  await _openFilters(tester);
  for (final label in [period, order].whereType<String>()) {
    final choice = find.widgetWithText(TextButton, label);
    await tester.ensureVisible(choice);
    await tester.tap(choice);
    await tester.pumpAndSettle();
  }
  final apply = find.widgetWithText(MeloopButton, 'Áp dụng');
  await tester.ensureVisible(apply);
  await tester.tap(apply);
  await tester.pumpAndSettle();
}

String _firstSessionId(WidgetTester tester) => tester
    .widgetList<PracticeSessionCard>(find.byType(PracticeSessionCard))
    .first
    .session
    .id;

void _expectSelectedChoice(WidgetTester tester, String label) => expect(
  tester
      .widget<TextButton>(find.widgetWithText(TextButton, label))
      .style!
      .backgroundColor!
      .resolve({}),
  TempoColors.teal,
);

Future<void> _mount(
  WidgetTester tester, {
  PracticeSessionsLoader? loader,
  PreviewPracticeDraft? draft,
  GlobalKey? boundaryKey,
  bool waitForHome = true,
}) async {
  final child = const MeloopUiShowcase(developmentTools: false);
  await tester.pumpWidget(
    MeloopApp(
      overrides: [
        startupSnapshotProvider.overrideWithValue(
          const StartupSnapshot(
            profiles: [_profile],
            selectedProfileId: 'profile-a',
          ),
        ),
        practiceSessionsClockProvider.overrideWithValue(() => _today),
        practiceSessionsLoaderProvider.overrideWithValue(
          loader ?? (profile) async => _records(),
        ),
      ],
      builder: boundaryKey == null
          ? null
          : (context, child) =>
                RepaintBoundary(key: boundaryKey, child: child!),
      home: child,
    ),
  );
  if (waitForHome) {
    await tester.pumpAndSettle();
  } else {
    // Navigate while Home's shared journal read is intentionally unresolved.
    await tester.pump();
  }
  if (draft != null) {
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MeloopUiShowcase)),
    );
    container
        .read(meloopShellControllerProvider.notifier)
        .reload(
          StartupSnapshot(
            profiles: const [_profile],
            selectedProfileId: _profile.id,
            draft: draft,
          ),
        );
    container.read(meloopShellControllerProvider.notifier).selectTab(1);
  } else {
    await tester.tap(_tab('Buổi luyện'));
  }
  await tester.pump();
}

void main() {
  testWidgets(
    'default profile preview opens details and resets UC-06 view state',
    (tester) async {
      final storage = MemoryProfilePreviewStorage();
      final service = ProfilePreviewService(storage: storage);
      await service.create(
        requestId: 'initial-profile',
        name: 'Guitar của tôi',
        instrumentType: InstrumentType.guitar,
        customType: '',
      );
      await tester.pumpWidget(
        createProfilePreviewApp(
          storage: storage,
          settingsStore: InMemoryAppSettingsStore(languageCode: 'vi'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(_tab('Buổi luyện'));
      await tester.pumpAndSettle();
      expect(find.byType(PracticeSessionCard), findsNWidgets(7));
      final profileId = tester
          .widget<PracticeSessionsTab>(find.byType(PracticeSessionsTab))
          .profile
          .id;
      final card = find.widgetWithText(PracticeSessionCard, 'Luyện gam C');
      await tester.ensureVisible(card);
      await tester.tap(card);
      await tester.pumpAndSettle();
      final detail = tester.widget<PracticeSessionDetailPage>(
        find.byType(PracticeSessionDetailPage),
      );
      expect(detail.session.profileId, profileId);
      expect(detail.profile.id, profileId);
      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();
      await _applyFilters(tester, period: '7 ngày', order: 'Cũ nhất');
      await tester.ensureVisible(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'gam');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.tap(_tab('Cài đặt'));
      await tester.pumpAndSettle();
      final reset = find.byKey(const Key('reset-preview-data'));
      await tester.ensureVisible(reset);
      await tester.tap(reset);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xóa và bắt đầu lại'));
      await tester.pumpAndSettle();
      expect(find.byType(WelcomeExample), findsOneWidget);
      await tester.ensureVisible(find.text('Tạo hồ sơ đầu tiên'));
      await tester.tap(find.text('Tạo hồ sơ đầu tiên'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('profile-type-guitar')));
      await tester.tap(find.byKey(const Key('profile-type-guitar')));
      await tester.pumpAndSettle();
      final save = find.byKey(const Key('save-profile'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      await tester.tap(_tab('Buổi luyện'));
      await tester.pumpAndSettle();
      expect(find.byType(PracticeSessionCard), findsNWidgets(7));
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      await _openFilters(tester);
      _expectSelectedChoice(tester, 'Tất cả');
      _expectSelectedChoice(tester, 'Mới nhất');
      expect(tester.takeException(), isNull);
    },
  );

  test('calendar ranges, notes, sorting and profile isolation', () {
    final records = _records();
    final week = PracticeSessionsViewState(
      filters: const PracticeSessionFilters(period: PracticePeriod.week),
    ).visibleSessions(records, profileId: _profile.id, now: _today);
    expect(week.map((session) => session.id), contains('week-edge'));
    expect(week.map((session) => session.id), isNot(contains('outside-week')));
    expect(week.map((session) => session.id), isNot(contains('other-profile')));
    final month = PracticeSessionsViewState(
      filters: const PracticeSessionFilters(
        period: PracticePeriod.month,
        order: PracticeOrder.oldest,
      ),
    ).visibleSessions(records, profileId: _profile.id, now: _today);
    expect(month.first.id, 'month-edge');
    expect(month.map((session) => session.id), isNot(contains('old')));
    final notes = PracticeSessionsViewState(query: '  TAY TRÁI  ')
        .visibleSessions(
          [
            ...records,
            _session(
              'note',
              'Bài tập mới',
              _today,
              difficulty: 'Thả lỏng tay trái',
            ),
          ],
          profileId: _profile.id,
          now: _today,
        );
    expect(notes.single.id, 'note');
  });

  testWidgets('period filters and details retain search and scroll position', (
    tester,
  ) async {
    await _mount(tester);
    await tester.pumpAndSettle();
    expect(find.text('Buổi riêng Piano'), findsNothing);
    expect(find.text('Khoảng thời gian'), findsNothing);
    expect(find.byTooltip('Bộ lọc'), findsOneWidget);
    expect(find.text('7 ngày'), findsNothing);
    expect(find.text('Hôm nay'), findsOneWidget);
    await _applyFilters(tester, period: '7 ngày', order: 'Cũ nhất');
    expect(find.text('Chuyển hợp âm'), findsNothing);
    expect(find.text('Luyện gam Am'), findsOneWidget);

    expect(find.text('Luyện kỹ thuật'), findsNothing);

    await tester.enterText(find.byType(TextField), 'gam');
    await tester.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    final card = find.widgetWithText(PracticeSessionCard, 'Luyện gam Am');
    await tester.ensureVisible(card);
    final scroll = tester
        .widget<PracticeSessionsTab>(find.byType(PracticeSessionsTab))
        .scrollController;
    final position = scroll.offset;
    await tester.tap(card);
    await tester.pumpAndSettle();
    final detail = tester.widget<PracticeSessionDetailPage>(
      find.byType(PracticeSessionDetailPage),
    );
    expect(detail.session.id, 'week-edge');
    expect(detail.session.profileId, detail.profile.id);
    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pumpAndSettle();
    expect(scroll.offset, closeTo(position, 1));
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'gam',
    );
    expect(find.text('Ôn bài nhạc'), findsNothing);
    await _openFilters(tester);
    _expectSelectedChoice(tester, '7 ngày');
    _expectSelectedChoice(tester, 'Cũ nhất');
    await tester.tap(find.widgetWithText(MeloopButton, 'Xóa bộ lọc'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'gam',
    );
    await tester.enterText(find.byType(TextField), 'không có kết quả');
    await tester.pumpAndSettle();
    expect(find.text('Không có buổi luyện phù hợp.'), findsOneWidget);
    final clear = find.text('Xóa tìm kiếm và bộ lọc');
    await tester.ensureVisible(clear);
    await tester.tap(clear);
    await tester.pumpAndSettle();
    expect(find.text('Ôn đoạn khó'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'period and order apply together, cancel and clear inside the filter sheet',
    (tester) async {
      await _mount(tester);
      await tester.pumpAndSettle();
      for (final label in [
        'Tất cả',
        '7 ngày',
        '30 ngày',
        'Mới nhất',
        'Cũ nhất',
      ]) {
        expect(find.text(label), findsNothing);
      }
      await _openFilters(tester);
      expect(find.text('Khoảng thời gian'), findsOneWidget);
      expect(find.text('Sắp xếp'), findsOneWidget);
      _expectSelectedChoice(tester, 'Tất cả');
      _expectSelectedChoice(tester, 'Mới nhất');
      await tester.tap(find.widgetWithText(TextButton, '7 ngày'));
      await tester.tap(find.widgetWithText(TextButton, 'Cũ nhất'));
      await tester.pumpAndSettle();
      _expectSelectedChoice(tester, '7 ngày');
      _expectSelectedChoice(tester, 'Cũ nhất');
      expect(find.byType(PracticeSessionCard), findsNWidgets(7));
      expect(_firstSessionId(tester), startsWith('today'));
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(PracticeSessionCard), findsNWidgets(7));
      expect(_firstSessionId(tester), startsWith('today'));
      await _openFilters(tester);
      _expectSelectedChoice(tester, 'Tất cả');
      _expectSelectedChoice(tester, 'Mới nhất');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await _applyFilters(tester, period: '7 ngày', order: 'Cũ nhất');
      expect(find.text('7 ngày'), findsNothing);
      expect(find.text('Cũ nhất'), findsNothing);
      expect(find.text('Chuyển hợp âm'), findsNothing);
      expect(find.text('Luyện gam Am'), findsOneWidget);
      expect(_firstSessionId(tester), 'week-edge');
      await _applyFilters(tester, period: '30 ngày');
      expect(find.text('Luyện kỹ thuật'), findsOneWidget);
      expect(find.text('Ôn đoạn khó'), findsNothing);
      expect(_firstSessionId(tester), 'month-edge');
      await _openFilters(tester);
      _expectSelectedChoice(tester, '30 ngày');
      _expectSelectedChoice(tester, 'Cũ nhất');
      await tester.tap(find.widgetWithText(MeloopButton, 'Xóa bộ lọc'));
      await tester.pumpAndSettle();
      expect(find.text('Ôn đoạn khó'), findsOneWidget);
      expect(find.byType(PracticeSessionCard), findsNWidgets(7));
      expect(_firstSessionId(tester), startsWith('today'));
      await _openFilters(tester);
      _expectSelectedChoice(tester, 'Tất cả');
      _expectSelectedChoice(tester, 'Mới nhất');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'period and oldest ordering remain scoped to profile across tabs',
    (tester) async {
      await _mount(tester);
      await tester.pumpAndSettle();
      expect(find.text('Mới nhất'), findsNothing);
      await _applyFilters(tester, order: 'Cũ nhất');
      expect(find.text('Cũ nhất'), findsNothing);
      expect(_firstSessionId(tester), 'old');
      await _applyFilters(tester, period: '7 ngày');
      expect(find.byType(PracticeSessionCard), findsNWidgets(4));
      expect(_firstSessionId(tester), 'week-edge');
      await tester.tap(_tab('Cài đặt'));
      await tester.pumpAndSettle();
      await tester.tap(_tab('Buổi luyện'));
      await tester.pumpAndSettle();
      expect(find.byType(PracticeSessionCard), findsNWidgets(4));
      expect(_firstSessionId(tester), 'week-edge');
      await _openFilters(tester);
      _expectSelectedChoice(tester, '7 ngày');
      _expectSelectedChoice(tester, 'Cũ nhất');
      await tester.tap(find.widgetWithText(TextButton, 'Tất cả'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(MeloopButton, 'Áp dụng'));
      await tester.pumpAndSettle();
      expect(find.byType(PracticeSessionCard), findsNWidgets(7));
      expect(_firstSessionId(tester), 'old');
      await _applyFilters(tester, order: 'Mới nhất');
      expect(find.text('Mới nhất'), findsNothing);
      expect(_firstSessionId(tester), startsWith('today'));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('loading, retry and first-session empty state', (tester) async {
    final pending = Completer<List<PracticeSession>>();
    var calls = 0;
    await _mount(
      tester,
      waitForHome: false,
      loader: (_) {
        calls++;
        return calls == 1 ? pending.future : Future.value(const []);
      },
    );
    expect(find.text('Đang tải buổi luyện…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.completeError(StateError('fixture load failure'));
    await tester.pumpAndSettle();
    expect(find.text('Chưa thể tải buổi luyện.'), findsOneWidget);
    await tester.ensureVisible(find.text('Thử lại'));
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('Chưa có buổi luyện'), findsOneWidget);
    final create = find.byKey(const Key('practice-create'));
    expect(create, findsOneWidget);
    await tester.ensureVisible(create);
    await tester.tap(create);
    await tester.pumpAndSettle();
    expect(find.byType(SetupExample), findsOneWidget);
    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pumpAndSettle();
    expect(find.byType(PracticeSessionsTab), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'fixed create button retains scroll position after Android back',
    (tester) async {
      await _mount(tester);
      await tester.pumpAndSettle();
      final scroll = tester
          .widget<PracticeSessionsTab>(find.byType(PracticeSessionsTab))
          .scrollController;
      scroll.jumpTo(scroll.position.maxScrollExtent);
      await tester.pumpAndSettle();
      final position = scroll.offset;
      await tester.tap(find.byKey(const Key('practice-create')));
      await tester.pumpAndSettle();
      expect(find.byType(SetupExample), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(PracticeSessionsTab), findsOneWidget);
      expect(scroll.offset, closeTo(position, 1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('draft is separate and fixed button resumes the existing timer', (
    tester,
  ) async {
    await _mount(
      tester,
      draft: const PreviewPracticeDraft(
        profileId: 'profile-a',
        title: 'Luyện chuyển hợp âm',
        accumulatedSeconds: 754,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Buổi luyện chưa hoàn tất'), findsOneWidget);
    expect(find.text('12:34'), findsOneWidget);
    expect(find.text('Tạm dừng'), findsOneWidget);
    final resume = find.byKey(const Key('practice-create'));
    await tester.ensureVisible(resume);
    await tester.tap(resume);
    await tester.pumpAndSettle();
    expect(find.byType(TimerExample), findsOneWidget);
    expect(find.byType(SetupExample), findsNothing);
    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pumpAndSettle();
    expect(find.byType(PracticeSessionsTab), findsOneWidget);
    expect(find.text('12:34'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'fixed create button stays visible while scrolling on small screens and large text',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 640);
      for (final scale in [1.0, 2.0]) {
        await tester.pumpWidget(const SizedBox());
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await _mount(tester);
        await tester.pumpAndSettle();
        final createFinder = find.byKey(const Key('practice-create'));
        final initialCreate = tester.getRect(createFinder);
        final viewport = tester.getRect(find.byType(SingleChildScrollView));
        expect(initialCreate.bottom, lessThanOrEqualTo(viewport.bottom));
        expect(
          initialCreate.bottom,
          lessThan(tester.getRect(find.byType(MeloopBottomNavigation)).top),
        );
        final scroll = tester
            .widget<PracticeSessionsTab>(find.byType(PracticeSessionsTab))
            .scrollController;
        scroll.jumpTo(scroll.position.maxScrollExtent);
        await tester.pumpAndSettle();
        final last = tester.getRect(
          find.widgetWithText(PracticeSessionCard, 'Ôn đoạn khó'),
        );
        final create = tester.getRect(createFinder);
        final navigation = tester.getRect(find.byType(MeloopBottomNavigation));
        expect(last.bottom, lessThan(create.top));
        expect(create.bottom, lessThan(navigation.top));
        expect(create.width, 60);
        expect(create.left, greaterThan(viewport.center.dx));
        expect(create, initialCreate);
        expect(last.bottom, lessThanOrEqualTo(viewport.bottom));
        await _applyFilters(tester, period: '7 ngày', order: 'Cũ nhất');
        tester.view.viewInsets = const FakeViewPadding(bottom: 240);
        await tester.pumpAndSettle();
        expect(createFinder, findsNothing);
        expect(find.byType(MeloopBottomNavigation), findsNothing);
        tester.view.resetViewInsets();
        await tester.pumpAndSettle();
        expect(createFinder, findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('capture UC-06 list, filter sheet and detail with Tempo assets', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(411, 867);
    final fonts = FontLoader(TempoType.fontFamily);
    for (final weight in [400, 500, 600, 700]) {
      fonts.addFont(rootBundle.load('assets/fonts/be-vietnam-pro-$weight.ttf'));
    }
    await fonts.load();
    final boundary = GlobalKey();
    await _mount(
      tester,
      boundaryKey: boundary,
      loader: (profile) async => practiceSessionExamples(
        lookupAppLocalizations(const Locale('vi')),
        profile,
        _today,
      ),
    );
    await tester.runAsync(() async {
      for (final asset in [
        'instruments-v2.png',
        'illustrations.png',
        'tools-v2.png',
      ]) {
        await precacheImage(
          AssetImage('assets/illustrations/$asset'),
          boundary.currentContext!,
        );
      }
    });
    await tester.pumpAndSettle();
    // Keep the Tempo controls while making the header compact and separated.
    final topBar = tester.getRect(find.byType(MeloopTopBar));
    expect(topBar.left, 20);
    expect(topBar.top, 22);
    expect(topBar.height, closeTo(47, 1));
    final heading = find.text('Buổi luyện').first;
    expect(tester.getTopLeft(heading).dx, 20);
    final introArt = find.byWidgetPredicate(
      (widget) => widget is MeloopArt && widget.scene == MeloopScene.journal,
    );
    final subtitle = find.text('Những nốt nhạc làm nên hành trình.');
    expect(
      tester.getRect(subtitle).right,
      lessThan(tester.getRect(introArt).left),
    );
    expect(
      tester.getTopLeft(find.byType(TextField)).dy,
      lessThanOrEqualTo(210),
    );
    expect(tester.getSize(find.byType(TextField)).height, closeTo(49, 1));
    expect(tester.getSize(find.byType(MeloopSearch)).width, 314);
    final filter = find.byTooltip('Bộ lọc');
    expect(filter, findsOneWidget);
    expect(tester.getSize(filter), const Size.square(49));
    expect(find.text('Tất cả'), findsNothing);
    expect(find.text('7 ngày'), findsNothing);
    expect(find.text('30 ngày'), findsNothing);
    expect(find.text('Sắp xếp'), findsNothing);
    expect(find.text('Mới nhất'), findsNothing);
    expect(find.text('Cũ nhất'), findsNothing);
    expect(tester.getTopLeft(find.text('Hôm nay')).dy, lessThanOrEqualTo(276));
    expect(
      tester.getSize(find.byType(MeloopBottomNavigation)).height,
      closeTo(86, 2),
    );
    Future<void> capture(String name) async {
      await tester.runAsync(() async {
        final render =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final snapshot = await render.toImage();
        final bytes = await snapshot.toByteData(format: ui.ImageByteFormat.png);
        final output = File('build/ui-review/$name.png');
        await output.parent.create(recursive: true);
        await output.writeAsBytes(bytes!.buffer.asUint8List());
        snapshot.dispose();
      });
    }

    await capture('uc06-sessions');
    final scroll = tester
        .widget<PracticeSessionsTab>(find.byType(PracticeSessionsTab))
        .scrollController;
    scroll.jumpTo(scroll.position.maxScrollExtent);
    await tester.pumpAndSettle();
    final create = find.byKey(const Key('practice-create'));
    expect(tester.getSize(create), const Size(60, 60));
    await capture('uc06-create');
    scroll.jumpTo(0);
    await tester.pumpAndSettle();
    await _openFilters(tester);
    await tester.tap(find.widgetWithText(TextButton, '30 ngày'));
    await tester.pumpAndSettle();
    await capture('uc06-filters');
    await tester.tap(find.widgetWithText(MeloopButton, 'Áp dụng'));
    await tester.pumpAndSettle();
    await capture('uc06-period-filter');
    await tester.tap(find.widgetWithText(PracticeSessionCard, 'Luyện gam C'));
    await tester.pumpAndSettle();
    await capture('uc06-detail');
    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MeloopUiShowcase)),
    );
    await container.read(appLocaleProvider.notifier).select(const Locale('en'));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/illustrations/illustrations.png'),
        boundary.currentContext!,
      );
    });
    await tester.pumpAndSettle();
    scroll.jumpTo(0);
    await tester.pumpAndSettle();
    final englishSubtitle = find.text('The notes that shape your journey.');
    expect(
      tester.getRect(englishSubtitle).right,
      lessThan(tester.getRect(introArt).left),
    );
    expect(
      tester.getTopLeft(find.byType(TextField)).dy,
      lessThanOrEqualTo(210),
    );
    await capture('uc06-sessions-en');
    tester.view.physicalSize = const Size(320, 640);
    await tester.pumpAndSettle();
    expect(
      tester.getRect(englishSubtitle).right,
      lessThan(tester.getRect(introArt).left),
    );
    await capture('uc06-sessions-en-narrow');
    expect(tester.takeException(), isNull);
  });
}
