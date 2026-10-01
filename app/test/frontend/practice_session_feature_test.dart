import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/app/meloop_app.dart';
import 'package:meloop/frontend/application/instrument_profile_service.dart';
import 'package:meloop/frontend/application/practice_session_provider.dart';
import 'package:meloop/frontend/application/startup_controller.dart';
import 'package:meloop/frontend/components/meloop_ui.dart';
import 'package:meloop/frontend/practice/practice_tools_page.dart';
import 'package:meloop/frontend/practice/saved_practice_page.dart';
import 'package:meloop/frontend/showcase/meloop_ui_showcase.dart';
import 'package:meloop/frontend/showcase/practice_preview_service.dart';
import 'package:meloop/frontend/showcase/session_form_example.dart';
import 'package:meloop/frontend/showcase/setup_example.dart';
import 'package:meloop/frontend/showcase/timer_example.dart';

const _profile = InstrumentProfile(
  id: 'test-guitar',
  name: 'Guitar của tôi',
  instrumentType: InstrumentType.guitar,
);
const _snapshot = StartupSnapshot(
  profiles: [
    PreviewInstrumentProfile(
      id: 'test-guitar',
      name: 'Guitar của tôi',
      instrument: MeloopInstrument.guitar,
    ),
  ],
  selectedProfileId: 'test-guitar',
);

class _Clock extends Stopwatch {
  Duration _elapsed = Duration.zero;
  bool _running = false;
  @override
  Duration get elapsed => _elapsed;
  @override
  bool get isRunning => _running;
  @override
  void start() => _running = true;
  @override
  void stop() => _running = false;
  @override
  void reset() => _elapsed = Duration.zero;
  void advance(Duration interval) {
    if (_running) _elapsed += interval;
  }
}

class _StartFailureService extends PracticePreviewService {
  _StartFailureService() : super(onSave: (_) async {});
  bool failStart = true;
  @override
  Future<PracticeSessionDraft> start({
    required String profileId,
    required String title,
  }) {
    if (failStart) return Future.error(StateError('Synthetic start failure'));
    return super.start(profileId: profileId, title: title);
  }
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Finder _button(String text) => find.widgetWithText(MeloopButton, text);
Finder _tab(String text) => find.descendant(
  of: find.byType(MeloopBottomNavigation),
  matching: find.text(text),
);

Future<void> _open(
  WidgetTester tester,
  PracticePreviewService service, {
  PracticeToolOpen? toolOpen,
  double scale = 1,
}) async {
  await tester.pumpWidget(
    MeloopApp(
      practiceSessionService: service,
      overrides: [
        startupSnapshotProvider.overrideWithValue(_snapshot),
        if (toolOpen != null)
          practiceToolOpenProvider.overrideWithValue(toolOpen),
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          padding: const EdgeInsets.only(top: 24, bottom: 24),
          viewPadding: const EdgeInsets.only(top: 24, bottom: 24),
        ),
        child: child!,
      ),
      home: const MeloopUiShowcase(developmentTools: false, profile: _profile),
    ),
  );
  await tester.pumpAndSettle();
  await _tap(tester, _tab('Buổi luyện'));
}

Future<void> _start(WidgetTester tester) async {
  await _tap(tester, find.byKey(const Key('create-practice-session')));
  await tester.enterText(find.byType(TextFormField), 'Luyện gam C');
  await _tap(tester, _button('Bắt đầu luyện'));
}

