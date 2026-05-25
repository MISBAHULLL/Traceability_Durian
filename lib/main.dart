import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/screens/home_screen.dart';

void main() {
  runApp(
    DevicePreview(
      // Only enable device preview in debug builds so it does not ship to
      // production binaries.
      enabled: !kReleaseMode,
      builder: (context) => const DurianTraceApp(),
    ),
  );
}

class DurianTraceApp extends StatelessWidget {
  const DurianTraceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DurianTrace',
      debugShowCheckedModeBanner: false,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      theme: AppTheme.light(),
      home: const HomeScreen(),
    );
  }
}
