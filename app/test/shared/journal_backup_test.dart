import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/shared/journal/journal_backup.dart';
import 'package:meloop/shared/journal/journal_models.dart';
import 'package:meloop/shared/journal/practice_date.dart';

void main() {
  final now = DateTime.utc(2026, 10, 3);
  final settings = BackupSettings(
    language: JournalLanguage.vi,
    reminderEnabled: false,
    weekdays: [],
    reminderMinutes: BackupRules.defaultReminderMinutes,
    metronomeBpm: BackupRules.defaultMetronomeBpm,
    beatsPerBar: BackupRules.defaultBeatsPerBar,
  );
  final capacity = throwsA(
    isA<BackupFailure>().having(
      (e) => e.code,
      'code',
      BackupFailureCode.capacityExceeded,
    ),
  );
  JournalBackupDocument document({
    List<JournalProfile> profiles = const [],
    List<PracticeSession> sessions = const [],
  }) => JournalBackupDocument(
    exportedAt: now,
    profiles: profiles,
    sessions: sessions,
    goals: [],
    settings: settings,
  );
  JournalProfile profile(String name) => JournalProfile(
    id: '00000000-0000-4000-8000-000000000001',
    name: name,
    instrument: JournalInstrument.guitar,
    customType: '',
    createdAt: now,
    updatedAt: now,
  );
  test('encoding enforces UTF8 byte capacity even for multibyte text', () {
    // Deliberately bypass field validation to isolate the byte encoder's bound.
    final content = List.filled(BackupRules.maximumBytes ~/ 4 + 1, '🎵').join();
    expect(() => document(profiles: [profile(content)]).encode(), capacity);
  });
  test(
    'profile and session capacities reject before encoding large collections',
    () {
      expect(
        () => document(
          profiles: List.filled(BackupRules.maximumProfiles + 1, profile('QA')),
        ).encode(),
        capacity,
      );
      final session = PracticeSession(
        id: '00000000-0000-4000-8000-000000000011',
        profileId: '00000000-0000-4000-8000-000000000001',
        state: PracticeState.saved,
        title: 'QA',
        practiceDate: PracticeDate.parse('2026-10-03'),
        startOffsetMinutes: 0,
        durationSeconds: 60,
        measuredDurationSeconds: 60,
        createdAt: now,
        updatedAt: now,
      );
      expect(
        () => document(
          sessions: List.filled(BackupRules.maximumSessions + 1, session),
        ).encode(),
        capacity,
      );
    },
  );
}
