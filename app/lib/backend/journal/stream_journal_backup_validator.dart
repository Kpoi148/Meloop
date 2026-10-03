import 'dart:convert';
import 'dart:typed_data';

import '../../shared/journal/backup_validation.dart';
import '../../shared/journal/journal_backup.dart';
import '../../shared/journal/journal_failure.dart';
import '../../shared/journal/journal_runtime.dart';
import '../../shared/journal/practice_date.dart';
import 'backup_v1_parser.dart';

class StreamJournalBackupValidator implements JournalBackupValidator {
  const StreamJournalBackupValidator({this.clock = const DeviceJournalClock()});
  final JournalClock clock;
  @override
  Future<BackupPreview> validate(Stream<List<int>> source) async {
    final bytes = BytesBuilder(copy: false);
    try {
      await for (final chunk in source) {
        if (bytes.length + chunk.length > BackupRules.maximumBytes) {
          throw const BackupValidationFailure(
            BackupValidationFailureCode.capacityExceeded,
          );
        }
        if (chunk.any((byte) => byte < 0 || byte > 255)) {
          throw const BackupValidationFailure(
            BackupValidationFailureCode.invalidBackup,
          );
        }
        // Copy so a stream producer cannot mutate previously delivered buffers.
        bytes.add(Uint8List.fromList(chunk));
      }
    } on BackupValidationFailure {
      rethrow;
    } catch (_) {
      throw const BackupValidationFailure(
        BackupValidationFailureCode.readFailure,
      );
    }
    try {
      final text = utf8.decode(bytes.takeBytes());
      _checkDepth(text);
      return BackupPreview(
        const BackupV1Parser().parse(
          jsonDecode(text),
          today: PracticeDate.fromLocal(clock.localNow()),
        ),
      );
    } on BackupValidationFailure {
      rethrow;
    } on FormatException {
      throw const BackupValidationFailure(
        BackupValidationFailureCode.invalidBackup,
      );
    } on ArgumentError {
      throw const BackupValidationFailure(
        BackupValidationFailureCode.invalidBackup,
      );
    } on JournalFailure {
      throw const BackupValidationFailure(
        BackupValidationFailureCode.invalidBackup,
      );
    }
  }

  void _checkDepth(String text) {
    var quoted = false, escaped = false, depth = 0;
    for (final code in text.codeUnits) {
      if (quoted) {
        if (escaped) {
          escaped = false;
        } else if (code == 0x5c) {
          escaped = true;
        } else if (code == 0x22) {
          quoted = false;
        }
      } else if (code == 0x22) {
        quoted = true;
      } else if (code == 0x7b || code == 0x5b) {
        if (++depth > BackupRules.maximumJsonDepth) {
          throw const BackupValidationFailure(
            BackupValidationFailureCode.invalidBackup,
          );
        }
      } else if (code == 0x7d || code == 0x5d) {
        depth--;
      }
    }
  }
}
