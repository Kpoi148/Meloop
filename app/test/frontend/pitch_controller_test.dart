import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/frontend/pitch/pitch_controller.dart';
import 'package:meloop/frontend/showcase/pitch_preview_service.dart';
import 'package:meloop/shared/pitch/pitch_service.dart';

const reading = PitchReading(
  note: 'A4',
  frequencyHz: 442.1,
  cents: 8,
  direction: PitchDirection.high,
);

class ControlledPitchService extends PitchPreviewService {
  Completer<void>? pendingStart, pendingStop;
  int starts = 0, stops = 0, settingsOpened = 0;
  bool failStart = false, failStop = false, failSettings = false;

  @override
  Future<void> start() async {
    starts++;
    await pendingStart?.future;
    if (failStart) throw StateError('start failed');
    present(PitchPhase.listening);
  }

  @override
  Future<void> stop() async {
    stops++;
    await pendingStop?.future;
    if (failStop) throw StateError('stop failed');
    await super.stop();
  }

  @override
  Future<bool> openAppSettings() async {
    settingsOpened++;
    if (failSettings) throw StateError('settings failed');
    return true;
  }
}

void main() {
  test('stream failure preserves an unsuccessful stop for retry', () async {
    final events = StreamController<PitchSnapshot>.broadcast(sync: true);
    final service = _FaultPitchService(events)..failStop = true;
    final controller = PitchController(service);
    await controller.start();
    events.addError(StateError('capture failed'));
    await Future<void>.delayed(Duration.zero);
    expect(controller.snapshot.phase, PitchPhase.stopFailed);
    expect(controller.snapshot.reading, isNull);
    service.failStop = false;
    controller.dispose();
    await events.close();
    await service.close();
  });
  test(
    'stop clears the result immediately and rejects late service events',
    () async {
      final service = ControlledPitchService();
      final controller = PitchController(service);
      await controller.start();
      service.present(PitchPhase.detected, reading: reading);
      expect(controller.snapshot.reading, reading);
      service.pendingStop = Completer<void>();
      final stop = controller.stop();
      expect(controller.snapshot.phase, PitchPhase.idle);
      expect(controller.snapshot.reading, isNull);
      service.present(PitchPhase.detected, reading: reading);
      expect(controller.snapshot.reading, isNull);
      service.pendingStop!.complete();
      await stop;
      expect(service.snapshot.phase, PitchPhase.idle);
      controller.dispose();
      await service.close();
    },
  );

  test(
    'stop while permission is pending releases a late start again',
    () async {
      final service = ControlledPitchService()
        ..pendingStart = Completer<void>();
      final controller = PitchController(service);
      final start = controller.start();
      expect(controller.snapshot.phase, PitchPhase.requestingPermission);
      final stop = controller.stop();
      expect(controller.snapshot.phase, PitchPhase.idle);
      await controller.start();
      expect(service.starts, 1);
      service.pendingStart!.complete();
      await Future.wait([start, stop]);
      expect(service.stops, 2);
      expect(service.snapshot.phase, PitchPhase.idle);
      expect(controller.snapshot.reading, isNull);
      controller.dispose();
      await service.close();
    },
  );

  test(
    'weak, invalid and stopped snapshots cannot retain the last note',
    () async {
      final service = ControlledPitchService();
      final controller = PitchController(service);
      await controller.start();
      service.present(PitchPhase.detected, reading: reading);
      service.present(PitchPhase.weakSignal, reading: reading);
      expect(controller.snapshot.reading, isNull);
      service.present(
        PitchPhase.detected,
        reading: const PitchReading(
          note: 'A4',
          frequencyHz: double.nan,
          cents: 0,
          direction: PitchDirection.inTune,
        ),
      );
      expect(controller.snapshot.phase, PitchPhase.weakSignal);
      expect(controller.snapshot.reading, isNull);
      service.present(PitchPhase.idle, reading: reading);
      expect(controller.snapshot.reading, isNull);
      controller.dispose();
      await service.close();
    },
  );

  test(
    'missing adapter and failures are reported without fake results',
    () async {
      final unavailable = PitchController(null);
      await unavailable.start();
      expect(unavailable.snapshot.phase, PitchPhase.unavailable);
      unavailable.dispose();
      final service = ControlledPitchService()..failStart = true;
      final controller = PitchController(service);
      await controller.start();
      expect(controller.snapshot.phase, PitchPhase.failed);
      expect(service.stops, greaterThan(0));
      service.failStart = false;
      await controller.start();
      service.present(PitchPhase.detected, reading: reading);
      service.failStop = true;
      await controller.stop();
      expect(controller.snapshot.phase, PitchPhase.stopFailed);
      expect(controller.snapshot.reading, isNull);
      service.failStop = false;
      await controller.toggle();
      expect(controller.snapshot.phase, PitchPhase.idle);
      service.failSettings = true;
      await controller.openSettings();
      expect(controller.settingsFailed, isTrue);
      service.failSettings = false;
      await controller.openSettings();
      expect(controller.settingsFailed, isFalse);
      controller.dispose();
      await service.close();
    },
  );

  test(
    'disposing a listening controller stops capture and clears the snapshot',
    () async {
      final service = ControlledPitchService();
      final controller = PitchController(service);
      await controller.start();
      service.present(PitchPhase.detected, reading: reading);
      controller.dispose();
      await Future<void>.delayed(Duration.zero);
      expect(service.stops, greaterThan(0));
      expect(service.snapshot.phase, PitchPhase.idle);
      expect(controller.snapshot.reading, isNull);
      await service.close();
    },
  );
}

class _FaultPitchService extends ControlledPitchService {
  _FaultPitchService(this.events);
  final StreamController<PitchSnapshot> events;
  @override
  Stream<PitchSnapshot> get changes => events.stream;
}
