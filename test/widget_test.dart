// Smoke test for the DurianTrace landing/login screen.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:traceability_durian/features/auth/screens/home_screen.dart';

void main() {
  testWidgets('Home screen renders welcome content and login form',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: HomeScreen()),
    );

    // Pump a few frames so the entry animation starts
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Selamat Datang'), findsOneWidget);
    expect(find.text('System Traceability Durian\nJawa Timur'), findsOneWidget);
    expect(find.text('Masukan Email / Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('MASUK'), findsAtLeastNWidgets(1));
    expect(find.text('Daftar Disini'), findsOneWidget);
  });
}