Future<void> _close(WidgetTester tester, PracticePreviewService service) async {
  await tester.pumpWidget(const SizedBox.shrink());
  service.dispose();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('failed start keeps setup input and retry enters the timer', (
    tester,
  ) async {
    final service = _StartFailureService();
    await _open(tester, service);
    await _tap(tester, find.byKey(const Key('create-practice-session')));
    await tester.enterText(
      find.byType(TextFormField),
      'Giữ tên khi bắt đầu lỗi',
    );
    await _tap(tester, _button('Bắt đầu luyện'));
    expect(service.current.draft, isNull);
    expect(find.textContaining('Chưa thể bắt đầu buổi luyện.'), findsOneWidget);
    expect(find.text('Giữ tên khi bắt đầu lỗi'), findsOneWidget);
    service.failStart = false;
    await _tap(tester, _button('Bắt đầu luyện'));
    expect(find.byType(TimerExample), findsOneWidget);
    expect(service.current.draft!.title, 'Giữ tên khi bắt đầu lỗi');
    await _close(tester, service);
  });

  testWidgets('zero measured duration is reviewed without inventing a second', (
    tester,
  ) async {
    var saveCalls = 0;
    final service = PracticePreviewService(
      clock: _Clock(),
      onSave: (_) async {
        saveCalls++;
      },
    );
    await _open(tester, service);
    await _start(tester);
    await _tap(tester, _button('Kết thúc'));
    await _tap(tester, _button('Lưu buổi luyện'));
    expect(find.text('Thời lượng phải từ 1 giây đến 24 giờ.'), findsOneWidget);
    expect(service.current.draft, isNotNull);
    expect(saveCalls, 0);
    await tester.enterText(find.byType(TextFormField).at(3), '1');
    await _tap(tester, _button('Lưu buổi luyện'));
    expect(service.current.sessions.single.values.durationSeconds, 1);
    expect(saveCalls, 1);
    await _close(tester, service);
  });

  testWidgets('rename and confirmed discard affect only the current draft', (
    tester,
  ) async {
    final service = PracticePreviewService(onSave: (_) async {});
    await _open(tester, service);
    await _start(tester);
    final id = service.current.draft!.id;
    await _tap(tester, find.byTooltip('Tùy chọn buổi luyện'));
    await _tap(tester, _button('Đổi tên buổi luyện'));
    await tester.enterText(find.byType(TextFormField), 'Tên mới');
    await _tap(tester, _button('Lưu'));
    expect(service.current.draft!.title, 'Tên mới');
    expect(service.current.draft!.id, id);
    await _tap(tester, find.byTooltip('Tùy chọn buổi luyện'));
    await _tap(tester, _button('Hủy buổi luyện'));
    await _tap(tester, _button('Tiếp tục luyện'));
    expect(service.current.draft!.id, id);
    await _tap(tester, find.byTooltip('Tùy chọn buổi luyện'));
    await _tap(tester, _button('Hủy buổi luyện'));
    await _tap(tester, _button('Hủy buổi luyện'));
    expect(service.current.draft, isNull);
    expect(service.current.sessions, isEmpty);
    expect(find.byType(TimerExample), findsNothing);
    await _close(tester, service);
  });

  testWidgets(
    'create icon stays above navigation; service owns elapsed and transitions',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final clock = _Clock();
      var creations = 0;
      final service = PracticePreviewService(
        onSave: (_) async {},
        clock: clock,
        newId: () => 'session-${++creations}',
      );
      await _open(tester, service);
      final fab = find.byKey(const Key('create-practice-session'));
      expect(
        tester.getRect(fab).bottom,
        lessThan(tester.getRect(find.byType(MeloopBottomNavigation)).top),
      );
      expect(tester.getRect(fab).center.dx, greaterThan(390 / 2));
      await _tap(tester, fab);
      await _tap(tester, _button('Bắt đầu luyện'));
      expect(service.current.draft, isNull);
      await tester.enterText(find.byType(TextFormField), 'Luyện gam C');
      await _tap(tester, _button('Bắt đầu luyện'));
      expect(find.byType(SetupExample), findsNothing);
      expect(find.byType(TimerExample), findsOneWidget);
      clock.advance(const Duration(seconds: 125));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('02:05'), findsOneWidget);
      await _tap(tester, _button('Tạm dừng'));
      clock.advance(const Duration(seconds: 50));
      await tester.pump(const Duration(seconds: 50));
      expect(find.text('02:05'), findsOneWidget);
      // An update coming from outside the widget must replace the displayed state.
      await service.resume();
      clock.advance(const Duration(seconds: 31));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('02:36'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(service.current.draft!.isRunning, isFalse);
      await _tap(tester, fab);
      expect(find.byType(SetupExample), findsNothing);
      expect(find.text('02:36'), findsOneWidget);
      expect(creations, 1);
      expect(find.textContaining('bài tập'), findsNothing);
      expect(find.textContaining('kế hoạch'), findsNothing);
      await _close(tester, service);
    },
  );

  testWidgets(
    'tools keep the same session; background pauses until explicit resume',
    (tester) async {
      final clock = _Clock();
      final service = PracticePreviewService(
        onSave: (_) async {},
        clock: clock,
      );
      String? toolSession;
      await _open(
        tester,
        service,
        toolOpen: (_, id, tool) async {
          toolSession = id;
        },
      );
      await _start(tester);
      final id = service.current.draft!.id;
      await _tap(tester, _button('Công cụ'));
      expect(find.byType(PracticeToolsPage), findsOneWidget);
      await _tap(tester, find.text('Máy đếm nhịp'));
      expect(toolSession, id);
      clock.advance(const Duration(seconds: 20));
      await tester.pump(const Duration(seconds: 1));
      expect(service.current.draft!.id, id);
      expect(service.current.draft!.elapsed.inSeconds, 20);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pumpAndSettle();
      expect(service.current.draft!.isRunning, isFalse);
      clock.advance(const Duration(seconds: 70));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(service.current.draft!.isRunning, isFalse);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('00:20'), findsOneWidget);
      expect(_button('Tiếp tục'), findsOneWidget);
      await _close(tester, service);
    },
  );

  testWidgets(
    'finish reviews measured duration, back resumes same session, one save opens details',
    (tester) async {
      final clock = _Clock();
      var saveCalls = 0;
      final pending = Completer<void>();
      final service = PracticePreviewService(
        clock: clock,
        onSave: (_) {
          saveCalls++;
          return pending.future;
        },
      );
      await _open(tester, service);
      await _start(tester);
      final id = service.current.draft!.id;
      clock.advance(const Duration(seconds: 65));
      await _tap(tester, _button('Kết thúc'));
      expect(service.current.draft!.phase, PracticeSessionPhase.review);
      expect(find.byType(SessionFormExample), findsOneWidget);
      expect(saveCalls, 0);
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).at(3))
            .controller!
            .text,
        '5',
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(service.current.draft!.phase, PracticeSessionPhase.paused);
      await _tap(tester, _button('Tiếp tục'));
      clock.advance(const Duration(seconds: 4));
      await _tap(tester, _button('Kết thúc'));
      final save = _button('Lưu buổi luyện');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.tap(save);
      await tester.pump();
      expect(saveCalls, 1);
      expect(service.current.sessions, isEmpty);
      pending.complete();
      await tester.pumpAndSettle();
      expect(service.current.draft, isNull);
      expect(service.current.sessions.single.id, id);
      expect(service.current.sessions.single.values.durationSeconds, 69);
      expect(find.byType(SavedPracticePage), findsOneWidget);
      expect(_button('Kết thúc'), findsNothing);
      expect(_button('Tiếp tục'), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(TimerExample), findsNothing);
      expect(find.text('Luyện gam C'), findsOneWidget);
      expect(saveCalls, 1);
      await _close(tester, service);
    },
  );

  testWidgets(
    'failed save retains review input and retries with the same identity',
    (tester) async {
      final clock = _Clock();
      var attempts = 0;
      final service = PracticePreviewService(
        clock: clock,
        onSave: (_) async {
          if (++attempts == 1) throw StateError('Synthetic save failure');
        },
      );
      await _open(tester, service);
      await _start(tester);
      final id = service.current.draft!.id;
      clock.advance(const Duration(seconds: 3));
      await _tap(tester, _button('Kết thúc'));
      await tester.enterText(
        find.byType(TextFormField).first,
        'Giữ tên khi lỗi',
      );
      await _tap(tester, _button('Lưu buổi luyện'));
      expect(find.textContaining('Chưa thể lưu buổi luyện.'), findsOneWidget);
      expect(service.current.draft!.id, id);
      expect(service.current.sessions, isEmpty);
      expect(find.text('Giữ tên khi lỗi'), findsOneWidget);
      await _tap(tester, _button('Lưu buổi luyện'));
      expect(service.current.sessions.single.values.title, 'Giữ tên khi lỗi');
      expect(service.current.sessions.single.id, id);
      expect(attempts, 2);
      await _close(tester, service);
    },
  );

  for (final width in [320.0, 390.0, 460.0]) {
    for (final scale in [1.0, 3.0]) {
      testWidgets('timer and create action fit $width px / ${scale}x text', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final service = PracticePreviewService(onSave: (_) async {});
        await _open(tester, service, scale: scale);
        final fab = find.byKey(const Key('create-practice-session'));
        expect(
          tester.getRect(fab).bottom,
          lessThan(tester.getRect(find.byType(MeloopBottomNavigation)).top),
        );
        await _start(tester);
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(_button('Kết thúc'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await _close(tester, service);
      });
    }
  }

  test('service excludes paused intervals and saves idempotently after concurrent calls or retries', () async {
    final clock = _Clock();
    final pending = Completer<void>();
    var calls = 0;
    final service = PracticePreviewService(
      clock: clock,
      onSave: (_) {
        calls++;
        return pending.future;
      },
    );
    addTearDown(service.dispose);
    final draft = await service.start(profileId: _profile.id, title: 'First');
    expect(
      (await service.start(profileId: 'another-profile', title: 'Second')).id,
      draft.id,
    );
    clock.advance(const Duration(seconds: 12));
    await service.pause();
    clock.advance(const Duration(seconds: 100));
    await service.resume();
    clock.advance(const Duration(seconds: 8));
    expect((await service.finish()).elapsed.inSeconds, 20);
    final values = SessionFormValues(
      title: 'First',
      date: DateTime(2026, 10, 1),
      durationSeconds: 20,
      practiced: '',
      difficulty: '',
      next: '',
    );
    final first = service.save(draft.id, values);
    final second = service.save(draft.id, values);
    await Future<void>.delayed(Duration.zero);
    expect(calls, 1);
    pending.complete();
    expect((await first).id, (await second).id);
    expect((await service.save(draft.id, values)).id, draft.id);
    expect(service.current.sessions, hasLength(1));
    expect(calls, 1);
  });
}
