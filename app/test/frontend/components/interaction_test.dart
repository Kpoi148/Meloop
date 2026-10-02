import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/app/meloop_app.dart';
import 'package:meloop/frontend/components/meloop_ui.dart';
import 'package:meloop/frontend/showcase/session_form_example.dart';

void main() {
  testWidgets(
    'Tempo rating clears to null when the active face is tapped again',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final values = <int?>[];
      await tester.pumpWidget(
        MeloopApp(
          home: MeloopPage(
            child: MeloopRating(label: 'Cảm xúc', onChanged: values.add),
          ),
        ),
      );
      final rating = find.bySemanticsLabel('Cảm xúc 2 trên 5');
      await tester.tap(rating);
      await tester.pump();
      await tester.tap(rating);
      await tester.pump();
      expect(values, [2, null]);
      semantics.dispose();
    },
  );
  testWidgets(
    'button locks immediately, awaits completion and releases after error',
    (tester) async {
      final pending = Completer<void>();
      var calls = 0, errors = 0;
      await tester.pumpWidget(
        MeloopApp(
          home: MeloopPage(
            child: MeloopButton(
              label: 'Lưu',
              onPressed: () {
                calls++;
                return pending.future;
              },
              onError: (_, _) {
                errors++;
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('Lưu'));
      await tester.tap(find.text('Lưu'));
      expect(calls, 1);
      await tester.pump();
      expect(find.text('Đang lưu…'), findsOneWidget);
      pending.completeError(StateError('Synthetic failure'));
      await tester.pumpAndSettle();
      expect(errors, 1);
      expect(find.text('Lưu'), findsOneWidget);
    },
  );

  testWidgets(
    'required and optional fields show inline validation with the proper keyboard',
    (tester) async {
      final form = GlobalKey<FormState>();
      final title = TextEditingController(),
          note = TextEditingController(),
          bpm = TextEditingController(text: '40.5');
      addTearDown(() {
        title.dispose();
        note.dispose();
        bpm.dispose();
      });
      await tester.pumpWidget(
        MeloopApp(
          home: MeloopPage(
            child: Form(
              key: form,
              child: Column(
                children: [
                  MeloopField(
                    label: 'Tên buổi luyện',
                    controller: title,
                    requirement: MeloopFieldRequirement.required,
                    validator: MeloopValidation.title,
                  ),
                  MeloopField(
                    label: 'Ghi chú',
                    controller: note,
                    type: MeloopInputType.multiline,
                    validator: MeloopValidation.note,
                  ),
                  MeloopField(
                    label: 'BPM',
                    controller: bpm,
                    type: MeloopInputType.integer,
                    validator: (v) => MeloopValidation.integer(
                      v,
                      label: 'BPM',
                      min: 40,
                      max: 240,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(form.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Vui lòng nhập tên buổi luyện.'), findsOneWidget);
      expect(find.text('BPM phải là số nguyên.'), findsOneWidget);
      final inputs = tester
          .widgetList<TextField>(find.byType(TextField))
          .toList();
      expect(inputs[1].keyboardType, TextInputType.multiline);
      expect(inputs[2].keyboardType, TextInputType.number);
      title.text = 'Luyện gam C';
      bpm.text = '80';
      expect(form.currentState!.validate(), isTrue);
    },
  );

  testWidgets(
    'required selection validates and optional active rating can be cleared',
    (tester) async {
      final form = GlobalKey<FormState>();
      final values = <int?>[];
      await tester.pumpWidget(
        MeloopApp(
          home: MeloopPage(
            child: Form(
              key: form,
              child: Column(
                children: [
                  MeloopChoiceGroup<int>(
                    label: 'Nhạc cụ',
                    requirement: MeloopFieldRequirement.required,
                    choices: const [MeloopChoice(value: 1, label: 'Guitar')],
                    onChanged: (_) {},
                  ),
                  MeloopChoiceGroup<int>(
                    label: 'Cảm xúc',
                    clearable: true,
                    choices: const [MeloopChoice(value: 2, label: '2 / 5')],
                    onChanged: values.add,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(form.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Vui lòng chọn nhạc cụ.'), findsOneWidget);
      await tester.tap(find.text('Guitar'));
      await tester.pump();
      expect(form.currentState!.validate(), isTrue);
      await tester.tap(find.text('2 / 5'));
      await tester.pump();
      await tester.tap(find.text('2 / 5'));
      await tester.pump();
      expect(values, [2, null]);
    },
  );

  testWidgets('search clear updates both controller and consumer', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'Gam C');
    addTearDown(controller.dispose);
    var query = controller.text;
    await tester.pumpWidget(
      MeloopApp(
        home: MeloopPage(
          child: MeloopSearch(
            controller: controller,
            onChanged: (v) => query = v,
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Xóa tìm kiếm'));
    await tester.pump();
    expect(controller.text, isEmpty);
    expect(query, isEmpty);
    expect(find.byTooltip('Xóa tìm kiếm'), findsNothing);
  });

  testWidgets(
    'failed session save retains inputs, blocks duplicate save and permits retry',
    (tester) async {
      var calls = 0;
      final pending = Completer<void>();
      await tester.pumpWidget(
        MeloopApp(
          home: SessionFormExample(
            initialTitle: 'Luyện gam C',
            onSave: (_) {
              calls++;
              return pending.future;
            },
          ),
        ),
      );
      final notes = find.ancestor(
        of: find.byWidgetPredicate(
          (widget) =>
              widget is TextField &&
              widget.decoration?.hintText == 'Gam, hợp âm, bài nhạc…',
        ),
        matching: find.byType(TextFormField),
      );
      await tester.ensureVisible(notes);
      await tester.enterText(notes, 'Giữ nguyên ghi chú này');
      final save = find.widgetWithText(MeloopButton, 'Lưu buổi luyện');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.tap(save);
      expect(calls, 1);
      await tester.pump();
      expect(find.text('Đang lưu…'), findsOneWidget);
      pending.completeError(StateError('Synthetic failure'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Chưa thể lưu buổi luyện. Nội dung của bạn vẫn ở đây. Vui lòng thử lại.',
        ),
        findsOneWidget,
      );
      final fields = tester
          .widgetList<TextFormField>(find.byType(TextFormField))
          .toList();
      expect(fields[0].controller!.text, 'Luyện gam C');
      expect(
        tester.widget<TextFormField>(notes).controller!.text,
        'Giữ nguyên ghi chú này',
      );
      expect(
        tester
            .widget<TextButton>(
              find.descendant(of: save, matching: find.byType(TextButton)),
            )
            .onPressed,
        isNotNull,
      );
    },
  );

  testWidgets(
    'confirmation stays open after failure and prevents repeated work',
    (tester) async {
      var calls = 0;
      final pending = Completer<void>();
      await tester.pumpWidget(
        MeloopApp(
          home: Builder(
            builder: (context) => MeloopPage(
              child: MeloopButton(
                label: 'Mở',
                onPressed: () async {
                  await showMeloopConfirm(
                    context,
                    title: 'Xóa buổi luyện?',
                    message: 'Các bản ghi âm cũng sẽ bị xóa.',
                    confirmLabel: 'Xóa',
                    onConfirm: () {
                      calls++;
                      return pending.future;
                    },
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Mở'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Xóa'));
      await tester.tap(find.text('Xóa'));
      expect(calls, 1);
      await tester.pump();
      pending.completeError(StateError('Synthetic failure'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Chưa thể hoàn tất. Vui lòng thử lại.'), findsOneWidget);
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
    },
  );
}
