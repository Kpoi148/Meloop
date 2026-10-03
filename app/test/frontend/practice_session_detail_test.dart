import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/app/meloop_app.dart';
import 'package:meloop/frontend/application/app_settings_controller.dart';
import 'package:meloop/frontend/application/startup_controller.dart';
import 'package:meloop/frontend/components/meloop_ui.dart';
import 'package:meloop/frontend/practice_sessions/practice_session.dart';
import 'package:meloop/frontend/practice_sessions/practice_session_actions.dart';
import 'package:meloop/frontend/practice_sessions/practice_session_card.dart';
import 'package:meloop/frontend/practice_sessions/practice_session_detail_page.dart';
import 'package:meloop/frontend/practice_sessions/practice_session_recordings_page.dart';
import 'package:meloop/frontend/practice_sessions/practice_session_summary.dart';
import 'package:meloop/frontend/practice_sessions/practice_sessions_tab.dart';
import 'package:meloop/frontend/showcase/meloop_ui_showcase.dart';
import 'package:meloop/frontend/showcase/home_example.dart';
import 'package:meloop/frontend/showcase/practice_session_examples.dart';
import 'package:meloop/frontend/showcase/session_form_example.dart';
import 'package:meloop/shared/settings/app_settings_store.dart';

const _profile = PreviewInstrumentProfile(
  id: 'guitar-detail',
  name: 'Guitar của tôi',
  instrument: MeloopInstrument.guitar,
);
final _today = DateTime(2026, 10, 2);

