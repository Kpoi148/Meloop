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
    if (_disposed) return;
    _pending = input;
    if (_active == null) unawaited(_start());
  }

  Future<void> _start() {
    error = null;
    final completion = Completer<void>();
    _active = completion.future;
    unawaited(_run(completion));
    return completion.future;
  }

  Future<void> _run(Completer<void> completion) async {
    try {
      await _drain();
    } finally {
      _active = null;
      if (!_disposed) notifyListeners();
      // A completion listener may submit another snapshot. Do not strand it
      // behind the operation that has just finished, or start two writers.
      if (_active == null && _pending != null && error == null) {
        unawaited(_start());
      }
      completion.complete();
    }
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
  }

  Future<void> flush() async {
    while (_active != null || _pending != null) {
      if (_active == null) _start();
      await _active;
      if (error != null) throw error!;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
