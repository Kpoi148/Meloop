import 'backup_validation.dart';
import 'journal_models.dart';

enum BackupRestoreFailureCode {
  confirmationRequired,
  busy,
  unfinishedSession,
  storage,
}

/// Safe codes only: never include SQL, file paths or journal content.
class BackupRestoreFailure implements Exception {
  const BackupRestoreFailure(this.code);
  final BackupRestoreFailureCode code;
  @override
  String toString() => 'BackupRestoreFailure(${code.name})';
}

class BackupRestoreResult {
  const BackupRestoreResult({
    required this.profileCount,
    required this.sessionCount,
    required this.language,
    required this.selectedProfileId,
    required this.cleanupPending,
    required this.remindersPending,
  });
  final int profileCount, sessionCount;
  final JournalLanguage language;
  final String? selectedProfileId;
  final bool cleanupPending, remindersPending;
}

abstract interface class JournalBackupRestorer {
  /// Call only after displaying the preview and replacement/audio warning.
  /// Cancel is a no-op. Validation is repeated; preview construction is not a
  /// validation bypass. Success means the database commit completed, even when
  /// post-commit device work remains pending. Never retry replacement for that.
  Future<BackupRestoreResult> restore({
    required BackupPreview backup,
    required bool confirmed,
  });
}

/// Future device adapters consume the durable cleanup queue and reminder
/// revision after commit. Return false on incomplete work, including permission
/// denial. Implementations must not restore/replace the journal again.
abstract interface class BackupRestoreDeviceEffects {
  Future<bool> drainCleanupQueue();
  Future<bool> reconcileReminders();
}
