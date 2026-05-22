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
    expect(find.text('앱 잠금'), findsOneWidget);
    expect(find.text('PIN 변경'), findsOneWidget);
  });
}


