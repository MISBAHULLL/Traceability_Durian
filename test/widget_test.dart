// Smoke test for the DurianTrace landing/login screen.

import 'package:flutter_test/flutter_test.dart';

import 'package:traceability_durian/main.dart';

void main() {
  testWidgets('Home screen renders welcome content and login form',
      (WidgetTester tester) async {
    await tester.pumpWidget(const DurianTraceApp());

    expect(find.text('Selamat Datang'), findsOneWidget);
    expect(find.text('System Traceability Durian\nJawa Timur'), findsOneWidget);
    expect(find.text('Masukan Email / Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('MASUK'), findsOneWidget);
    expect(find.text('Daftar Disini'), findsOneWidget);
  });
}
