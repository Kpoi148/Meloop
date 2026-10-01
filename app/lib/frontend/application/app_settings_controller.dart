import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/settings/app_settings_store.dart';

final appSettingsStoreProvider = Provider<AppSettingsStore>(
  (ref) => InMemoryAppSettingsStore(languageCode: 'vi'),
);

final appLocaleProvider = AsyncNotifierProvider<AppLocaleController, Locale>(
  AppLocaleController.new,
);

class AppLocaleController extends AsyncNotifier<Locale> {
  static const supportedCodes = {'vi', 'en'};

  @override
  Future<Locale> build() async {
    final code = await ref.read(appSettingsStoreProvider).readLanguageCode();
    return Locale(supportedCodes.contains(code) ? code! : 'vi');
  }

  Future<void> select(Locale locale) async {
    final code = locale.languageCode;
    if (!supportedCodes.contains(code) || state.value?.languageCode == code) {
      return;
    }
    final previous = state;
    state = AsyncData(Locale(code));
    try {
      await ref.read(appSettingsStoreProvider).writeLanguageCode(code);
    } catch (error, stackTrace) {
      state = previous;
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}
