import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/app/journal_providers.dart';
import 'package:meloop/app/profile_preview_app.dart';
import 'package:meloop/backend/database/journal_database_owner.dart';
import 'package:meloop/frontend/components/meloop_ui.dart';
import 'package:meloop/frontend/home/practice_progress_page.dart';
import 'package:meloop/frontend/practice_sessions/practice_session.dart';
import 'package:meloop/frontend/practice_sessions/practice_session_card.dart';
import 'package:meloop/frontend/practice_sessions/practice_session_detail_page.dart';
import 'package:meloop/frontend/profiles/profile_screens.dart';
import 'package:meloop/frontend/showcase/home_example.dart';
import 'package:meloop/frontend/showcase/session_form_example.dart';

/// Saved journal records are test fixtures in a disposable database only.
Future<void> runHomeOverviewJourney(
  WidgetTester tester, {
  required JournalDatabaseOwner owner,
  Future<void> Function(String)? screenshot,
}) async {
  const guitar = '00000000-0000-4000-8000-000000000001';
  const flute = '00000000-0000-4000-8000-000000000002';
  const saved = '00000000-0000-4000-8000-000000000011';
  final today = DateTime(2026, 10, 3);
  Future<void> waitFor(Finder finder) async {
    for (var attempt = 0; attempt < 150; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await tester.pump(const Duration(milliseconds: 50));
      if (finder.evaluate().isNotEmpty &&
          find.byType(CircularProgressIndicator).evaluate().isEmpty) {
        break;
      }
    }
    await tester.pumpAndSettle();
    expect(finder, findsOneWidget);
  }

  Future<void> tap(Finder finder) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await waitFor(finder);
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pump(const Duration(milliseconds: 400));
  }

  Finder tab(String label) => find.descendant(
    of: find.byType(MeloopBottomNavigation),
    matching: find.text(label),
  );
  String metric(String key) => tester.widget<Text>(find.byKey(Key(key))).data!;
  Future<void> waitHome() async {
    await waitFor(find.byType(HomeExample));
    await waitFor(find.byKey(const Key('overview-count')));
  }

  Future<void> progress(int minutes, int count, int streak, String goal) async {
    await tap(tab('Tiến độ'));
    await waitFor(find.byType(PracticeProgressPage));
    await waitFor(find.byKey(const Key('overview-count')));
    expect(metric('overview-minutes'), '$minutes');
    expect(metric('overview-count'), '$count');
    expect(metric('overview-streak'), '$streak');
    expect(find.text(goal), findsOneWidget);
  }

  try {
    await owner.transaction((db) async {
      for (final entry in [
        (guitar, 'Guitar QA', 'guitar'),
        (flute, 'Sáo QA', 'flute'),
      ]) {
        await db.insert('instrument_profiles', {
          'id': entry.$1,
          'name': entry.$2,
          'name_key': entry.$2.toLowerCase(),
          'instrument_type': entry.$3,
          'created_at': today.millisecondsSinceEpoch,
          'updated_at': today.millisecondsSinceEpoch,
        });
        await db.insert('weekly_goals', {
          'profile_id': entry.$1,
          'enabled': entry.$1 == guitar ? 1 : 0,
          'target_days': 4,
          'updated_at': today.millisecondsSinceEpoch,
        });
      }
      await db.insert('practice_sessions', {
        'id': saved,
        'profile_id': guitar,
        'state': 'saved',
        'title': 'Gam C QA',
        'practice_date': '2026-10-03',
        'start_offset_minutes': 420,
        'duration_seconds': 90,
        'measured_duration_seconds': 90,
        'practiced': 'Chuyển hợp âm',
        'mood': 4,
        'focus': 5,
        'bpm': 80,
        'created_at': today.millisecondsSinceEpoch,
        'updated_at': today.millisecondsSinceEpoch,
      });
    });
    await tester.pumpWidget(
      createJournalProfileApp(
        overrides: [
          journalDatabaseOwnerProvider.overrideWithValue(owner),
          practiceSessionsClockProvider.overrideWithValue(() => today),
        ],
      ),
    );
    await waitFor(find.byType(ProfilePickerScreen));
    await tap(find.byKey(const Key('select-profile-$guitar')));
    await waitHome();
    expect(find.text('Gam C QA'), findsOneWidget);
    expect(metric('overview-minutes'), '1');
    expect(metric('overview-count'), '1');
    expect(metric('overview-streak'), '1');
    expect(find.text('1/4 ngày'), findsOneWidget);
    expect(find.textContaining('Tiếp tục'), findsNothing);
    if (screenshot != null) await screenshot('task24-home-guitar');
    await progress(1, 1, 1, '1/4 ngày');
    expect(find.text('4,0/5 · 1 lượt đánh giá'), findsOneWidget);
    if (screenshot != null) await screenshot('task24-progress-guitar');
    await tap(tab('Trang chủ'));
    await waitHome();
    await tap(find.byKey(const Key('choose-profile')));
    await waitFor(find.byType(ProfilePickerScreen));
    await tap(find.byKey(const Key('select-profile-$flute')));
    await waitHome();
    expect(metric('overview-count'), '0');
    expect(find.text('Gam C QA'), findsNothing);
    expect(find.text('Chưa có buổi luyện'), findsOneWidget);
    expect(find.text('Đang tắt'), findsOneWidget);
    if (screenshot != null) await screenshot('task24-home-flute-empty');
    await progress(0, 0, 0, 'Đang tắt');
    await tap(tab('Trang chủ'));
    await tap(find.byKey(const Key('choose-profile')));
    await tap(find.byKey(const Key('select-profile-$guitar')));
    await waitHome();
    // Editing through the real form changes the latest card and both sets of totals.
    await tap(tab('Buổi luyện'));
    await tap(find.widgetWithText(PracticeSessionCard, 'Gam C QA'));
    await waitFor(find.byType(PracticeSessionDetailPage));
    await tap(find.text('Sửa nhật ký'));
    await waitFor(find.byType(SessionFormExample));
    await tester.enterText(find.byType(TextFormField).first, 'Gam C đã sửa QA');
    await tester.enterText(
      find.byKey(const Key('session-duration-minutes')),
      '0',
    );
    await tester.enterText(
      find.byKey(const Key('session-duration-seconds')),
      '30',
    );
    await tap(find.text('Lưu thay đổi'));
    await waitFor(find.byType(PracticeSessionDetailPage));
    await tap(find.byTooltip('Quay lại'));
    await tap(tab('Trang chủ'));
    await waitHome();
    expect(find.text('Gam C đã sửa QA'), findsOneWidget);
    expect(metric('overview-streak'), '0');
    expect(find.text('0/4 ngày'), findsOneWidget);
    await progress(0, 1, 0, '0/4 ngày');
    // Delete the last saved record and verify the recent block becomes empty.
    await tap(tab('Buổi luyện'));
    await tap(find.widgetWithText(PracticeSessionCard, 'Gam C đã sửa QA'));
    await tap(find.text('Xóa buổi luyện'));
    await waitFor(find.byType(Dialog));
    await tap(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.text('Xóa buổi luyện'),
      ),
    );
    await waitFor(find.text('Chưa có buổi luyện'));
    await tap(tab('Trang chủ'));
    await waitHome();
    expect(find.text('Chưa có buổi luyện'), findsOneWidget);
    expect(find.text('Gam C đã sửa QA'), findsNothing);
    await progress(0, 0, 0, '0/4 ngày');
    expect(await owner.read((db) => db.query('practice_sessions')), isEmpty);
  } finally {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await owner.close();
  }
}
