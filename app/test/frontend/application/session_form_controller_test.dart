import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/frontend/application/session_form_controller.dart';
import 'package:meloop/frontend/application/session_form_values.dart';

SessionFormValues values() => SessionFormValues(
  title: 'Luyện gam C',
  date: DateTime(2026, 9, 29),
  durationSeconds: 60,
  practiced: '',
  difficulty: '',
  next: '',
);

void main() {
  test(
    'injected save locks immediately, exposes errors and allows retry',
    () async {
      var calls = 0;
      SessionFormValues? received;
      var pending = Completer<void>();
      final container = ProviderContainer(
        overrides: [
          sessionFormSaveProvider.overrideWithValue((value) {
            calls++;
            received = value;
            return pending.future;
          }),
        ],
      );
      addTearDown(container.dispose);
      final provider = sessionFormControllerProvider(Object());
      final subscription = container.listen(provider, (_, _) {});
      addTearDown(subscription.close);
      final controller = container.read(provider.notifier);
      final request = values();

      final saving = controller.save(request);
      expect(container.read(provider).isLoading, isTrue);
      expect(await controller.save(request), isFalse);
      expect(calls, 1);
      expect(received, same(request));
      final error = StateError('Synthetic test failure');
      pending.completeError(error);
      expect(await saving, isFalse);
      expect(container.read(provider).error, same(error));
      expect(container.read(provider).isLoading, isFalse);

      pending = Completer<void>();
      final retry = controller.save(request);
      expect(container.read(provider).hasError, isFalse);
      pending.complete();
      expect(await retry, isTrue);
      expect(calls, 2);
      expect(container.read(provider).hasError, isFalse);
      expect(container.read(provider).isLoading, isFalse);
    },
  );

  test('unconfigured backend cannot report a successful save', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final provider = sessionFormControllerProvider(Object());
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);

    expect(await container.read(provider.notifier).save(values()), isFalse);
    expect(container.read(provider).error, isA<StateError>());
  });

  test('two forms have independent loading and error states', () async {
    final pending = Completer<void>();
    final container = ProviderContainer(
      overrides: [
        sessionFormSaveProvider.overrideWithValue((_) => pending.future),
      ],
    );
    addTearDown(container.dispose);
    final first = sessionFormControllerProvider(Object());
    final second = sessionFormControllerProvider(Object());
    final firstSubscription = container.listen(first, (_, _) {});
    final secondSubscription = container.listen(second, (_, _) {});
    addTearDown(firstSubscription.close);
    addTearDown(secondSubscription.close);

    final saving = container.read(first.notifier).save(values());
    expect(container.read(first).isLoading, isTrue);
    expect(container.read(second).isLoading, isFalse);
    pending.completeError(StateError('Synthetic test failure'));
    expect(await saving, isFalse);
    expect(container.read(first).hasError, isTrue);
    expect(container.read(second).hasError, isFalse);
  });

  for (final fails in [false, true]) {
    test('completion after form disposal is safe (fails=$fails)', () async {
      final pending = Completer<void>();
      final container = ProviderContainer(
        overrides: [
          sessionFormSaveProvider.overrideWithValue((_) => pending.future),
        ],
      );
      addTearDown(container.dispose);
      final provider = sessionFormControllerProvider(Object());
      final subscription = container.listen(provider, (_, _) {});
      final saving = container.read(provider.notifier).save(values());
      subscription.close();
      await container.pump();

      if (fails) {
        pending.completeError(StateError('Synthetic test failure'));
      } else {
        pending.complete();
      }
      expect(await saving, isFalse);
      expect(container.read(provider).isLoading, isFalse);
      expect(container.read(provider).hasError, isFalse);
    });
  }
}
