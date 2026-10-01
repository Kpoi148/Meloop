import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meloop/app/meloop_app.dart';
import 'package:meloop/frontend/application/startup_controller.dart';
import 'package:meloop/frontend/components/meloop_ui.dart';
import 'package:meloop/frontend/practice/saved_practice_page.dart';
import 'package:meloop/frontend/showcase/meloop_ui_showcase.dart';
import 'package:meloop/frontend/showcase/practice_preview_service.dart';
import 'package:meloop/frontend/showcase/session_form_example.dart';
import 'package:meloop/frontend/showcase/timer_example.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Android UC-04 creates, pauses, reviews and saves one session', (
    tester,
  ) async {
    var saveCalls = 0;
    final pending = Completer<void>();
    final service = PracticePreviewService(
      onSave: (_) {
        saveCalls++;
        return pending.future;
      },
    );
    await tester.pumpWidget(
      MeloopApp(
        practiceSessionService: service,
        overrides: [
          startupSnapshotProvider.overrideWithValue(StartupSnapshot.oneProfile),
        ],
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
    final create = find.byKey(const Key('create-practice-session'));
    expect(
      tester.getRect(create).bottom,
      lessThan(tester.getRect(find.byType(MeloopBottomNavigation)).top),
    );
    await tester.tap(create);
    await tester.pumpAndSettle();
    final title = find.byType(TextFormField);
    await tester.ensureVisible(title);
    await tester.tap(title);
    for (var attempt = 0; attempt < 16; attempt++) {
      if (tester.view.viewInsets.bottom > 0) break;
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(tester.view.viewInsets.bottom, greaterThan(0));
    await tester.enterText(title, 'Luyện gam trên Android');
    await tester.pumpAndSettle();
    Future<void> tapButton(String label) async {
      final button = find.widgetWithText(MeloopButton, label);
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
    }

    await tapButton('Bắt đầu luyện');
    expect(find.byType(TimerExample), findsOneWidget);
    final id = service.current.draft!.id;
    await tester.pump(const Duration(seconds: 2));
    await tapButton('Tạm dừng');
    final paused = service.current.draft!.elapsed;
    expect(paused.inSeconds, greaterThanOrEqualTo(1));
    await tester.pump(const Duration(seconds: 1));
    expect(service.current.draft!.elapsed, paused);
    await tapButton('Tiếp tục');
    await tester.pump(const Duration(seconds: 1));
    await tapButton('Kết thúc');
    expect(find.byType(SessionFormExample), findsOneWidget);
    expect(saveCalls, 0);
    final save = find.widgetWithText(MeloopButton, 'Lưu buổi luyện');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.tap(save);
    await tester.pump();
    expect(saveCalls, 1);
    pending.complete();
    await tester.pumpAndSettle();
    expect(service.current.draft, isNull);
    expect(service.current.sessions.single.id, id);
    expect(find.byType(SavedPracticePage), findsOneWidget);
    expect(find.widgetWithText(MeloopButton, 'Kết thúc'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    service.dispose();
  });
}
