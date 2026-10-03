import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/app/meloop_app.dart';
import 'package:meloop/frontend/application/app_settings_controller.dart';
import 'package:meloop/frontend/components/meloop_ui.dart';
import 'package:meloop/frontend/showcase/session_form_example.dart';
import 'package:meloop/shared/settings/app_settings_store.dart';

Future<void> _open(
  WidgetTester tester, {
  required int durationSeconds,
  required SessionFormSave onSave,
  bool editing = false,
}) async {
  await tester.pumpWidget(
    MeloopApp(
      overrides: [
        appSettingsStoreProvider.overrideWithValue(
          InMemoryAppSettingsStore(languageCode: 'vi'),
        ),
      ],
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => SessionFormExample(
                  editing: editing,
                  initialTitle: 'Luyện gam C',
                  initialDurationSeconds: durationSeconds,
                  onSave: onSave,
                ),
              ),
            ),
            child: const Text('Mở nhật ký'),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Mở nhật ký'));
  await tester.pumpAndSettle();
}

Finder _durationField() => find.byKey(const Key('session-duration-minutes'));

Future<void> _save(WidgetTester tester, {bool editing = false}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump();
  await tester.tap(
    find.widgetWithText(
      MeloopButton,
      editing ? 'Lưu thay đổi' : 'Lưu buổi luyện',
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final (seconds, minutes) in [(5, 0), (90, 1), (3720, 2)]) {
    testWidgets(
      'new session keeps $seconds measured seconds in hour/minute/second inputs',
      (tester) async {
        SessionFormValues? saved;
        await _open(
          tester,
          durationSeconds: seconds,
          onSave: (values) async => saved = values,
        );
        expect(find.text('Thời lượng *'), findsOneWidget);
        expect(find.text('Giờ *'), findsOneWidget);
        expect(find.text('Giây *'), findsOneWidget);
        expect(
          tester.widget<TextFormField>(_durationField()).controller!.text,
          '$minutes',
        );
        await _save(tester);
        expect(saved?.durationSeconds, seconds);
        expect(find.byType(SessionFormExample), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('invalid duration components cannot be submitted', (
    tester,
  ) async {
    final saved = <SessionFormValues>[];
    await _open(
      tester,
      durationSeconds: 60,
      onSave: (values) async => saved.add(values),
    );
    for (final invalid in ['-1', '60']) {
      await tester.ensureVisible(_durationField());
      await tester.enterText(_durationField(), invalid);
      await _save(tester);
      expect(saved, isEmpty);
      expect(find.byType(SessionFormExample), findsOneWidget);
    }
    await tester.enterText(_durationField(), '0');
    await tester.enterText(
      find.byKey(const Key('session-duration-hours')),
      '24',
    );
    await _save(tester);
    expect(saved.single.durationSeconds, 86400);
    expect(tester.takeException(), isNull);
  });

  for (final changed in [false, true]) {
    testWidgets('edit changes minutes independently of seconds: $changed', (
      tester,
    ) async {
      SessionFormValues? saved;
      await _open(
        tester,
        editing: true,
        durationSeconds: 99,
        onSave: (values) async => saved = values,
      );
      if (changed) await tester.enterText(_durationField(), '2');
      await _save(tester, editing: true);
      expect(saved?.durationSeconds, changed ? 159 : 99);
      expect(tester.takeException(), isNull);
    });
  }
}
