import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/pitch/pitch_service.dart';
import 'pitch_controller.dart';
import 'pitch_page.dart';

/// App composition overrides this port when real pitch capture is available.
/// Without an adapter, the UI reports unavailability instead of a fake reading.
final pitchServiceProvider = Provider<PitchService?>((ref) => null);

class PitchRoute extends ConsumerStatefulWidget {
  const PitchRoute({super.key, required this.onHome});
  final VoidCallback onHome;

  @override
  ConsumerState<PitchRoute> createState() => _PitchRouteState();
}

class _PitchRouteState extends ConsumerState<PitchRoute>
    with WidgetsBindingObserver {
  late final PitchController _controller;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _controller = PitchController(ref.read(pitchServiceProvider));
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Android's permission prompt uses inactive; stopping then would cancel
    // the user's first request. Actual backgrounding does release the mic.
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_controller.stop());
    }
  }

  Future<void> _leave({bool home = false}) async {
    if (_leaving) return;
    _leaving = true;
    await _controller.stop();
    if (!mounted) return;
    if (_controller.snapshot.phase == PitchPhase.stopFailed) {
      _leaving = false;
      return;
    }
    Navigator.of(context).pop();
    if (home) widget.onHome();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) unawaited(_leave());
    },
    child: AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => PitchPage(
        snapshot: _controller.snapshot,
        stopping: _controller.stopping,
        settingsBusy: _controller.settingsBusy,
        settingsFailed: _controller.settingsFailed,
        onToggle: () => unawaited(_controller.toggle()),
        onOpenSettings: _controller.openSettings,
        onBack: () => unawaited(_leave()),
        onHome: () => unawaited(_leave(home: true)),
      ),
    ),
  );
}