Future<ProviderContainer> _mount(
  WidgetTester tester, {
  PracticeSessionDelete? delete,
  PracticeSessionUpdate? update,
  GlobalKey? boundary,
}) async {
  await tester.pumpWidget(
    MeloopApp(
      overrides: [
        appSettingsStoreProvider.overrideWithValue(
          InMemoryAppSettingsStore(languageCode: 'vi'),
        ),
        startupSnapshotProvider.overrideWithValue(
          const StartupSnapshot(
            profiles: [_profile],
            selectedProfileId: 'guitar-detail',
          ),
        ),
        practiceSessionsClockProvider.overrideWithValue(() => _today),
        practiceSessionsLoaderProvider.overrideWith(
          (ref) => ref.watch(practiceSessionsPreviewLoaderProvider),
        ),
        practiceSessionUpdateProvider.overrideWith(
          (ref) =>
              update ??
              ref.read(practiceSessionPreviewChangesProvider.notifier).update,
        ),
        practiceSessionDeleteProvider.overrideWith(
          (ref) =>
              delete ??
              ref.read(practiceSessionPreviewChangesProvider.notifier).delete,
        ),
        practiceRecordingDeleteProvider.overrideWith(
          (ref) => ref
              .read(practiceSessionPreviewChangesProvider.notifier)
              .deleteRecording,
        ),
      ],
      builder: boundary == null
          ? null
          : (_, child) => RepaintBoundary(key: boundary, child: child!),
      home: const MeloopUiShowcase(developmentTools: false),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(
      of: find.byType(MeloopBottomNavigation),
      matching: find.text('Buổi luyện'),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(
    tester.element(find.byType(MeloopUiShowcase)),
  );
}

Future<void> _open(WidgetTester tester, [String title = 'Luyện gam C']) async {
  final card = find.widgetWithText(PracticeSessionCard, title);
  await tester.ensureVisible(card);
  await tester.tap(card);
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String label) async {
  final finder = find.text(label);
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'edit failure keeps entered content; cancel discard and retry are safe',
    (tester) async {
      var calls = 0;
      late ProviderContainer container;
      container = await _mount(
        tester,
        update: (session, values) async {
          calls++;
          if (calls == 1) throw StateError('Storage unavailable');
          return container
              .read(practiceSessionPreviewChangesProvider.notifier)
              .update(session, values);
        },
      );
      await _open(tester);
      await _tap(tester, 'Sửa nhật ký');
      final title = find.byWidgetPredicate(
        (widget) =>
            widget is TextFormField && widget.controller?.text == 'Luyện gam C',
      );
      await tester.enterText(title, 'Chuyển hợp âm');
      FocusManager.instance.primaryFocus?.unfocus();
      await _tap(tester, 'Lưu thay đổi');
      expect(find.textContaining('Chưa thể lưu buổi luyện.'), findsOneWidget);
      expect(container.read(practiceSessionPreviewChangesProvider), isEmpty);
      await tester.ensureVisible(find.byTooltip('Quay lại'));
      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();
      await _tap(tester, 'Tiếp tục sửa');
      expect(find.byType(SessionFormExample), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is TextFormField &&
              widget.controller?.text == 'Chuyển hợp âm',
        ),
        findsOneWidget,
      );
      await _tap(tester, 'Lưu thay đổi');
      expect(calls, 2);
      expect(find.text('Chuyển hợp âm'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'details retain empty fields and expose no timer or recording creation',
    (tester) async {
      await _mount(tester);
      await _open(tester, 'Ôn lại những đoạn khó');
      expect(find.text('— / 5', findRichText: true), findsNWidgets(2));
      expect(find.text('Chưa có ghi chú.'), findsOneWidget);
      expect(find.text('Tiếp tục buổi luyện'), findsNothing);
      expect(find.text('Hoàn tất'), findsNothing);
      expect(find.text('Ghi âm'), findsNothing);
      await _tap(tester, 'Sửa nhật ký');
      final form = tester.widget<SessionFormExample>(
        find.byType(SessionFormExample),
      );
      expect(form.editing, isTrue);
      expect(form.initialValues!.mood, isNull);
      expect(form.initialValues!.focus, isNull);
      expect(form.initialValues!.difficulty, isEmpty);
      await tester.ensureVisible(find.byTooltip('Quay lại'));
      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(find.byType(PracticeSessionDetailPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'edit prefills every field and updates this session without changing its recordings',
    (tester) async {
      final container = await _mount(tester);
      await _open(tester);
      await _tap(tester, 'Sửa nhật ký');
      final form = tester.widget<SessionFormExample>(
        find.byType(SessionFormExample),
      );
      expect(form.initialValues!.title, 'Luyện gam C');
      expect(form.initialValues!.durationSeconds, 35 * 60);
      expect(form.initialValues!.mood, 5);
      expect(form.initialValues!.focus, 4);
      expect(form.initialValues!.bpm, 80);
      expect(form.initialValues!.date, DateTime(2026, 10, 2, 19));
      final title = find.byWidgetPredicate(
        (widget) =>
            widget is TextFormField && widget.controller?.text == 'Luyện gam C',
      );
      await tester.ensureVisible(title);
      await tester.enterText(title, 'Luyện gam C trưởng');
      FocusManager.instance.primaryFocus?.unfocus();
      await _tap(tester, 'Lưu thay đổi');
      expect(find.byType(PracticeSessionDetailPage), findsOneWidget);
      expect(find.text('Luyện gam C trưởng'), findsOneWidget);
      final updated = container.read(
        practiceSessionPreviewChangesProvider,
      )['guitar-detail:session-0']!;
      expect(updated.practiced, form.initialValues!.practiced);
      expect(updated.difficulty, form.initialValues!.difficulty);
      expect(updated.nextPractice, form.initialValues!.next);
      expect(updated.recordings, hasLength(2));
      await tester.ensureVisible(find.byTooltip('Quay lại'));
      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(PracticeSessionCard, 'Luyện gam C trưởng'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'cancel and Android back retain data; confirmed delete removes exactly one and refreshes totals',
    (tester) async {
      final container = await _mount(tester);
      final original = await container.read(
        practiceSessionsProvider(_profile).future,
      );
      final before = PracticeSessionSummary(original, _today);
      await _open(tester);
      await _tap(tester, 'Xóa buổi luyện');
      expect(
        find.textContaining('Bản ghi âm vẫn được giữ riêng.'),
        findsOneWidget,
      );
      await _tap(tester, 'Hủy');
      expect(container.read(practiceSessionPreviewChangesProvider), isEmpty);
      expect(find.byType(PracticeSessionDetailPage), findsOneWidget);
      await _tap(tester, 'Xóa buổi luyện');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(container.read(practiceSessionPreviewChangesProvider), isEmpty);
      await _tap(tester, 'Xóa buổi luyện');
      await tester.tap(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.text('Xóa buổi luyện'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PracticeSessionsTab), findsOneWidget);
      expect(find.byType(PracticeSessionDetailPage), findsNothing);
      expect(
        find.widgetWithText(PracticeSessionCard, 'Luyện gam C'),
        findsNothing,
      );
      final remaining = await container.read(
        practiceSessionsProvider(_profile).future,
      );
      expect(remaining.length, original.length - 1);
      expect(
        remaining.map((session) => session.id),
        isNot(contains('guitar-detail:session-0')),
      );
      final after = PracticeSessionSummary(remaining, _today);
      expect(after.count, before.count - 1);
      expect(after.minutes, before.minutes - 35);
      expect(
        tester
            .widget<MeloopBottomNavigation>(find.byType(MeloopBottomNavigation))
            .selectedIndex,
        1,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'failed delete retains details and retries without a duplicate action',
    (tester) async {
      var calls = 0;
      final pending = <String>[];
      await _mount(
        tester,
        delete: (session) async {
          calls++;
          pending.add(session.id);
          if (calls == 1) throw StateError('Storage unavailable');
        },
      );
      await _open(tester);
      await _tap(tester, 'Xóa buổi luyện');
      await tester.tap(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.text('Xóa buổi luyện'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Chưa thể xóa.'), findsOneWidget);
      expect(
        find.byType(PracticeSessionDetailPage, skipOffstage: false),
        findsOneWidget,
      );
      expect(calls, 1);
      await _tap(tester, 'Thử lại');
      expect(calls, 2);
      expect(pending.toSet(), {'guitar-detail:session-0'});
      expect(find.byType(PracticeSessionDetailPage), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'saved session recordings have no capture action and return to their journal',
    (tester) async {
      final container = await _mount(tester);
      await _open(tester, 'Ôn lại những đoạn khó');
      final savedId = tester
          .widget<PracticeSessionDetailPage>(
            find.byType(PracticeSessionDetailPage),
          )
          .session
          .id;
      await _tap(tester, 'Bản ghi của buổi này');
      expect(find.byType(PracticeSessionRecordingsPage), findsOneWidget);
      expect(find.text('Bản ghi của buổi luyện'), findsOneWidget);
      expect(find.text('Lắng nghe\nhành trình của bạn.'), findsOneWidget);
      expect(find.text('Chưa có bản ghi âm.'), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('Ghi âm buổi luyện'), findsNothing);
      expect(
        container.read(meloopShellControllerProvider).selectedDraft,
        isNull,
      );
      expect(container.read(practiceSessionPreviewChangesProvider), isEmpty);
      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<PracticeSessionDetailPage>(
              find.byType(PracticeSessionDetailPage),
            )
            .session
            .id,
        savedId,
      );
      await _tap(tester, 'Bản ghi của buổi này');
      await tester.tap(find.byTooltip('Trang chủ'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeExample), findsOneWidget);
      expect(find.byType(PracticeSessionRecordingsPage), findsNothing);
      expect(container.read(practiceSessionPreviewChangesProvider), isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'related recordings stay scoped and deleting a recording keeps the journal',
    (tester) async {
      final container = await _mount(tester);
      await _open(tester);
      await _tap(tester, 'Bản ghi của buổi này');
      expect(find.text('Luyện gam C · Lần 1'), findsOneWidget);
      expect(find.text('Luyện gam C · Lần 2'), findsOneWidget);
      expect(find.text('Ghi âm'), findsNothing);
      expect(
        tester
            .widget<IconButton>(
              find
                  .byWidgetPredicate(
                    (widget) =>
                        widget is IconButton && widget.tooltip == 'Nghe lại',
                  )
                  .first,
            )
            .onPressed,
        isNotNull,
      );
      expect(
        tester
            .widget<TextButton>(
              find.widgetWithText(TextButton, 'Xuất bản ghi').first,
            )
            .onPressed,
        isNotNull,
      );
      await tester.tap(find.byTooltip('Xóa bản ghi').first);
      await tester.pumpAndSettle();
      await _tap(tester, 'Xóa bản ghi');
      expect(find.text('Luyện gam C · Lần 1'), findsNothing);
      expect(find.text('Luyện gam C · Lần 2'), findsOneWidget);
      expect(
        container
            .read(
              practiceSessionPreviewChangesProvider,
            )['guitar-detail:session-0']!
            .recordings,
        hasLength(1),
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(PracticeSessionDetailPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'capture detail, edit, recordings and delete at prototype size and check large text',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(411, 867);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final fonts = FontLoader(TempoType.fontFamily);
      for (final weight in [400, 500, 600, 700]) {
        fonts.addFont(
          rootBundle.load('assets/fonts/be-vietnam-pro-$weight.ttf'),
        );
      }
      await fonts.load();
      final boundary = GlobalKey();
      await _mount(tester, boundary: boundary);
      await tester.runAsync(() async {
        for (final name in [
          'illustrations.png',
          'tools-v2.png',
          'instruments-v2.png',
        ]) {
          await precacheImage(
            AssetImage('assets/illustrations/$name'),
            boundary.currentContext!,
          );
        }
      });
      await _open(tester);
      Future<void> capture(String name) async {
        await tester.runAsync(() async {
          final render =
              boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final snapshot = await render.toImage();
          final bytes = await snapshot.toByteData(
            format: ui.ImageByteFormat.png,
          );
          final output = File('build/ui-review/$name.png');
          await output.parent.create(recursive: true);
          await output.writeAsBytes(bytes!.buffer.asUint8List());
          snapshot.dispose();
        });
      }

      await capture('flutter-detail-top');
      final scroll = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position;
      scroll.jumpTo(scroll.maxScrollExtent);
      await tester.pumpAndSettle();
      await capture('flutter-detail-bottom');
      await _tap(tester, 'Xóa buổi luyện');
      await capture('flutter-delete');
      await _tap(tester, 'Hủy');
      await _tap(tester, 'Bản ghi của buổi này');
      await capture('flutter-recordings');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await _tap(tester, 'Sửa nhật ký');
      await capture('flutter-edit');
      await tester.ensureVisible(find.byTooltip('Quay lại'));
      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(320, 640);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
      await _tap(tester, 'Xóa buổi luyện');
      await capture('flutter-delete-large-text');
      await _tap(tester, 'Hủy');
      await _tap(tester, 'Sửa nhật ký');
      await capture('flutter-edit-large-text');
      tester.view.viewInsets = const FakeViewPadding(bottom: 240);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      expect(find.text('Lưu thay đổi'), findsOneWidget);
      expect(
        tester.getRect(find.text('Lưu thay đổi')).bottom,
        lessThanOrEqualTo(400),
      );
      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(SessionFormExample)),
      );
      await container
          .read(appLocaleProvider.notifier)
          .select(const Locale('en'));
      await tester.pumpAndSettle();
      expect(find.text('Save changes'), findsOneWidget);
      await capture('flutter-edit-large-text-en');
      expect(tester.takeException(), isNull);
    },
  );
}
