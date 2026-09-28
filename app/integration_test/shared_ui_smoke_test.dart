import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meloop/app/meloop_app.dart';
import 'package:meloop/frontend/components/meloop_ui.dart';
import 'package:meloop/frontend/showcase/session_form_example.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Android keyboard, inline validation and guarded save retry', (
    tester,
  ) async {
    var calls = 0;
    var pending = Completer<void>();
    await tester.pumpWidget(
      MeloopApp(
        home: Builder(
          builder: (context) => MeloopPage(
            child: MeloopButton(
              label: 'Mở form mẫu',
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => SessionFormExample(
                    onSave: (_) {
                      calls++;
                      return pending.future;
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mở form mẫu'));
    await tester.pumpAndSettle();

    final save = find.widgetWithText(MeloopButton, 'Lưu buổi luyện');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(calls, 0);
    expect(find.text('Vui lòng nhập tên buổi luyện.'), findsOneWidget);

    final title = find.byType(TextFormField).first;
    await tester.ensureVisible(title);
    await tester.tap(title);
    // Integration binding uses the platform IME, rather than mock view insets.
    for (var attempt = 0; attempt < 16; attempt++) {
      if (tester.view.viewInsets.bottom > 0) break;
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(tester.view.viewInsets.bottom, greaterThan(0));
    await tester.enterText(title, 'Luyện gam C');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.tap(save);
    expect(calls, 1);
    await tester.pump();
    expect(find.text('Đang lưu…'), findsOneWidget);
    pending.completeError(StateError('Synthetic Android test failure'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Chưa thể lưu buổi luyện. Nội dung của bạn vẫn ở đây. Vui lòng thử lại.',
      ),
      findsOneWidget,
    );
    expect(tester.widget<TextFormField>(title).controller!.text, 'Luyện gam C');
    expect(tester.takeException(), isNull);

    pending = Completer<void>();
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.tap(save);
    expect(calls, 2);
    pending.complete();
    await tester.pumpAndSettle();
    expect(find.text('Mở form mẫu'), findsOneWidget);
    expect(find.byType(SessionFormExample), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
