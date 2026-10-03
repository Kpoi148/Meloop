import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../shared/pitch/pitch_service.dart';

/// Owns a route's listening lifecycle, but no pitch detection or journal data.
class PitchController extends ChangeNotifier {
  PitchController(this.service)
    : _snapshot = PitchSnapshot(
        configuration:
            service?.snapshot.configuration ?? PitchConfiguration.standard,
      ) {
    _subscription = service?.changes.listen(
      _receive,
      onError: (Object error, StackTrace stack) {
        if (_acceptUpdates) {
          unawaited(
            stop().then((_) {
              if (!_disposed && _snapshot.phase != PitchPhase.stopFailed) {
                _set(_snapshot.withPhase(PitchPhase.failed));
              }
            }),
          );
        }
      },
      onDone: () {
        if (_acceptUpdates) unawaited(stop());
      },
    );
  }

  final PitchService? service;
  late PitchSnapshot _snapshot;
  StreamSubscription<PitchSnapshot>? _subscription;
  Future<void>? _pendingStart, _pendingStop;
  int _revision = 0;
  bool _acceptUpdates = false, _disposed = false, _settingsBusy = false;
  bool _settingsFailed = false;

  PitchSnapshot get snapshot => _snapshot;
  bool get stopping => _pendingStop != null;
  bool get settingsBusy => _settingsBusy;
  bool get settingsFailed => _settingsFailed;

  void _set(PitchSnapshot next) {
    _snapshot = next;
    if (_disposed) return;
    notifyListeners();
  }

  void _receive(PitchSnapshot next) {
    if (!_acceptUpdates || _disposed) return;
    _set(
      next.phase == PitchPhase.detected && next.reading == null
          ? next.withPhase(PitchPhase.weakSignal)
          : next,
    );
  }

  Future<void> toggle() =>
      _snapshot.listening || _snapshot.phase == PitchPhase.stopFailed
      ? stop()
      : start();

  Future<void> start() async {
    if (_disposed || _pendingStart != null || stopping || _snapshot.listening) {
      return;
    }
    final port = service;
    if (port == null) {
      _set(_snapshot.withPhase(PitchPhase.unavailable));
      return;
    }
    final revision = ++_revision;
    _acceptUpdates = true;
    _settingsFailed = false;
    _set(_snapshot.withPhase(PitchPhase.requestingPermission));
    final operation = Future<void>.sync(port.start);
    _pendingStart = operation;
    try {
      await operation;
      if (!_disposed && revision == _revision) _receive(port.snapshot);
    } catch (_) {
      if (!_disposed && revision == _revision) {
        await stop();
        if (!_disposed && _snapshot.phase != PitchPhase.stopFailed) {
          _set(_snapshot.withPhase(PitchPhase.failed));
        }
      }
    } finally {
      if (identical(_pendingStart, operation)) _pendingStart = null;
    }
  }

  Future<void> stop() {
    if (_pendingStop != null) return _pendingStop!;
    ++_revision;
    _acceptUpdates = false;
    _set(_snapshot.withPhase(PitchPhase.idle));
    final operation = _release();
    _pendingStop = operation;
    return operation.whenComplete(() {
      _pendingStop = null;
      if (!_disposed) notifyListeners();
    });
  }

  Future<void> _release() async {
    final port = service;
    if (port == null) return;
    final pending = _pendingStart;
    var failed = false;
    try {
      await port.stop();
    } catch (_) {
      failed = true;
    }
    // Stop again if a start request was already in flight when the user left.
    // This also protects adapters whose permission callback resolves late.
    if (pending != null) {
      try {
        await pending;
      } catch (_) {
        // The start command reports its own failure; release still must run.
      }
      try {
        await port.stop();
        failed = false;
      } catch (_) {
        failed = true;
      }
    }
    if (failed) _set(_snapshot.withPhase(PitchPhase.stopFailed));
  }

  Future<void> openSettings() async {
    if (_disposed || _settingsBusy) return;
    _settingsBusy = true;
    _settingsFailed = false;
    notifyListeners();
    try {
      _settingsFailed = await service?.openAppSettings() != true;
    } catch (_) {
      _settingsFailed = true;
    } finally {
      _settingsBusy = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    // Stop is invoked synchronously even for externally removed routes.
    _disposed = true;
    unawaited(stop());
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
