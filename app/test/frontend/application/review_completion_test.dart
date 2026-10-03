import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/frontend/application/instrument_profile_service.dart';
import 'package:meloop/frontend/application/practice_review_provider.dart';
import 'package:meloop/frontend/application/practice_timer_service.dart';
import 'package:meloop/shared/journal/journal_models.dart';
import 'package:meloop/shared/journal/practice_timer_service.dart';

class _Profiles implements InstrumentProfileService {
  var reads = 0;
  @override
  Future<ProfileDirectory> load() async {
    if (++reads == 1) throw StateError('Injected directory failure');
    return const ProfileDirectory(
      profiles: [
        InstrumentProfile(
          id: 'owner',
          name: 'Guitar',
          instrumentType: InstrumentType.guitar,
          savedSessionCount: 1,
        ),
      ],
      selectedProfileId: 'owner',
      isPro: false,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Timer implements PracticeTimerService {
  @override
  PracticeTimerSnapshot? snapshot = const PracticeTimerSnapshot(
    sessionId: 'saved',
    profileId: 'owner',
    state: PracticeState.review,
    elapsedMilliseconds: 1000,
    persistedMilliseconds: 1000,
  );
  var completions = 0;
  @override
  Future<void> complete(String id) async {
    expect(id, snapshot!.sessionId);
    completions++;
    snapshot = null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('directory retry does not complete an already released timer', () async {
    final timer = _Timer();
    final profiles = _Profiles();
    final container = ProviderContainer(
      overrides: [
        practiceTimerServiceProvider.overrideWithValue(timer),
        instrumentProfileServiceProvider.overrideWithValue(profiles),
      ],
    );
    addTearDown(container.dispose);
    final complete = container.read(practiceReviewCompleteProvider);
    await expectLater(complete('saved'), throwsStateError);
    expect(timer.snapshot, isNull);
    expect(await complete('saved'), {'owner': 1});
    expect(timer.completions, 1);
    expect(profiles.reads, 2);
  });

  test(
    'completion of an old saved session preserves another active timer',
    () async {
      final timer = _Timer();
      final container = ProviderContainer(
        overrides: [practiceTimerServiceProvider.overrideWithValue(timer)],
      );
      addTearDown(container.dispose);
      await container.read(practiceTimerCompleteProvider)('other-session');
      expect(timer.snapshot!.sessionId, 'saved');
      expect(timer.completions, 0);
    },
  );
}
