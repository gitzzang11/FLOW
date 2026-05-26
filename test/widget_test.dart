import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flow/main.dart';

void main() {
  testWidgets('Flow app renders main shell in 2-column grid layout', (tester) async {
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

    // Verify gridDelegate is SliverGridDelegateWithFixedCrossAxisCount with crossAxisCount: 2
    final sliverGrid = tester.widget<SliverGrid>(find.byType(SliverGrid).first);
    expect(sliverGrid.gridDelegate, isA<SliverGridDelegateWithFixedCrossAxisCount>());
    final delegate = sliverGrid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, equals(2));
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

  testWidgets('LockScreen lockout after 10 failed attempts', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Set lock screen enabled in SharedPreferences mock setup
    SharedPreferences.setMockInitialValues({
      'flow_store_v1': '{"version":1,"prompts":[],"folders":[],"settings":{"darkMode":false,"lockEnabled":true,"pinCode":"1234"}}'
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


