import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/frontend/application/session_form_values.dart';
import 'package:meloop/frontend/showcase/showcase_controller.dart';

void main() {
  test(
    'preview failure is consumed once and only success updates the counter',
    () async {
      final container = ProviderContainer(
        overrides: [showcaseSaveDelayProvider.overrideWithValue(Duration.zero)],
      );
      addTearDown(container.dispose);
      final controller = container.read(showcaseControllerProvider.notifier);
      controller.selectTab(1);
      controller.search('gam');
      controller.simulateFailure(true);
      final save = container.read(showcaseSessionSaveProvider);
      final request = SessionFormValues(
        title: 'Luyện gam C',
        date: DateTime(2026, 9, 29),
        durationSeconds: 60,
        practiced: '',
        difficulty: '',
        next: '',
      );

      await expectLater(save(request), throwsStateError);
      expect(container.read(showcaseControllerProvider).failNextSave, isFalse);
      expect(container.read(showcaseControllerProvider).saveCount, 0);
      await save(request);
      final state = container.read(showcaseControllerProvider);
      expect(state.saveCount, 1);
      expect(state.selectedTab, 1);
      expect(state.query, 'gam');
    },
  );
}
