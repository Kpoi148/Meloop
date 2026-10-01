enum JournalFailureCode { storage, corruptData, closed, invalidInput }

/// Safe to map to localized UI messages. Never includes user journal content.
class JournalFailure implements Exception {
  const JournalFailure(this.code);
  final JournalFailureCode code;

  @override
  String toString() => 'JournalFailure(${code.name})';
}
