import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/backend/database/journal_database_owner.dart';
import 'package:meloop/backend/journal/sqlite_journal_readers.dart';
import 'package:meloop/frontend/application/practice_review_provider.dart';
import 'package:meloop/frontend/components/meloop_ui.dart';
import 'package:meloop/frontend/practice_sessions/practice_session_card.dart';
import 'package:meloop/frontend/practice_sessions/practice_session_detail_page.dart';
import 'package:meloop/frontend/practice_sessions/practice_sessions_controller.dart';
import 'package:meloop/frontend/practice_sessions/practice_sessions_tab.dart';
import 'package:meloop/frontend/profiles/profile_screens.dart';
import 'package:meloop/frontend/showcase/session_form_example.dart';

import 'session_search_journey.dart';

/// Actual SQLite app ports + existing Edit/Delete UI. Save uses the same
/// production Save/complete ports, without synthesizing a timer UI acceptance.
Future<void> runSessionSearchAcceptanceJourney(
  WidgetTester tester,
  JournalDatabaseOwner owner,
) => runSessionSearchJourney(
  tester,
  owner,
  afterSearch: () async {
    const profile = '00000000-0000-4000-8000-000000000001';
    const other = '00000000-0000-4000-8000-000000000002';
    const savedId = '00000000-0000-4000-8000-000000000030';
    Future<void> waitFor(Finder finder) async {
      for (var i = 0; i < 150; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await tester.pump(const Duration(milliseconds: 50));
        if (finder.evaluate().isNotEmpty &&
            find
                .byType(CircularProgressIndicator, skipOffstage: false)
                .evaluate()
                .isEmpty) {
          break;
        }
      }
      await tester.pumpAndSettle();
      expect(finder, findsOneWidget);
    }

    Future<void> tap(Finder finder) async {
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pump(const Duration(milliseconds: 300));
    }

    Future<void> search(String value) async {
      await tester.ensureVisible(find.byType(TextField));
      await tester.enterText(find.byType(TextField), value);
      await tester.pumpAndSettle();
    }

    Future<void> filters() async {
      await tap(find.byTooltip('Bộ lọc'));
      await tester.pumpAndSettle();
      await tap(find.widgetWithText(TextButton, '7 ngày'));
      await tap(find.widgetWithText(TextButton, 'Cũ nhất'));
      await tap(find.widgetWithText(MeloopButton, 'Áp dụng'));
      await tester.pumpAndSettle();
    }

    ProviderContainer scope() => ProviderScope.containerOf(
      tester.element(find.byType(PracticeSessionsTab)),
    );
    PracticeSessionsViewState state() => scope()
        .read(practiceSessionsControllerProvider.notifier)
        .forProfile(profile);
    void expectContext(String query) {
      expect(state().query, query);
      expect(state().filters.period, PracticePeriod.week);
      expect(state().filters.order, PracticeOrder.oldest);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        query,
      );
    }

    await search('zznew');
    await filters();
    await waitFor(find.text('Không có buổi luyện phù hợp.'));
    final now = DateTime.utc(2026, 10, 3).millisecondsSinceEpoch;
    await owner.transaction((db) async {
      await db.insert('practice_sessions', {
        'id': savedId,
        'profile_id': profile,
        'state': 'review',
        'title': 'Pending',
        'practice_date': '2026-10-03',
        'start_offset_minutes': 420,
        'created_at': now,
        'updated_at': now,
      });
    });
    final container = scope();
    await container.read(practiceReviewSaveProvider)(
      savedId,
      SessionFormValues(
        title: 'zznew Đàn',
        date: DateTime(2026, 10, 3),
        durationSeconds: 60,
        practiced: '',
        difficulty: '',
        next: '',
        mood: null,
        focus: null,
      ),
    );
    final counts = await container.read(practiceReviewCompleteProvider)(
      savedId,
    );
    expect(
      counts[profile],
      8,
    ); // Seven fixture Saved rows plus this Save (incl. future).
    await waitFor(find.widgetWithText(PracticeSessionCard, 'zznew Đàn'));
    expectContext('zznew');
    final card = find.byType(PracticeSessionCard);
    expect(card, findsOneWidget);
    final scroll = tester
        .widget<PracticeSessionsTab>(find.byType(PracticeSessionsTab))
        .scrollController;
    await tap(card);
    await waitFor(find.byType(PracticeSessionDetailPage));
    await tap(find.byTooltip('Quay lại'));
    await waitFor(card);
    expectContext('zznew');
    final offset = scroll.offset;
    await tap(card);
    await waitFor(find.byType(PracticeSessionDetailPage));
    await tap(find.byTooltip('Quay lại'));
    await waitFor(card);
    expectContext('zznew');
    expect(scroll.offset, closeTo(offset, 1));
    await tap(card);
    await waitFor(find.byType(PracticeSessionDetailPage));
    await tap(find.text('Sửa nhật ký'));
    await waitFor(find.byType(SessionFormExample));
    await tester.enterText(find.byType(TextFormField).first, 'zzedit Đàn');
    await tap(find.text('Lưu thay đổi'));
    await waitFor(find.byType(PracticeSessionDetailPage));
    await tap(find.byTooltip('Quay lại'));
    await waitFor(find.text('Không có buổi luyện phù hợp.'));
    expectContext('zznew');
    // Removing the last matching card shortens the list; Flutter clamps the
    // saved offset to the remaining extent rather than scrolling beyond it.
    expect(scroll.offset, lessThanOrEqualTo(scroll.position.maxScrollExtent));
    expect(
      await SqliteJournalSessionReader(owner)
          .saved(profileId: profile, query: 'zznew'),
      isEmpty,
    );
    expect(
      (await SqliteJournalSessionReader(
        owner,
      ).saved(profileId: profile, query: 'ZZEDIT')).single.id,
      savedId,
    );
    await search('zzedit');
    await waitFor(find.widgetWithText(PracticeSessionCard, 'zzedit Đàn'));
    await tap(card);
    await waitFor(find.byType(PracticeSessionDetailPage));
    await tap(find.widgetWithText(MeloopButton, 'Xóa buổi luyện'));
    await tester.pumpAndSettle();
    await tap(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.text('Xóa buổi luyện'),
      ),
    );
    await waitFor(find.text('Không có buổi luyện phù hợp.'));
    expectContext('zzedit');
    expect(
      await SqliteJournalSessionReader(owner)
          .findSaved(profileId: profile, sessionId: savedId),
      isNull,
    );
    // Changing owner must reset list context. Returning to the first profile must
    // not resurrect an old query/filter or show another owner's rows.
    await tap(find.text('Guitar'));
    await waitFor(find.byType(ProfilePickerScreen));
    await tap(find.byKey(const Key('select-profile-$other')));
    await waitFor(find.byKey(const Key('overview-count')));
    await tap(find.text('Buổi luyện').last);
    await waitFor(find.byType(TextField));
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    expect(
      tester
          .widgetList<PracticeSessionCard>(find.byType(PracticeSessionCard))
          .every((c) => c.session.profileId == other),
      isTrue,
    );
    await tap(find.text('Guitar'));
    await waitFor(find.byType(ProfilePickerScreen));
    await tap(find.byKey(const Key('select-profile-$profile')));
    await waitFor(find.byKey(const Key('overview-count')));
    await tap(find.text('Buổi luyện').last);
    await waitFor(find.byType(TextField));
    expect(state().query, isEmpty);
    expect(state().filters.isActive, isFalse);
    expect(tester.takeException(), isNull);
  },
);
