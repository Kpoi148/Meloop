import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/app/meloop_app.dart';
import 'package:meloop/frontend/application/app_settings_controller.dart';
import 'package:meloop/frontend/application/startup_controller.dart';
import 'package:meloop/frontend/components/meloop_ui.dart';
import 'package:meloop/frontend/practice_sessions/practice_session.dart';
import 'package:meloop/frontend/recording/recording_track_player.dart';
import 'package:meloop/frontend/recording/recordings_export.dart';
import 'package:meloop/frontend/recording/recordings_page.dart';
import 'package:meloop/frontend/recording/recordings_visuals.dart';
import 'package:meloop/frontend/recording/recording_ui_state.dart';
import 'package:meloop/frontend/showcase/meloop_ui_showcase.dart';
import 'package:meloop/frontend/showcase/metronome_preview_controller.dart';
import 'package:meloop/frontend/showcase/recording_preview_controller.dart';
import 'package:meloop/frontend/showcase/recordings_playback_preview.dart';
import 'package:meloop/shared/settings/app_settings_store.dart';

const _profile = PreviewInstrumentProfile(
  id: 'recordings-review',
  instrument: MeloopInstrument.guitar,
);
const _records = [
  PracticeSessionRecording(
    id: 'take-one',
    title: 'Luyện gam C · Lần 1',
    duration: Duration(seconds: 84),
  ),
  PracticeSessionRecording(
    id: 'take-two',
    title: 'Luyện gam C · Lần 2',
    duration: Duration(seconds: 58),
  ),
  PracticeSessionRecording(
    id: 'melody',
    title: 'Ý tưởng giai điệu',
    duration: Duration(seconds: 36),
    linkedToJournal: false,
  ),
];

