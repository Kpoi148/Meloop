import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'session_form_values.dart';

/// Override at app startup when the backend implementation is available.
/// An unconfigured dependency must never report a successful save.
final sessionFormSaveProvider = Provider<SessionFormSave>(
  (ref) => (_) async {
    throw StateError('Session save dependency has not been configured.');
  },
);

/// Each mounted form supplies its own identity, even when sharing a save handler.
final sessionFormControllerProvider = NotifierProvider.autoDispose
    .family<SessionFormController, AsyncValue<void>, Object>(
      (_) => SessionFormController(),
    );

class SessionFormController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  void clearError() {
    if (state.hasError) state = const AsyncData(null);
  }

  /// Coordinates UI state only; validation and persistence belong to the backend.
  /// The optional callback preserves the standalone component examples' API.
  Future<bool> save(
    SessionFormValues values, {
    SessionFormSave? onSave,
    FutureOr<void> Function()? onCompleted,
  }) async {
    if (state.isLoading) return false;
    final operationRef = ref;
    state = const AsyncLoading();
    try {
      final SessionFormSave save =
          onSave ?? operationRef.read<SessionFormSave>(sessionFormSaveProvider);
      await save(values);
      if (!operationRef.mounted) return false;
      await onCompleted?.call();
      if (operationRef.mounted) state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      if (operationRef.mounted) state = AsyncError(error, stackTrace);
      return false;
    }
  }
}
