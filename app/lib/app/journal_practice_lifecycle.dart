import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../frontend/application/practice_timer_service.dart';

/// Above profile/tab navigation. Foreground never resumes automatically.
class JournalPracticeLifecycle extends ConsumerStatefulWidget {
  const JournalPracticeLifecycle({super.key, required this.child});
  final Widget child;
  @override
  ConsumerState<JournalPracticeLifecycle> createState() =>
      _JournalPracticeLifecycleState();
}

class _JournalPracticeLifecycleState
    extends ConsumerState<JournalPracticeLifecycle>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref
        .read(practiceTimerServiceProvider)
        ?.setForeground(state == AppLifecycleState.resumed);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
