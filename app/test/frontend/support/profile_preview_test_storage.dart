import 'package:meloop/frontend/showcase/profile_preview_storage.dart';

class MemoryProfilePreviewStorage implements ProfilePreviewStorage {
  String? snapshot;
  int writes = 0;
  bool failWrite = false;

  @override
  Future<String?> read() async => snapshot;

  @override
  Future<void> write(String value) async {
    if (failWrite) throw StateError('Synthetic storage failure');
    snapshot = value;
    writes++;
  }
}
