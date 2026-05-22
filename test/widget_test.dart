import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flow/main.dart';

void main() {
  testWidgets('Flow app renders main shell', (tester) async {
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
  });

  testWidgets('Flow app toggles prompt view mode', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const FlowApp());
    await tester.pumpAndSettle();

    // Verify initial layout toggle button text is '원래 배열'
    expect(find.text('원래 배열'), findsOneWidget);
    expect(find.text('2열 배열'), findsNothing);

    // Verify default gridDelegate is SliverGridDelegateWithMaxCrossAxisExtent
    var sliverGrid = tester.widget<SliverGrid>(find.byType(SliverGrid).first);
    expect(sliverGrid.gridDelegate, isA<SliverGridDelegateWithMaxCrossAxisExtent>());

    // Tap layout toggle button
    await tester.tap(find.text('원래 배열'));
    await tester.pumpAndSettle();

    // Verify text changes to '2열 배열'
    expect(find.text('원래 배열'), findsNothing);
    expect(find.text('2열 배열'), findsOneWidget);

    // Verify gridDelegate is now SliverGridDelegateWithFixedCrossAxisCount with crossAxisCount: 2
    sliverGrid = tester.widget<SliverGrid>(find.byType(SliverGrid).first);
    expect(sliverGrid.gridDelegate, isA<SliverGridDelegateWithFixedCrossAxisCount>());
    final delegate = sliverGrid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, equals(2));

    // Tap layout toggle button again to switch back
    await tester.tap(find.text('2열 배열'));
    await tester.pumpAndSettle();

    expect(find.text('원래 배열'), findsOneWidget);
    expect(find.text('2열 배열'), findsNothing);
  });
}

