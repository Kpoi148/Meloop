import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../metronome/metronome_page.dart';
import 'metronome_preview_controller.dart';

/// Connects the Tempo page to transient UI state, without storage or audio.
class MetronomeExample extends ConsumerStatefulWidget {
  const MetronomeExample({super.key, required this.onHome});
  final VoidCallback onHome;

  @override
  ConsumerState<MetronomeExample> createState() => _MetronomeExampleState();
}

class _MetronomeExampleState extends ConsumerState<MetronomeExample>
    with WidgetsBindingObserver {
  late final MetronomePreviewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ref.read(metronomePreviewControllerProvider.notifier);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _controller.stop();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.closePreview();
    super.dispose();
  }

  void _back() {
    _controller.stop();
    Navigator.of(context).pop();
  }

  void _home() {
    _back();
    widget.onHome();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    onPopInvokedWithResult: (didPop, _) {
      if (didPop) _controller.stop();
    },
    child: MetronomePage(
      state: ref.watch(metronomePreviewControllerProvider),
      onBpmChanged: _controller.setBpm,
      onBeatsChanged: _controller.setBeats,
      onToggle: _controller.toggle,
      onBack: _back,
      onHome: _home,
    ),
  );
}
