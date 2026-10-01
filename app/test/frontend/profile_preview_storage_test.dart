import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/app/profile_preview_storage.dart';
import 'package:meloop/frontend/application/instrument_profile_service.dart';
import 'package:meloop/frontend/showcase/profile_preview_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/profile_preview_test_storage.dart';

void main() {
  sqfliteFfiInit();

  test(
    'SQLite preserves create, rename, select, delete and reset after reopening',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'meloop-profile-ui-test-',
      );
      final stores = <SqliteProfilePreviewStorage>[];
      addTearDown(() async {
        for (final store in stores) {
          await store.close();
        }
        await directory.delete(recursive: true);
      });
      SqliteProfilePreviewStorage openStore() {
        final store = SqliteProfilePreviewStorage(
          factory: databaseFactoryFfi,
          path: '${directory.path}/profile-ui.db',
        );
        stores.add(store);
        return store;
      }

      var store = openStore();
      var service = ProfilePreviewService(storage: store);
      expect((await service.load()).profiles, isEmpty);
      await service.create(
        requestId: 'guitar',
        name: 'Guitar',
        instrumentType: InstrumentType.guitar,
        customType: '',
      );
      await service.create(
        requestId: 'piano',
        name: 'Piano',
        instrumentType: InstrumentType.piano,
        customType: '',
      );
      await service.rename(profileId: 'preview-1', name: 'Guitar buổi tối');
      await service.select('preview-1');
      await service.enableProPreview();
      await store.close();

      store = openStore();
      service = ProfilePreviewService(storage: store);
      var state = await service.load();
      expect(state.profiles, hasLength(2));
      expect(state.isPro, isTrue);
      expect(state.selectedProfile!.name, 'Guitar buổi tối');
      expect(state.selectedProfile!.instrumentType, InstrumentType.guitar);
      expect(
        state.profiles.every(
          (profile) =>
              profile.savedSessionCount == 0 && profile.recordingCount == 0,
        ),
        isTrue,
      );
      // A retried creation still refers to its original profile after restart.
      state = await service.create(
        requestId: 'guitar',
        name: 'Guitar',
        instrumentType: InstrumentType.guitar,
        customType: '',
      );
      expect(state.profiles, hasLength(2));
      await service.delete('preview-1');
      await store.close();

      store = openStore();
      service = ProfilePreviewService(storage: store);
      state = await service.load();
      expect(state.profiles.single.name, 'Piano');
      expect(state.selectedProfileId, 'preview-2');
      await service.reset();
      await store.close();
      service = ProfilePreviewService(storage: openStore());
      state = await service.load();
      expect(state.profiles, isEmpty);
      expect(state.selectedProfileId, isNull);
      expect(state.isPro, isFalse);
    },
  );

  test(
    'failed write rolls back creation and permits the same request to retry',
    () async {
      final storage = MemoryProfilePreviewStorage()..failWrite = true;
      final service = ProfilePreviewService(storage: storage);
      Future<ProfileDirectory> create() => service.create(
        requestId: 'retry',
        name: 'Guitar',
        instrumentType: InstrumentType.guitar,
        customType: '',
      );
      await expectLater(create(), throwsA(isA<ProfileServiceException>()));
      expect((await service.load()).profiles, isEmpty);
      storage.failWrite = false;
      await create();
      final reopened = await ProfilePreviewService(storage: storage).load();
      expect(reopened.profiles.single.id, 'preview-1');
      expect(reopened.selectedProfileId, 'preview-1');
    },
  );
}
