import 'dart:async';

import '../../shared/journal/journal_failure.dart';
import '../../shared/journal/journal_models.dart';
import '../../shared/journal/journal_text.dart';
import '../../shared/journal/practice_timer_service.dart';

class StopwatchMonotonicClock implements MonotonicClock {
  final Stopwatch _watch = Stopwatch()..start();
  @override
  int get elapsedMilliseconds => _watch.elapsedMilliseconds;
}

/// App-scoped engine. Render pulses never determine elapsed time. All storage
/// writes/commands are ordered, while Pause freezes time immediately.
class PracticeTimer implements PracticeTimerService {
  PracticeTimer({
    required this.store,
    required this.clock,
    required this.screenAwake,
    this.schedulePulses = true,
  });
  final PracticeTimerStore store;
  final MonotonicClock clock;
  final PracticeScreenAwake screenAwake;
  final bool schedulePulses;
  final _changes = StreamController<PracticeTimerSnapshot>.broadcast(
    sync: true,
  );
  Future<void> _tail = Future.value();
  Timer? _ticker;
  String? _sessionId, _profileId;
  PracticeState _state = PracticeState.paused;
  int _base = 0, _persisted = 0;
  int? _anchor;
  int _pending = 0;
  int _runGeneration = 0;
  bool _failed = false, _foreground = true, _closed = false;
  Future<void>? _closing;

  int get _elapsed =>
      (_base + (_anchor == null ? 0 : clock.elapsedMilliseconds - _anchor!))
          .clamp(0, PracticeRules.maximumDuration.inMilliseconds);
  @override
  PracticeTimerSnapshot? get snapshot => _sessionId == null
      ? null
      : PracticeTimerSnapshot(
          sessionId: _sessionId!,
          profileId: _profileId!,
          state: _state,
          elapsedMilliseconds: _elapsed,
          persistedMilliseconds: _persisted,
          busy: _pending > 0,
          failed: _failed,
        );
  @override
  Stream<PracticeTimerSnapshot> get changes => _changes.stream;
  void _emit() {
    final current = snapshot;
    if (current != null && !_changes.isClosed) _changes.add(current);
  }

  void _freeze({PracticeState state = PracticeState.paused}) {
    _base = _elapsed;
    _anchor = null;
    if (_state != PracticeState.review) _state = state;
    _emit();
  }

