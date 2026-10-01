import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/app/meloop_app.dart';
import 'package:meloop/frontend/application/session_form_controller.dart';
import 'package:meloop/frontend/components/meloop_ui.dart';
import 'package:meloop/frontend/showcase/meloop_ui_showcase.dart';
import 'package:meloop/frontend/showcase/session_form_example.dart';
import 'package:meloop/frontend/showcase/showcase_controller.dart';

void main() {
  testWidgets(
    'component showcase wires preview failure and retry across routes',
    (tester) async {
      await tester.pumpWidget(
        MeloopApp(
          overrides: [
            sessionFormSaveProvider.overrideWith(
              (ref) => ref.read(showcaseSessionSaveProvider),
            ),
          ],
          home: const MeloopUiShowcase(),
        ),
      );
      await tester.pumpAndSettle();
      Finder tab(String label) => find.descendant(
        of: find.byType(MeloopBottomNavigation),
        matching: find.text(label),
      );
      await tester.tap(tab('Cài đặt'));
      await tester.pumpAndSettle();
      final failureToggle = find.descendant(
        of: find.widgetWithText(MeloopToggle, 'Mô phỏng lỗi ở lần lưu tiếp'),
        matching: find.byType(Switch),
      );
      await tester.ensureVisible(failureToggle);
      await tester.tap(failureToggle);
      await tester.pumpAndSettle();
      final open = find.widgetWithText(MeloopButton, 'Xem form lưu buổi luyện');
      await tester.ensureVisible(open);
      await tester.tap(open);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Luyện gam C');
      final save = find.widgetWithText(MeloopButton, 'Lưu buổi luyện');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.textContaining('Chưa thể lưu buổi luyện.'), findsOneWidget);
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.byType(SessionFormExample), findsNothing);
      expect(tester.widget<Switch>(failureToggle).value, isFalse);
      await tester.tap(tab('Buổi luyện'));
      await tester.pumpAndSettle();
      expect(find.textContaining('1 lần lưu mẫu hoàn tất.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'form uses app dependency and only navigates after successful retry',
    (tester) async {
      var calls = 0;
      SessionFormValues? received;
      var pending = Completer<void>();
      await tester.pumpWidget(
        MeloopApp(
          overrides: [
            sessionFormSaveProvider.overrideWithValue((values) {
              calls++;
              received = values;
              return pending.future;
            }),
          ],
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) =>
                        const SessionFormExample(initialTitle: 'Luyện gam C'),
                  ),
                ),
                child: const Text('Mở form'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Mở form'));
      await tester.pumpAndSettle();
      final save = find.widgetWithText(MeloopButton, 'Lưu buổi luyện');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.tap(save);
      await tester.pump();
      expect(calls, 1);
      expect(received!.title, 'Luyện gam C');
      expect(find.text('Đang lưu…'), findsOneWidget);
      expect(
        tester.widget<TextFormField>(find.byType(TextFormField).first).enabled,
        isFalse,
      );

      pending.completeError(StateError('Synthetic test failure'));
      await tester.pumpAndSettle();
      expect(find.byType(SessionFormExample), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).first)
            .controller!
            .text,
        'Luyện gam C',
      );
      expect(find.textContaining('Chưa thể lưu buổi luyện.'), findsOneWidget);
      pending = Completer<void>();
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pump();
      pending.complete();
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(find.byType(SessionFormExample), findsNothing);
      expect(find.text('Mở form'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('showcase retains history search across tab changes', (
    tester,
  ) async {
    await tester.pumpWidget(const MeloopApp(home: MeloopUiShowcase()));
    await tester.pumpAndSettle();
    Finder tab(String label) => find.descendant(
      of: find.byType(MeloopBottomNavigation),
      matching: find.text(label),
    );
    await tester.tap(tab('Buổi luyện'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'không tìm thấy');
    await tester.pumpAndSettle();
    expect(find.text('Không có buổi luyện phù hợp.'), findsOneWidget);
    // Dismiss the keyboard so the bottom navigation is visible again.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.tap(tab('Cài đặt'));
    await tester.pumpAndSettle();
    await tester.tap(tab('Buổi luyện'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'không tìm thấy',
    );
    await tester.tap(find.byTooltip('Xóa tìm kiếm'));
    await tester.pumpAndSettle();
    expect(find.text('Không có buổi luyện phù hợp.'), findsNothing);
    expect(find.text('Luyện gam C'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
