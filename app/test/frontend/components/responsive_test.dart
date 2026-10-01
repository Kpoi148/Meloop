import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/app/meloop_app.dart';
import 'package:meloop/frontend/application/startup_controller.dart';
import 'package:meloop/frontend/components/meloop_ui.dart';
import 'package:meloop/frontend/showcase/component_catalog.dart';
import 'package:meloop/frontend/showcase/home_example.dart';
import 'package:meloop/frontend/showcase/instrument_profiles_example.dart';
import 'package:meloop/frontend/showcase/session_form_example.dart';
import 'package:meloop/frontend/showcase/settings_example.dart';
import 'package:meloop/frontend/showcase/setup_example.dart';
import 'package:meloop/frontend/showcase/welcome_example.dart';

Widget harness(Widget screen, {double scale = 1, double keyboard = 0}) =>
    MeloopApp(
      key: UniqueKey(),
      home: screen,
      // Override above the Navigator so dialogs and sheets inherit the same metrics.
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          padding: const EdgeInsets.only(top: 24, bottom: 24),
          viewPadding: const EdgeInsets.only(top: 24, bottom: 24),
          viewInsets: EdgeInsets.only(bottom: keyboard),
        ),
        child: child!,
      ),
    );

void main() {
  for (final width in [320.0, 390.0, 460.0]) {
    for (final scale in [1.0, 2.0, 3.0]) {
      testWidgets(
        'sample screens fit $width px at ${scale}x text with keyboard and safe areas',
        (tester) async {
          tester.view.physicalSize = Size(width, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final screens = <Widget>[
            MeloopPage(
              bottomNavigation: MeloopBottomNavigation(
                selectedIndex: 0,
                onSelected: (_) {},
              ),
              child: HomeExample(
                onCreate: () {},
                onHistory: () {},
                onCatalog: () {},
              ),
            ),
            const WelcomeExample(),
            SetupExample(onSave: (_) async {}),
            SessionFormExample(onSave: (_) async {}),
            MeloopPage(
              bottomNavigation: MeloopBottomNavigation(
                selectedIndex: 3,
                onSelected: (_) {},
              ),
              child: SettingsExample(
                profile: const PreviewInstrumentProfile(
                  id: 'guitar-preview',
                  instrument: MeloopInstrument.guitar,
                ),
                language: 'Tiếng Việt',
                onLanguage: () {},
              ),
            ),
            InstrumentProfilesExample(
              profiles: const [
                PreviewInstrumentProfile(
                  id: 'guitar-preview',
                  name: 'Guitar của tôi',
                  instrument: MeloopInstrument.guitar,
                ),
                PreviewInstrumentProfile(
                  id: 'piano-preview',
                  name: 'Piano buổi tối',
                  instrument: MeloopInstrument.piano,
                ),
                PreviewInstrumentProfile(
                  id: 'violin-preview',
                  name: 'Violin của tôi',
                  instrument: MeloopInstrument.violin,
                ),
              ],
              selectedProfileId: 'guitar-preview',
              archivedProfileIds: const {'violin-preview'},
              onBack: () {},
              onHome: () {},
              onAdd: () {},
            ),
            const ComponentCatalog(),
          ];
          for (final screen in screens) {
            for (final keyboard in [0.0, 300.0]) {
              await tester.pumpWidget(
                harness(screen, scale: scale, keyboard: keyboard),
              );
              await tester.pump(const Duration(milliseconds: 100));
              expect(
                tester.takeException(),
                isNull,
                reason: '${screen.runtimeType}, keyboard=$keyboard',
              );
              if (screen is MeloopPage && keyboard > 0) {
                expect(find.byType(MeloopBottomNavigation), findsNothing);
              }
              final scrollable = tester.state<ScrollableState>(
                find.byType(Scrollable).first,
              );
              scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
              await tester.pump();
              expect(
                tester.takeException(),
                isNull,
                reason: '${screen.runtimeType} at bottom',
              );
              expect(scrollable.position.extentAfter, 0);
            }
          }
        },
      );
    }
  }
  for (final keyboard in [0.0, 280.0]) {
    testWidgets(
      'large-text dialog and sheet scroll at keyboard inset $keyboard',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          harness(
            Builder(
              builder: (context) => MeloopPage(
                child: Column(
                  children: [
                    MeloopButton(
                      label: 'Hộp thoại',
                      onPressed: () async {
                        await showMeloopConfirm(
                          context,
                          title: 'Bỏ thay đổi chưa lưu?',
                          message: 'Nội dung của bạn vẫn ở đây. ' * 5,
                          confirmLabel: 'Bỏ thay đổi',
                          cancelLabel: 'Tiếp tục sửa',
                        );
                      },
                    ),
                    MeloopButton(
                      label: 'Bảng lựa chọn',
                      onPressed: () async {
                        await showMeloopSheet<void>(
                          context,
                          title: 'Thông tin buổi luyện',
                          child: Text('Nội dung dài. ' * 100),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            scale: 3,
            keyboard: keyboard,
          ),
        );
        await tester.tap(find.text('Hộp thoại'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('Tiếp tục sửa'));
        await tester.tap(find.text('Tiếp tục sửa'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Bảng lựa chọn'));
        await tester.tap(find.text('Bảng lựa chọn'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull);
        final sheetScrollable = tester.state<ScrollableState>(
          find.byType(Scrollable).last,
        );
        sheetScrollable.position.jumpTo(
          sheetScrollable.position.maxScrollExtent,
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
