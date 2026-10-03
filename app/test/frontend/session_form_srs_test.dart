import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/app/meloop_app.dart';
import 'package:meloop/frontend/application/app_settings_controller.dart';
import 'package:meloop/frontend/application/session_form_draft_controller.dart';
import 'package:meloop/frontend/components/meloop_ui.dart';
import 'package:meloop/frontend/showcase/session_form_example.dart';
import 'package:meloop/shared/journal/journal_models.dart';
import 'package:meloop/shared/settings/app_settings_store.dart';

Future<void> openForm(
  WidgetTester tester, {
  required SessionFormSave save,
  int seconds = 5,
  bool editing = false,
  SessionFormPersistInput? persist,
  ReviewInput? raw,
  int? initialBpm,
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
                  initialTitle: raw?.title ?? 'Luyện gam C',
                  initialDurationSeconds: seconds,
                  initialReviewInput: raw,
                  initialValues: initialBpm == null
                      ? null
                      : SessionFormValues(
                          title: 'Luyện gam C',
                          date: DateTime(2026, 9, 30),
                          durationSeconds: seconds,
                          practiced: '',
                          difficulty: '',
                          next: '',
                          bpm: initialBpm,
                        ),
                  instrumentName: 'Guitar QA',
                  onPersistInput: persist,
                  onSave: save,
                ),
              ),
            ),
            child: const Text('Mở form'),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Mở form'));
  await tester.pumpAndSettle();
}

