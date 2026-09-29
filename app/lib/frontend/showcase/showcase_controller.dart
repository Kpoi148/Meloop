import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/session_form_values.dart';

class ShowcaseState {
  const ShowcaseState({
    this.selectedTab = 0,
    this.query = '',
    this.failNextSave = false,
    this.saveCount = 0,
  });

  final int selectedTab, saveCount;
  final String query;
  final bool failNextSave;

  ShowcaseState copyWith({
    int? selectedTab,
    String? query,
    bool? failNextSave,
    int? saveCount,
  }) => ShowcaseState(
    selectedTab: selectedTab ?? this.selectedTab,
    query: query ?? this.query,
    failNextSave: failNextSave ?? this.failNextSave,
    saveCount: saveCount ?? this.saveCount,
  );
}

final showcaseControllerProvider =
    NotifierProvider<ShowcaseController, ShowcaseState>(ShowcaseController.new);

final showcaseSaveDelayProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 1),
);

/// Only main_showcase.dart installs this simulation as the form's dependency.
final showcaseSessionSaveProvider = Provider<SessionFormSave>(
  (ref) =>
      (values) =>
          ref.read(showcaseControllerProvider.notifier).simulateSave(values),
);

class ShowcaseController extends Notifier<ShowcaseState> {
  @override
  ShowcaseState build() => const ShowcaseState();

  void selectTab(int value) => state = state.copyWith(selectedTab: value);
  void search(String value) => state = state.copyWith(query: value);
  void simulateFailure(bool value) =>
      state = state.copyWith(failNextSave: value);

  Future<void> simulateSave(SessionFormValues values) async {
    final operationRef = ref;
    final shouldFail = state.failNextSave;
    if (shouldFail) state = state.copyWith(failNextSave: false);
    await Future<void>.delayed(operationRef.read(showcaseSaveDelayProvider));
    if (!operationRef.mounted) return;
    if (shouldFail) throw StateError('Synthetic preview failure');
    state = state.copyWith(saveCount: state.saveCount + 1);
  }
}
