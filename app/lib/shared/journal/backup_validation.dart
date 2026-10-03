import 'journal_backup.dart';

enum BackupValidationFailureCode {
  invalidBackup,
  unsupportedVersion,
  capacityExceeded,
  readFailure,
}

/// Safe failure codes only; never include imported text or source paths.
class BackupValidationFailure implements Exception {
  const BackupValidationFailure(this.code);
  final BackupValidationFailureCode code;
  @override
  String toString() => 'BackupValidationFailure(${code.name})';
}

class BackupPreview {
  const BackupPreview(this.document);
  final JournalBackupDocument document;
  DateTime get exportedAt => document.exportedAt;
  int get profileCount => document.profiles.length;
  int get sessionCount => document.sessions.length;
}

abstract interface class JournalBackupValidator {
  /// Reads with a byte bound and validates the entire dataset before returning.
  /// No database writes, restore, confirmation or document picker in this port.
  Future<BackupPreview> validate(Stream<List<int>> source);
}
