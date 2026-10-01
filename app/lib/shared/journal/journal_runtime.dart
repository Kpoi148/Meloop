import 'package:uuid/uuid.dart';

abstract interface class JournalClock {
  DateTime utcNow();
  DateTime localNow();
}

class DeviceJournalClock implements JournalClock {
  const DeviceJournalClock();
  @override
  DateTime utcNow() => DateTime.now().toUtc();
  @override
  DateTime localNow() => DateTime.now();
}

abstract interface class JournalIdentifiers {
  /// Generate once at the command boundary and reuse the ID on retries.
  String newId();
}

class UuidJournalIdentifiers implements JournalIdentifiers {
  const UuidJournalIdentifiers();
  @override
  String newId() => const Uuid().v4();
}

class JournalId {
  JournalId._();
  static final _v4 = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );
  static bool isValid(String value) => _v4.hasMatch(value);
}
