abstract interface class AppSettingsStore {
  Future<String?> readLanguageCode();

  Future<void> writeLanguageCode(String languageCode);
}

/// Safe default for widget tests and previews. Production injects durable storage.
class InMemoryAppSettingsStore implements AppSettingsStore {
  factory InMemoryAppSettingsStore({String? languageCode}) =>
      InMemoryAppSettingsStore._(languageCode);

  InMemoryAppSettingsStore._(this._languageCode);

  String? _languageCode;

  @override
  Future<String?> readLanguageCode() async => _languageCode;

  @override
  Future<void> writeLanguageCode(String languageCode) async {
    _languageCode = languageCode;
  }
}
