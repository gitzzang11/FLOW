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

    expect(find.text('폴더'), findsOneWidget);
    expect(find.text('빠른 시작'), findsWidgets);
    expect(find.text('랜딩 페이지 카피라이팅'), findsOneWidget);
    expect(find.text('최신순'), findsOneWidget);
  });
}
