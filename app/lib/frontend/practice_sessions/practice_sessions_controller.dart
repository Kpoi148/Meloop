import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/journal/journal_text.dart';
import 'practice_session.dart';

enum PracticePeriod {
  all(null),
  week(7),
  month(30);

  const PracticePeriod(this.days);
  final int? days;
}

enum PracticeOrder { newest, oldest }

class PracticeSessionFilters {
  const PracticeSessionFilters({
    this.period = PracticePeriod.all,
    this.order = PracticeOrder.newest,
  });

  final PracticePeriod period;
  final PracticeOrder order;

  bool get isActive =>
      period != PracticePeriod.all || order != PracticeOrder.newest;

  PracticeSessionFilters copyWith({
    PracticePeriod? period,
    PracticeOrder? order,
  }) => PracticeSessionFilters(
    period: period ?? this.period,
    order: order ?? this.order,
  );
}

class PracticeSessionsViewState {
  const PracticeSessionsViewState({
    this.query = '',
    this.filters = const PracticeSessionFilters(),
  });
  final String query;
  final PracticeSessionFilters filters;

  List<PracticeSession> visibleSessions(
    List<PracticeSession> sessions, {
    required String profileId,
    required DateTime now,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final days = filters.period.days;
    final from = days == null
        ? null
        : DateTime(today.year, today.month, today.day - days + 1);
    final queryText = JournalText.searchKey(query.trim());
    final result = sessions.where((session) {
      if (session.profileId != profileId) return false;
      final day = DateTime(
        session.date.year,
        session.date.month,
        session.date.day,
      );
      if (day.isAfter(today) || (from != null && day.isBefore(from))) {
        return false;
      }
      return [
        session.title,
        session.practiced,
        session.difficulty,
        session.nextPractice,
      ].any((field) => JournalText.searchKey(field).contains(queryText));
    }).toList();
    result.sort((a, b) {
      final dateOrder = a.date.compareTo(b.date);
      final order = dateOrder == 0 ? a.id.compareTo(b.id) : dateOrder;
      return filters.order == PracticeOrder.newest ? -order : order;
    });
    return result;
  }
}

final practiceSessionsControllerProvider =
    NotifierProvider<
      PracticeSessionsController,
      Map<String, PracticeSessionsViewState>
    >(PracticeSessionsController.new);

class PracticeSessionsController
    extends Notifier<Map<String, PracticeSessionsViewState>> {
  @override
  Map<String, PracticeSessionsViewState> build() => const {};

  PracticeSessionsViewState forProfile(String profileId) =>
      state[profileId] ?? const PracticeSessionsViewState();

  void search(String profileId, String query) {
    final current = forProfile(profileId);
    state = {
      ...state,
      profileId: PracticeSessionsViewState(
        query: query,
        filters: current.filters,
      ),
    };
  }

  void applyFilters(String profileId, PracticeSessionFilters filters) {
    state = {
      ...state,
      profileId: PracticeSessionsViewState(
        query: forProfile(profileId).query,
        filters: filters,
      ),
    };
  }

  void clear(String profileId) {
    state = {...state, profileId: const PracticeSessionsViewState()};
  }
}