Future<ProviderContainer> _mount(
  WidgetTester tester, {
  List<PracticeSessionRecording> records = _records,
  RecordingExport? export,
  GlobalKey? boundary,
  double scale = 1,
  bool library = false,
  Future<void> Function(PracticeSessionRecording)? onDelete,
}) async {
  var visible = records;
  await tester.pumpWidget(
    MeloopApp(
      overrides: [
        appSettingsStoreProvider.overrideWithValue(
          InMemoryAppSettingsStore(languageCode: 'vi'),
        ),
        startupSnapshotProvider.overrideWithValue(
          const StartupSnapshot(
            profiles: [_profile],
            selectedProfileId: 'recordings-review',
          ),
        ),
        recordingsExportProvider.overrideWithValue(export),
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: RepaintBoundary(key: boundary, child: child!),
      ),
      home: library
          ? const MeloopUiShowcase(developmentTools: false)
          : StatefulBuilder(
              builder: (context, setState) => RepaintBoundary(
                child: RecordingsPage(
                  title: 'Bản ghi âm',
                  recordings: visible,
                  instrument: MeloopInstrument.guitar,
                  onBack: () {},
                  onHome: () {},
                  onRecordPractice: () async {},
                  onDelete: (recording) async {
                    await onDelete?.call(recording);
                    setState(
                      () => visible = visible
                          .where((item) => item.id != recording.id)
                          .toList(),
                    );
                  },
                ),
              ),
            ),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(
    tester.element(find.byType(library ? MeloopUiShowcase : RecordingsPage)),
  );
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    final fonts = FontLoader(TempoType.fontFamily);
    for (final weight in [400, 500, 600, 700]) {
      fonts.addFont(rootBundle.load('assets/fonts/be-vietnam-pro-$weight.ttf'));
    }
    await fonts.load();
    final materialIcons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await materialIcons.load();
  });

  test(
    'playback chooses the correct record, seeks, completes and excludes tools',
    () {
      var now = Duration.zero;
      final scope = ProviderContainer(
        overrides: [recordingPreviewClockProvider.overrideWithValue(() => now)],
      );
      addTearDown(scope.dispose);
      final playback = scope.read(recordingsPlaybackPreviewProvider.notifier);
      final metronome = scope.read(metronomePreviewControllerProvider.notifier);
      final recorder = scope.read(recordingPreviewControllerProvider.notifier);
      metronome.toggle();
      playback.toggle(_records.first);
      expect(scope.read(metronomePreviewControllerProvider).playing, isFalse);
      now = const Duration(seconds: 10);
      playback.refresh();
      expect(
        scope.read(recordingsPlaybackPreviewProvider).position,
        const Duration(seconds: 10),
      );
      playback.seek(_records.first, const Duration(seconds: 40));
      now += const Duration(seconds: 2);
      playback.refresh();
      expect(
        scope.read(recordingsPlaybackPreviewProvider).position,
        const Duration(seconds: 42),
      );
      playback.toggle(_records[1]);
      expect(
        scope.read(recordingsPlaybackPreviewProvider).recordingId,
        'take-two',
      );
      expect(
        scope.read(recordingsPlaybackPreviewProvider).position,
        Duration.zero,
      );
      playback.seek(_records[1], const Duration(minutes: 2));
      expect(scope.read(recordingsPlaybackPreviewProvider).playing, isFalse);
      playback.toggle(_records[1]);
      expect(
        scope.read(recordingsPlaybackPreviewProvider).position,
        Duration.zero,
      );
      recorder.start('active-session', sessionRunning: true);
      expect(scope.read(recordingsPlaybackPreviewProvider).playing, isFalse);
      playback.toggle(_records.first);
      expect(
        recorder.forSession('active-session').phase,
        RecordingPhase.review,
      );
      metronome.toggle();
      expect(scope.read(recordingsPlaybackPreviewProvider).playing, isFalse);
      playback.remove('take-one');
      expect(scope.read(recordingsPlaybackPreviewProvider).recordingId, isNull);
    },
  );

  testWidgets(
    'tools opens the profile library and confirmed delete frees quota',
    (tester) async {
      final scope = await _mount(tester, library: true);
      await _tap(tester, find.text('Công cụ luyện tập'));
      await _tap(tester, find.text('Bản ghi âm'));
      expect(find.byType(RecordingsPage), findsOneWidget);
      expect(find.byType(RecordingTrackPlayer), findsNWidgets(3));
      expect(scope.read(recordingPreviewInputsProvider).quota.savedFiles, 3);
      final player = find.byType(RecordingTrackPlayer).first;
      await _tap(
        tester,
        find.descendant(of: player, matching: find.byTooltip('Nghe lại')),
      );
      final id = scope.read(recordingsPlaybackPreviewProvider).recordingId;
      await _tap(tester, find.byTooltip('Xóa bản ghi').first);
      await _tap(tester, find.text('Hủy'));
      expect(find.byType(RecordingTrackPlayer), findsNWidgets(3));
      expect(scope.read(recordingsPlaybackPreviewProvider).recordingId, id);
      await _tap(tester, find.byTooltip('Xóa bản ghi').first);
      await _tap(tester, find.text('Xóa bản ghi'));
      expect(find.byType(RecordingTrackPlayer), findsNWidgets(2));
      expect(scope.read(recordingsPlaybackPreviewProvider).recordingId, isNull);
      expect(scope.read(recordingPreviewInputsProvider).quota.savedFiles, 2);
      await _tap(tester, find.byTooltip('Quay lại'));
      await _tap(tester, find.text('Bản ghi âm'));
      expect(find.byType(RecordingTrackPlayer), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'cancel export never reports success; original remains after export',
    (tester) async {
      var calls = 0;
      var result = RecordingExportResult.cancelled;
      RecordingExportDestination? usedDestination;
      await _mount(
        tester,
        export: (recording, destination) async {
          expect(recording.id, 'take-one');
          calls++;
          usedDestination = destination;
          return result;
        },
      );
      await _tap(tester, find.text('Xuất bản ghi').first);
      await _tap(tester, find.text('Hủy'));
      expect(calls, 0);
      expect(find.text('Đã xuất bản ghi âm.'), findsNothing);
      await _tap(tester, find.text('Xuất bản ghi').first);
      await _tap(tester, find.text('Chia sẻ bản ghi'));
      expect(calls, 1);
      expect(usedDestination, RecordingExportDestination.share);
      expect(find.text('Đã xuất bản ghi âm.'), findsNothing);
      result = RecordingExportResult.success;
      await _tap(tester, find.text('Xuất bản ghi').first);
      await _tap(tester, find.text('Lưu vào tệp'));
      expect(usedDestination, RecordingExportDestination.saveFile);
      expect(find.text('Đã xuất bản ghi âm.'), findsOneWidget);
      expect(find.text('Luyện gam C · Lần 1'), findsOneWidget);
      expect(find.byType(RecordingTrackPlayer), findsNWidgets(3));
    },
  );

  testWidgets(
    'export failure, unavailable adapter and missing file keep the list',
    (tester) async {
      await _mount(tester);
      await _tap(tester, find.text('Xuất bản ghi').first);
      await _tap(tester, find.text('Lưu vào tệp'));
      expect(find.text('Đã xuất bản ghi âm.'), findsNothing);
      await _mount(
        tester,
        export: (_, _) async => throw StateError('export failed'),
      );
      await _tap(tester, find.text('Xuất bản ghi').first);
      await _tap(tester, find.text('Chia sẻ bản ghi'));
      expect(
        find.text('Chưa thể xuất bản ghi âm. Vui lòng thử lại.'),
        findsOneWidget,
      );
      expect(find.byType(RecordingTrackPlayer), findsNWidgets(3));
      await _mount(
        tester,
        records: const [
          PracticeSessionRecording(
            id: 'missing',
            title: 'Luyện hợp âm',
            duration: Duration(seconds: 60),
            fileAvailable: false,
          ),
        ],
      );
      expect(find.text('01:00 · Tệp không còn trên thiết bị'), findsOneWidget);
      await _mount(
        tester,
        export: (_, _) async => RecordingExportResult.missingFile,
      );
      await _tap(tester, find.text('Xuất bản ghi').first);
      await _tap(tester, find.text('Lưu vào tệp'));
      expect(find.text('01:24 · Tệp không còn trên thiết bị'), findsOneWidget);
      expect(find.byType(RecordingTrackPlayer), findsNWidgets(2));
      await _mount(
        tester,
        records: const [
          PracticeSessionRecording(
            id: 'missing',
            title: 'Luyện hợp âm',
            duration: Duration(seconds: 60),
            fileAvailable: false,
          ),
        ],
      );
      expect(find.text('01:00 · Tệp không còn trên thiết bị'), findsOneWidget);
      expect(find.byType(RecordingTrackPlayer), findsNothing);
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Xuất bản ghi'))
            .onPressed,
        isNull,
      );
      await _tap(tester, find.byTooltip('Xóa bản ghi'));
      await _tap(tester, find.text('Xóa bản ghi'));
      expect(find.text('Chưa có bản ghi âm.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('failed delete retains the file and quota and allows retry', (
    tester,
  ) async {
    var fail = true;
    final scope = await _mount(
      tester,
      onDelete: (_) async {
        if (fail) throw StateError('delete failed');
      },
    );
    await _tap(tester, find.byTooltip('Nghe lại').first);
    await _tap(tester, find.byTooltip('Xóa bản ghi').first);
    await _tap(tester, find.text('Xóa bản ghi'));
    expect(find.text('Thử lại'), findsOneWidget);
    expect(find.text('Luyện gam C · Lần 1'), findsOneWidget);
    expect(scope.read(recordingPreviewInputsProvider).quota.savedFiles, 3);
    expect(scope.read(recordingsPlaybackPreviewProvider).playing, isFalse);
    fail = false;
    await _tap(tester, find.text('Thử lại'));
    expect(find.text('Luyện gam C · Lần 1'), findsNothing);
    expect(scope.read(recordingPreviewInputsProvider).quota.savedFiles, 2);
    expect(find.byType(RecordingTrackPlayer), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'record button stays at the bottom and last recording remains accessible',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 780);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final records = [
        for (var take = 1; take <= 12; take++)
          PracticeSessionRecording(
            id: 'scroll-take-$take',
            title: 'Luyện gam C · Lần $take',
            duration: const Duration(seconds: 84),
          ),
      ];
      await _mount(tester, records: records);
      final button = find.widgetWithText(MeloopButton, 'Ghi âm buổi luyện');
      final position = tester.getRect(button);
      final intro = find.byType(RecordingsIntro);
      final heading = find.descendant(
        of: intro,
        matching: find.text('Lắng nghe\nhành trình của bạn.'),
      );
      final artwork = find.descendant(
        of: intro,
        matching: find.byType(MeloopArt),
      );
      expect(
        tester.getRect(heading).overlaps(tester.getRect(artwork)),
        isFalse,
      );
      final subtitle = find.descendant(
        of: intro,
        matching: find.text('Những âm thanh bạn muốn giữ lại.'),
      );
      final firstCard = tester.getRect(find.byKey(ValueKey(records.first.id)));
      expect(
        firstCard.top - tester.getRect(subtitle).bottom,
        lessThanOrEqualTo(20),
      );
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -1200),
      );
      await tester.pumpAndSettle();
      expect(tester.getRect(button), position);
      final lastCard = find.byKey(ValueKey(records.last.id));
      await tester.ensureVisible(lastCard);
      await tester.pumpAndSettle();
      expect(tester.getRect(button), position);
      expect(tester.getRect(lastCard).bottom, lessThanOrEqualTo(position.top));
      expect(tester.takeException(), isNull);
    },
  );

  for (final sample in [(390.0, 1.0), (320.0, 2.0), (460.0, 1.0)]) {
    testWidgets(
      'list, export, missing and empty visual review ${sample.$1}px ${sample.$2}x',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(sample.$1, 1100 * sample.$2);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        final boundary = GlobalKey();
        await _mount(tester, boundary: boundary, scale: sample.$2);
        await tester.runAsync(() async {
          for (final asset in ['tools-v2.png', 'instruments-v2.png']) {
            await precacheImage(
              AssetImage('assets/illustrations/$asset'),
              boundary.currentContext!,
            );
          }
        });
        await tester.pumpAndSettle();
        Future<void> capture(String name) async {
          expect(tester.takeException(), isNull);
          await tester.runAsync(() async {
            final render =
                boundary.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final snapshot = await render.toImage();
            final bytes = await snapshot.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final directory = Directory('build/uc11-13-review')
              ..createSync(recursive: true);
            File(
              '${directory.path}/flutter-$name-${sample.$1.toInt()}-${sample.$2}.png',
            ).writeAsBytesSync(bytes!.buffer.asUint8List());
            snapshot.dispose();
          });
        }

        await capture('library');
        await _tap(tester, find.text('Xuất bản ghi').first);
        await capture('export');
        await _tap(tester, find.text('Hủy'));
        await _tap(tester, find.byTooltip('Xóa bản ghi').first);
        await capture('delete');
        await _tap(tester, find.text('Hủy'));
        await _mount(
          tester,
          boundary: boundary,
          scale: sample.$2,
          records: const [],
        );
        await capture('empty');
        await _mount(
          tester,
          boundary: boundary,
          scale: sample.$2,
          records: const [
            PracticeSessionRecording(
              id: 'missing-review',
              title: 'Luyện gam C · Lần 1',
              duration: Duration(seconds: 84),
              fileAvailable: false,
            ),
          ],
        );
        await capture('missing');
      },
    );
  }
}
