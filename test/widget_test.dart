import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flow/main.dart';
import 'package:flow/widgets.dart';

void main() {
  testWidgets('Flow app renders adaptive fixed-card grid layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const FlowApp());
    await tester.pumpAndSettle();

    expect(find.text('폴더'), findsAtLeastNWidgets(1));
    expect(find.text('빠른 시작'), findsWidgets);
    expect(find.text('랜딩 페이지 카피라이팅'), findsOneWidget);
    expect(find.text('최신순'), findsOneWidget);

    final sliverGrid = tester.widget<SliverGrid>(find.byType(SliverGrid).first);
    expect(
      sliverGrid.gridDelegate,
      isA<SliverGridDelegateWithFixedCrossAxisCount>(),
    );
    final delegate =
        sliverGrid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, equals(4));
    expect(delegate.mainAxisExtent, equals(246));

    expect(find.byTooltip('폴더바 닫기'), findsOneWidget);
    await tester.tap(find.byTooltip('폴더바 닫기'));
    await tester.pumpAndSettle();

    final closedGrid = tester.widget<SliverGrid>(find.byType(SliverGrid).first);
    final closedDelegate =
        closedGrid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(closedDelegate.crossAxisCount, equals(5));
    expect(find.byTooltip('폴더바 열기'), findsOneWidget);

    await tester.tap(find.byTooltip('폴더바 열기'));
    await tester.pumpAndSettle();

    final reopenedGrid = tester.widget<SliverGrid>(find.byType(SliverGrid).first);
    final reopenedDelegate =
        reopenedGrid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(reopenedDelegate.crossAxisCount, equals(4));
  });

  testWidgets('Flow app supports desktop search shortcut', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const FlowApp());
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('Folder shortcuts handle long names and remain tappable', (
    tester,
  ) async {
    var tapped = false;
    const folderName = '브랜드 캠페인 콘텐츠 제작용 프롬프트 모음';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: FolderCard(
              name: folderName,
              promptCount: 12,
              isSelected: true,
              onTap: () => tapped = true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(folderName), findsOneWidget);

    await tester.tap(find.byType(FolderCard));
    expect(tapped, isTrue);
  });

  testWidgets('Flow app opens settings sheet', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const FlowApp());
    await tester.pumpAndSettle();

    // Verify settings button exists and tap it
    final settingsButton = find.byIcon(Icons.settings_rounded);
    expect(settingsButton, findsOneWidget);
    await tester.tap(settingsButton);
    await tester.pumpAndSettle();

    // Verify SettingsSheet is displayed
    expect(find.text('다크 모드'), findsOneWidget);
    expect(find.text('터치 진동'), findsOneWidget);
    expect(find.text('앱 잠금'), findsOneWidget);
    expect(find.text('PIN 변경'), findsOneWidget);

    // Verify haptic toggle can be tapped
    await tester.tap(find.text('터치 진동'));
    await tester.pumpAndSettle();
  });

  testWidgets('Flow app enables lock without closing', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const FlowApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings_rounded));
    await tester.pumpAndSettle();

    await tester.tap(
      find.ancestor(
        of: find.text('앱 잠금'),
        matching: find.byType(SwitchListTile),
      ),
    );
    await tester.pumpAndSettle();

    final pinField = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    expect(pinField, findsOneWidget);
    await tester.enterText(pinField, '1234');
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, '확인'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.settings_rounded), findsOneWidget);
    expect(find.byKey(const ValueKey('flow-shell')), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    final rawStore = prefs.getString('flow_store_v1')!;
    expect(rawStore, contains('"lockEnabled":true'));
    expect(rawStore, contains('"pinCode":"1234"'));
  });

  testWidgets('LockScreen lockout after 10 failed attempts', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Set lock screen enabled in SharedPreferences mock setup
    SharedPreferences.setMockInitialValues({
      'flow_store_v1':
          '{"version":1,"prompts":[],"folders":[],"settings":{"darkMode":false,"lockEnabled":true,"pinCode":"1234"}}',
    });

    await tester.pumpWidget(const FlowApp());
    await tester.pumpAndSettle();

    // Verify LockScreen is displayed
    expect(find.text('잠금 해제'), findsOneWidget);

    final pinField = find.byType(TextField);
    expect(pinField, findsOneWidget);

    // Fail 9 times
    for (int i = 0; i < 9; i++) {
      await tester.enterText(pinField, '0000');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('PIN이 일치하지 않습니다. (시도 횟수: ${i + 1}/10)'), findsOneWidget);
    }

    // 10th failure
    await tester.enterText(pinField, '0000');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    // Should be locked out
    expect(find.text('잠금 해제 제한됨'), findsOneWidget);
    expect(find.textContaining('10회 실패로 잠금해제가 제한됩니다.'), findsOneWidget);

    // Try to type correct pin while locked out
    await tester.enterText(pinField, '1234');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    // Should still be on lock screen
    expect(find.text('잠금 해제 제한됨'), findsOneWidget);

    // Fast forward time to check if lockout expires
    await tester.pump(const Duration(seconds: 60));
    await tester.pumpAndSettle();

    // Lockout should expire
    expect(find.text('잠금 해제'), findsOneWidget);
    expect(find.textContaining('10회 실패로'), findsNothing);

    // Enter correct pin now
    await tester.tap(pinField);
    await tester.pumpAndSettle();
    await tester.enterText(pinField, '1234');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    // App should be unlocked (folders page displayed)
    expect(find.text('폴더'), findsOneWidget);
  });
}
