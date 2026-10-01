/// Storage for the interactive UI prototype, replaced by Khanh's service later.
abstract interface class ProfilePreviewStorage {
  Future<String?> read();
  Future<void> write(String snapshot);
}
