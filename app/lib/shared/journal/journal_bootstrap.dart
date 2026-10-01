import '../profiles/instrument_profile_service.dart';
import 'journal_models.dart';

class JournalBootstrapSnapshot {
  const JournalBootstrapSnapshot({required this.directory, this.draft});
  final ProfileDirectory directory;
  final PracticeDraft? draft;
}

abstract interface class JournalBootstrapReader {
  Future<JournalBootstrapSnapshot> read();
}