Finder duration(String part) => find.byKey(Key('session-duration-$part'));
Finder notes(String hint) => find.ancestor(
  of: find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.hintText == hint,
  ),
  matching: find.byType(TextFormField),
);
Future<void> submit(WidgetTester tester, {bool editing = false}) async {
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
  for (final clearBpm in [false, true]) {
    testWidgets(
      'legacy Review retains session BPM, explicit clearing yields null: $clearBpm',
      (tester) async {
        SessionFormValues? saved;
        await openForm(
          tester,
          initialBpm: 80,
          save: (value) async => saved = value,
          raw: ReviewInput(
            title: 'Luyện gam C',
            practiceDate: '2026-09-30',
            durationHoursInput: '0',
            durationMinutesInput: '0',
            durationSecondsInput: '5',
            practiced: '',
            difficulty: '',
            next: '',
            mood: null,
            focus: null,
            bpmInput: clearBpm ? '' : null,
          ),
        );
        await submit(tester);
        expect(saved!.bpm, clearBpm ? isNull : 80);
      },
    );
  }
  for (final editing in [false, true]) {
    testWidgets(
      'SRS duration rejects zero, decimals, negatives and values above 24h (edit: $editing)',
      (tester) async {
        final saved = <SessionFormValues>[];
        await openForm(
          tester,
          save: (value) async => saved.add(value),
          seconds: 0,
          editing: editing,
        );
        await submit(tester, editing: editing);
        expect(saved, isEmpty);
        expect(
          find.text('Thời lượng phải từ 1 giây đến 24 giờ.'),
          findsOneWidget,
        );
        for (final (part, value) in [
          ('seconds', '1.5'),
          ('seconds', '-1'),
          ('seconds', '60'),
          ('seconds', ''),
          ('hours', '25'),
        ]) {
          await tester.ensureVisible(duration(part));
          await tester.enterText(duration(part), value);
          await submit(tester, editing: editing);
          expect(saved, isEmpty);
          expect(
            tester.widget<TextFormField>(duration(part)).controller!.text,
            value,
          );
        }
        await tester.enterText(duration('hours'), '24');
        await tester.enterText(duration('seconds'), '1');
        await submit(tester, editing: editing);
        expect(saved, isEmpty);
        await tester.enterText(duration('seconds'), '0');
        await submit(tester, editing: editing);
        expect(saved.single.durationSeconds, 86400);
        expect(saved.single.mood, isNull);
        expect(saved.single.focus, isNull);
      },
    );
  }

  testWidgets(
    'optional labels, code-point limits and multiline notes follow SRS',
    (tester) async {
      SessionFormValues? saved;
      await openForm(tester, save: (value) async => saved = value);
      expect(find.text('Tên buổi luyện *'), findsOneWidget);
      expect(find.text('Nhạc cụ: Guitar QA'), findsOneWidget);
      for (final label in [
        'Bạn đã luyện gì?',
        'Điều còn vướng',
        'Cho lần luyện tiếp',
      ]) {
        expect(find.text('$label (không bắt buộc)'), findsOneWidget);
      }
      final title = find.byType(TextFormField).first;
      await tester.enterText(title, List.filled(101, '😀').join());
      await submit(tester);
      expect(saved, isNull);
      expect(
        tester.widget<TextFormField>(title).controller!.text.runes.length,
        101,
      );
      await tester.ensureVisible(title);
      await tester.enterText(title, List.filled(100, '😀').join());
      final practiced = notes('Gam, hợp âm, bài nhạc…');
      expect(
        tester
            .widget<TextField>(
              find.descendant(of: practiced, matching: find.byType(TextField)),
            )
            .keyboardType,
        TextInputType.multiline,
      );
      await tester.ensureVisible(practiced);
      await tester.enterText(practiced, List.filled(2001, '😀').join());
      await submit(tester);
      expect(saved, isNull);
      await tester.ensureVisible(practiced);
      await tester.enterText(practiced, 'Dòng một\nDòng hai');
      await submit(tester);
      expect(saved!.title.runes.length, 100);
      expect(saved!.practiced, 'Dòng một\nDòng hai');
      expect(saved!.difficulty, isEmpty);
      expect(saved!.next, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('selecting an active mood or focus clears it to null', (
    tester,
  ) async {
    SessionFormValues? saved;
    await openForm(tester, save: (value) async => saved = value);
    for (var index = 0; index < 2; index++) {
      final rating = find.byType(MeloopRating).at(index);
      final choice = find
          .descendant(of: rating, matching: find.byType(InkWell))
          .at(3);
      await tester.ensureVisible(choice);
      await tester.tap(choice);
      await tester.pump();
      await tester.tap(choice);
      await tester.pump();
    }
    await submit(tester);
    expect(saved!.mood, isNull);
    expect(saved!.focus, isNull);
  });

  testWidgets(
    'Android Back protects edits; keep editing retains input and discard leaves original',
    (tester) async {
      var saves = 0;
      await openForm(tester, save: (_) async => saves++, editing: true);
      await tester.enterText(find.byType(TextFormField).first, 'Chưa lưu');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiếp tục sửa'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).first)
            .controller!
            .text,
        'Chưa lưu',
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bỏ thay đổi'));
      await tester.pumpAndSettle();
      expect(find.byType(SessionFormExample), findsNothing);
      expect(saves, 0);
    },
  );

  testWidgets(
    'draft write failure blocks Back; retry retains invalid duration and raw notes',
    (tester) async {
      ReviewInput? persisted;
      var fail = true;
      final pending = Completer<void>();
      await openForm(
        tester,
        save: (_) async {},
        persist: (input) async {
          await pending.future;
          if (fail) throw StateError('Synthetic write failure');
          persisted = input;
        },
      );
      await tester.ensureVisible(duration('seconds'));
      await tester.enterText(duration('seconds'), '1.5');
      final practiced = notes('Gam, hợp âm, bài nhạc…');
      await tester.ensureVisible(practiced);
      await tester.enterText(practiced, 'Nháp\nchưa lưu');
      pending.complete();
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Quay lại buổi luyện').last);
      await tester.pumpAndSettle();
      expect(find.byType(SessionFormExample), findsOneWidget);
      expect(persisted, isNull);
      fail = false;
      await tester.ensureVisible(find.widgetWithText(MeloopButton, 'Thử lại'));
      await tester.tap(find.widgetWithText(MeloopButton, 'Thử lại'));
      await tester.pumpAndSettle();
      expect(persisted!.durationSecondsInput, '1.5');
      expect(persisted!.practiced, 'Nháp\nchưa lưu');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Quay lại buổi luyện').last);
      await tester.pumpAndSettle();
      expect(find.byType(SessionFormExample), findsNothing);
      await openForm(tester, save: (_) async {}, raw: persisted);
      expect(
        tester.widget<TextFormField>(duration('seconds')).controller!.text,
        '1.5',
      );
      expect(tester.takeException(), isNull);
    },
  );
}
