import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meloop/app/journal_providers.dart';
import 'package:meloop/app/profile_preview_app.dart';
import 'package:meloop/backend/database/journal_database.dart';
import 'package:meloop/backend/database/journal_database_owner.dart';
import 'package:meloop/backend/journal/sqlite_instrument_profile_service.dart';
import 'package:meloop/frontend/showcase/meloop_ui_showcase.dart';
import 'package:meloop/shared/journal/journal_runtime.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Android form commits a journal profile and reopens it', (
    tester,
  ) async {
    const phase = String.fromEnvironment('PROFILE_TEST_PHASE');
    const configuredFile = String.fromEnvironment('PROFILE_TEST_DB');
    if (configuredFile.isNotEmpty &&
        !RegExp(r'^profile-process-[0-9a-f-]+\.db$').hasMatch(configuredFile)) {
      throw ArgumentError(
        'Only isolated profile-process test files are allowed.',
      );
    }
    final filename = configuredFile.isEmpty
        ? 'profile-test-${const UuidJournalIdentifiers().newId()}.db'
        : configuredFile;
    final path = '${await getDatabasesPath()}/$filename';
    var owner = JournalDatabaseOwner(
      open: () => JournalDatabase.open(path: path),
    );
    Future<void> pump() async {
      await tester.pumpWidget(
        createJournalProfileApp(
          overrides: [journalDatabaseOwnerProvider.overrideWithValue(owner)],
        ),
      );
      await tester.pumpAndSettle();
      // SQLite I/O can complete after pumpAndSettle has no scheduled frame.
      for (
        var attempt = 0;
        attempt < 100 && find.text('Đang mở hồ sơ…').evaluate().isNotEmpty;
        attempt++
      ) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pumpAndSettle();
    }

    Future<void> tap(Finder target) async {
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      await tester.tap(target);
      await tester.pumpAndSettle();
    }

    try {
      await pump();
      if (phase != 'reopen') {
        await tap(find.text('Tạo hồ sơ đầu tiên'));
        await tap(find.byKey(const Key('profile-type-guitar')));
        await owner.read(
          (db) => db.execute(
            "CREATE TRIGGER injected_goal_failure BEFORE INSERT ON weekly_goals BEGIN SELECT RAISE(ABORT, 'injected'); END",
          ),
        );
        await tap(find.byKey(const Key('save-profile')));
        expect(
          find.text('Chưa thể lưu hồ sơ. Nội dung của bạn vẫn ở đây.'),
          findsOneWidget,
        );
        expect(
          tester
              .widget<TextFormField>(find.byType(TextFormField).last)
              .controller!
              .text,
          'Guitar của tôi',
        );
        expect(
          await owner.read((db) => db.query('instrument_profiles')),
          isEmpty,
        );
        await owner.read(
          (db) => db.execute('DROP TRIGGER injected_goal_failure'),
        );
        await tap(find.byKey(const Key('save-profile')));
      }
      expect(find.byType(MeloopUiShowcase), findsOneWidget);
      final service = SqliteInstrumentProfileService(
        owner: owner,
        initialLanguage: 'vi',
      );
      final directory = await service.load();
      expect(directory.profiles, hasLength(1));
      final id = directory.selectedProfileId;
      expect(JournalId.isValid(id!), isTrue);
      expect(await owner.read((db) => db.query('practice_sessions')), isEmpty);
      expect(await owner.read((db) => db.query('weekly_goals')), hasLength(1));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await owner.close();
      owner = JournalDatabaseOwner(
        open: () => JournalDatabase.open(path: path),
      );
      await pump();
      expect(find.byType(MeloopUiShowcase), findsOneWidget);
      expect(
        (await SqliteInstrumentProfileService(
          owner: owner,
          initialLanguage: 'vi',
        ).load()).selectedProfileId,
        id,
      );
      expect(
        await owner.read((db) => db.rawQuery('PRAGMA foreign_key_check')),
        isEmpty,
      );
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await owner.close();
      if (phase != 'create') await deleteDatabase(path);
    }
  });
}
