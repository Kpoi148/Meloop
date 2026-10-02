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

Finder _durationField() => find.ancestor(
  of: find.byWidgetPredicate(
    (widget) =>
        widget is TextField &&
        widget.keyboardType == TextInputType.number &&
        widget.decoration?.hintText == null,
  ),
  matching: find.byType(TextFormField),
);

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
  for (final (seconds, minutes) in [(5, 1), (90, 2), (3720, 62)]) {
    testWidgets(
      'new session displays $seconds seconds as $minutes total minutes',
      (tester) async {
        SessionFormValues? saved;
        await _open(
          tester,
          durationSeconds: seconds,
          onSave: (values) async => saved = values,
        );
        expect(find.text('Thời lượng (phút) *'), findsOneWidget);
        expect(find.text('Giờ *'), findsNothing);
        expect(find.text('Giây *'), findsNothing);
        expect(
          tester.widget<TextFormField>(_durationField()).controller!.text,
          '$minutes',
        );
        await _save(tester);
        expect(saved?.durationSeconds, minutes * Duration.secondsPerMinute);
        expect(find.byType(SessionFormExample), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('minutes outside the prototype range cannot be submitted', (
    tester,
  ) async {
    final saved = <SessionFormValues>[];
    await _open(
      tester,
      durationSeconds: 60,
      onSave: (values) async => saved.add(values),
    );
    for (final invalid in ['0', '1441']) {
      await tester.ensureVisible(_durationField());
      await tester.enterText(_durationField(), invalid);
      await _save(tester);
      expect(saved, isEmpty);
      expect(find.byType(SessionFormExample), findsOneWidget);
    }
    await tester.enterText(_durationField(), '1440');
    await _save(tester);
    expect(saved.single.durationSeconds, 86400);
    expect(tester.takeException(), isNull);
  });

  for (final changed in [false, true]) {
    testWidgets(
      'edit preserves seconds only while duration is unchanged: $changed',
      (tester) async {
        SessionFormValues? saved;
        await _open(
          tester,
          editing: true,
          durationSeconds: 99,
          onSave: (values) async => saved = values,
        );
        if (changed) await tester.enterText(_durationField(), '2');
        await _save(tester, editing: true);
        expect(saved?.durationSeconds, changed ? 120 : 99);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
