import '../profiles/instrument_profile_service.dart';
import 'journal_models.dart';

class JournalBootstrapSnapshot {
  const JournalBootstrapSnapshot({required this.directory, this.draft});
  final ProfileDirectory directory;

  /// Only the selected profile's unfinished session. Other drafts stay stored
  /// and are loaded when that profile is selected.
  final PracticeDraft? draft;
}

abstract interface class JournalBootstrapReader {
  Future<JournalBootstrapSnapshot> read();
}
