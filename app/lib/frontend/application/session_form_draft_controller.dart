import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../shared/journal/journal_models.dart';

typedef SessionFormPersistInput = Future<void> Function(ReviewInput input);

/// Serializes snapshots and retains the latest raw input after a write failure.
/// Navigation and Save wait for flush so no late draft write races a commit.
class SessionFormDraftController extends ChangeNotifier {
  SessionFormDraftController(this.persist);
  final SessionFormPersistInput persist;
  ReviewInput? _pending;
  Future<void>? _active;
  Object? error;
  bool _disposed = false;

  void update(ReviewInput input) {
    _pending = input;
    if (_active == null) unawaited(_start());
  }

  Future<void> _start() {
    error = null;
    return _active = _drain().whenComplete(() => _active = null);
  }

  Future<void> _drain() async {
    while (_pending != null) {
      final input = _pending!;
      _pending = null;
      try {
        await persist(input);
      } catch (failure) {
        _pending ??= input;
        error = failure;
        break;
      }
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> flush() async {
    if (_active == null && _pending != null) _start();
    await _active;
    if (error != null) throw error!;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
