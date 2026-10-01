import 'package:flutter/services.dart';

import '../../shared/journal/practice_timer_service.dart';

class AndroidPracticeScreenAwake implements PracticeScreenAwake {
  static const _channel = MethodChannel('meloop/practice_screen_awake');
  Future<void> _tail = Future.value();
  @override
  Future<void> setEnabled(bool enabled) {
    final result = _tail.then(
      (_) => _channel.invokeMethod<void>('setEnabled', enabled),
    );
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }
}
