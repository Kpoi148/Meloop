import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/backend/journal/practice_screen_awake.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('meloop/practice_screen_awake');
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );
  test('platform awake calls remain ordered when enabling is slow', () async {
    final gate = Completer<void>();
    final entered = Completer<void>();
    final values = <bool>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'setEnabled');
          values.add(call.arguments as bool);
          if (call.arguments == true) {
            entered.complete();
            await gate.future;
          }
          return null;
        });
    final awake = AndroidPracticeScreenAwake();
    final enable = awake.setEnabled(true);
    await entered.future;
    final disable = awake.setEnabled(false);
    expect(values, [true]);
    gate.complete();
    await enable;
    await disable;
    expect(values, [true, false]);
  });
  test('a failed platform call does not poison later disable/retry', () async {
    var calls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (++calls == 1) throw PlatformException(code: 'injected');
          expect(call.arguments, false);
          return null;
        });
    final awake = AndroidPracticeScreenAwake();
    await expectLater(
      awake.setEnabled(true),
      throwsA(isA<PlatformException>()),
    );
    await awake.setEnabled(false);
    expect(calls, 2);
  });
}
