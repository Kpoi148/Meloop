import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/app/meloop_app.dart';
import 'package:meloop/frontend/application/app_settings_controller.dart';
import 'package:meloop/frontend/showcase/setup_example.dart';
import 'package:meloop/shared/journal/journal_runtime.dart';
import 'package:meloop/shared/settings/app_settings_store.dart';

void main() {
  Future<void> open(
    WidgetTester tester,
    Future<void> Function(String, String) start,
  ) async {
    await tester.pumpWidget(
      MeloopApp(
        overrides: [
          appSettingsStoreProvider.overrideWithValue(
            InMemoryAppSettingsStore(),
          ),
        ],
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SetupExample(onJournalStart: start),
                ),
              ),
              child: const Text('Open setup'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open setup'));
    await tester.pumpAndSettle();
  }

  Future<void> start(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Bắt đầu luyện'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bắt đầu luyện'));
    await tester.pump();
  }

  testWidgets(
    'opening/back/invalid title create nothing; dirty Back keeps editing or discards',
    (tester) async {
      var calls = 0;
      await open(tester, (_, _) async {
        calls++;
      });
      await start(tester);
      await tester.pumpAndSettle();
      expect(calls, 0);
      await tester.enterText(find.byType(TextFormField), 'Working title');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiếp tục sửa'));
      await tester.pumpAndSettle();
      expect(find.text('Working title'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bỏ thay đổi'));
      await tester.pumpAndSettle();
      expect(find.byType(SetupExample), findsNothing);
      expect(calls, 0);
    },
  );
  testWidgets(
    'pending Start locks double tap/back; failure retains input and retry request identity',
    (tester) async {
      var pending = Completer<void>();
      final ids = <String>[];
      await open(tester, (id, title) {
        ids.add(id);
        expect(title, 'Retry title');
        return pending.future;
      });
      await tester.enterText(find.byType(TextFormField), 'Retry title');
      await start(tester);
      expect(ids, hasLength(1));
      expect(JournalId.isValid(ids.single), isTrue);
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byType(SetupExample), findsOneWidget);
      final buttons = find.byType(TextButton);
      // The Start button remains locked until the write resolves.
      expect(
        tester
            .widgetList<TextButton>(buttons)
            .where((b) => b.onPressed == null),
        isNotEmpty,
      );
      pending.completeError(StateError('injected'));
      await tester.pumpAndSettle();
      expect(find.text('Retry title'), findsOneWidget);
      pending = Completer<void>();
      await start(tester);
      expect(ids, hasLength(2));
      expect(ids[0], ids[1]);
      pending.complete();
      await tester.pumpAndSettle();
      expect(find.byType(SetupExample), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'disposed Setup does not navigate or set state after pending Start',
    (tester) async {
      final pending = Completer<void>();
      await open(tester, (_, _) => pending.future);
      await tester.enterText(find.byType(TextFormField), 'Pending title');
      await start(tester);
      await tester.pumpWidget(const SizedBox.shrink());
      pending.complete();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