  Future<void> _enqueue(Future<void> Function() action) {
    if (_closed || _closing != null) {
      return Future.error(const JournalFailure(JournalFailureCode.closed));
    }
    _pending++;
    _emit();
    final result = _tail.then((_) async {
      try {
        await action();
      } catch (_) {
        _freeze();
        _failed = true;
        // Disable independently of the failed command; the port serializes its
        // platform calls, so an earlier enable cannot win after this disable.
        unawaited(screenAwake.setEnabled(false).catchError((Object _) {}));
        rethrow;
      } finally {
        _pending--;
        _emit();
      }
    });
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<void> _persist() async {
    final result = await store.checkpoint(
      sessionId: _sessionId!,
      profileId: _profileId!,
      accumulatedMilliseconds: _elapsed,
      state: _state,
    );
    _persisted = result.accumulatedMilliseconds;
  }

  @override
  Future<void> open(PracticeDraft draft, {bool newlyStarted = false}) =>
      _enqueue(() async {
        final generation = _runGeneration;
        if (_sessionId == draft.session.id) {
          return; // Keep newer in-memory values after a failed checkpoint.
        }
        if (_sessionId != null || draft.session.state == PracticeState.saved) {
          throw const JournalFailure(JournalFailureCode.invalidInput);
        }
        _sessionId = draft.session.id;
        _profileId = draft.session.profileId;
        _base = _persisted = draft.accumulatedMilliseconds;
        if (schedulePulses && _ticker == null) {
          _ticker = Timer.periodic(
            PracticeRules.timerRefreshInterval,
            (_) => unawaited(pulse().catchError((Object _) {})),
          );
        }
        _state = draft.session.state == PracticeState.review
            ? PracticeState.review
            : PracticeState.paused;
        if (_state != PracticeState.review) {
          if (newlyStarted &&
              _foreground &&
              _base < PracticeRules.maximumDuration.inMilliseconds) {
            _state = PracticeState.running;
          } else if (_base == PracticeRules.maximumDuration.inMilliseconds) {
            _state = PracticeState.review;
          }
          await _persist();
        }
        await screenAwake.setEnabled(
          _state == PracticeState.running && _foreground,
        );
        if (_state == PracticeState.running &&
            _foreground &&
            generation == _runGeneration) {
          _anchor = clock.elapsedMilliseconds;
        } else if (_state == PracticeState.running) {
          _freeze();
          await _persist();
        }
      });
  @override
  Future<void> pause() {
    if (_sessionId == null || _closed) return Future.value();
    _runGeneration++;
    _freeze();
    return _enqueue(() async {
      await screenAwake.setEnabled(false);
      if (!_failed) await _persist();
    });
  }

  @override
  Future<void> resume() {
    final generation = _runGeneration;
    return _enqueue(() async {
      if (_sessionId == null ||
          _failed ||
          !_foreground ||
          _state == PracticeState.review ||
          generation != _runGeneration) {
        return;
      }
      if (_state == PracticeState.running) return;
      if (_base >= PracticeRules.maximumDuration.inMilliseconds) {
        _state = PracticeState.review;
        await _persist();
        return;
      }
      _state = PracticeState.running;
      await _persist();
      await screenAwake.setEnabled(_foreground);
      if (_foreground && generation == _runGeneration) {
        _anchor = clock.elapsedMilliseconds;
      } else {
        _freeze();
        await _persist();
      }
    });
  }

  @override
  Future<void> retry() => _enqueue(() async {
    if (_sessionId == null) return;
    _freeze();
    await screenAwake.setEnabled(false);
    await _persist();
    _failed = false;
  });
  @override
  Future<void> finish() {
    if (_sessionId == null || _failed) {
      return Future.error(
        const JournalFailure(JournalFailureCode.invalidInput),
      );
    }
    _runGeneration++;
    _freeze(state: PracticeState.review);
    return _enqueue(() async {
      await screenAwake.setEnabled(false);
      await _persist();
    });
  }

  @override
  Future<void> leaveReview() => _enqueue(() async {
    if (_sessionId == null || _failed) return;
    _state = PracticeState.paused;
    await _persist();
  });

  @override
  Future<void> complete(String sessionId) => _enqueue(() async {
    if (_sessionId != sessionId || _state != PracticeState.review) {
      throw const JournalFailure(JournalFailureCode.invalidInput);
    }
    _state = PracticeState.saved;
    _anchor = null;
    _emit();
    _ticker?.cancel();
    _ticker = null;
    _sessionId = _profileId = null;
    _base = _persisted = 0;
    _failed = false;
  });
  @override
  void setForeground(bool foreground) {
    _foreground = foreground;
    if (!foreground) unawaited(pause().catchError((Object _) {}));
  }

  /// Public for deterministic tests; scheduling may skip pulses without losing time.
  Future<void> pulse() {
    if (_closed || _sessionId == null || _anchor == null) return Future.value();
    _emit();
    if (_elapsed >= PracticeRules.maximumDuration.inMilliseconds) {
      _freeze(state: PracticeState.review);
      return _enqueue(() async {
        await screenAwake.setEnabled(false);
        await _persist();
      });
    }
    if (!_failed &&
        _pending == 0 &&
        _elapsed - _persisted >=
            PracticeRules.checkpointInterval.inMilliseconds) {
      return _enqueue(_persist);
    }
    return Future.value();
  }

  @override
  Future<void> close() => _closing ??= () async {
    _foreground = false;
    _runGeneration++;
    _freeze();
    _ticker?.cancel();
    await _tail;
    _freeze();
    _ticker?.cancel();
    try {
      await screenAwake.setEnabled(false);
      if (_sessionId != null && !_failed) await _persist();
    } catch (_) {
      _failed = true;
      _emit();
    }
    _closed = true;
    await _changes.close();
  }();
}
