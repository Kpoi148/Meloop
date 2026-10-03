import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/frontend/application/session_form_draft_controller.dart';
import 'package:meloop/shared/journal/journal_models.dart';

ReviewInput snapshot(String text) => ReviewInput(
  title: text,
  practiceDate: '2026-09-30',
  durationHoursInput: '',
  durationMinutesInput: '',
  durationSecondsInput: '1.5',
  practiced: 'Nháp\nchưa lưu',
  difficulty: '',
  next: '',
  mood: null,
  focus: null,
  bpmInput: 'bad',
);

void main() {
  test(
    'new input on autosave completion is persisted without another edit',
    () async {
      final stored = <String>[];
      final controller = SessionFormDraftController((input) async {
        stored.add(input.title);
      });
      addTearDown(controller.dispose);
      var changed = false;
      controller.addListener(() {
        if (!changed) {
          changed = true;
          controller.update(snapshot('Latest'));
        }
      });
      controller.update(snapshot('First'));
      await Future<void>.delayed(Duration.zero);
      expect(stored, ['First', 'Latest']);
    },
  );

  test('flush waits for the snapshot submitted on completion', () async {
    final gate = Completer<void>();
    final stored = <String>[];
    final controller = SessionFormDraftController((input) async {
      if (input.title == 'Latest') await gate.future;
      stored.add(input.title);
    });
    addTearDown(controller.dispose);
    var changed = false;
    controller.addListener(() {
      if (!changed) {
        changed = true;
        controller.update(snapshot('Latest'));
      }
    });
    controller.update(snapshot('First'));
    var finished = false;
    final flush = controller.flush().then((_) => finished = true);
    await Future<void>.delayed(Duration.zero);
    expect(finished, isFalse);
    gate.complete();
    await flush;
    expect(stored, ['First', 'Latest']);
  });

  test(
    'a failed write retains newest raw input and retry survives disposal',
    () async {
      final first = Completer<void>();
      ReviewInput? stored;
      var fail = true;
      final controller = SessionFormDraftController((input) async {
        if (fail) {
          await first.future;
          throw StateError('Injected');
        }
        stored = input;
      });
      controller.update(snapshot('First'));
      controller.update(snapshot('Latest'));
      first.complete();
      await expectLater(controller.flush(), throwsStateError);
      fail = false;
      final flush = controller.flush();
      controller.dispose();
      await flush;
      expect(stored!.title, 'Latest');
      expect(stored!.durationSecondsInput, '1.5');
      expect(stored!.bpmInput, 'bad');
    },
  );
}
