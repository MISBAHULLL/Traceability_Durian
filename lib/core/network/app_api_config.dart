import 'package:flutter/foundation.dart';

import '../config/app_environment.dart';

class AppApiConfig {
  AppApiConfig._();

  static const String _defaultEnvironmentLabel = 'dev';
  static const String _androidDevBaseUrl = 'http://10.0.2.2:8000/api';
  static const String _desktopDevBaseUrl = 'http://127.0.0.1:8000/api';
  static const String _webDevBaseUrl = 'http://localhost:8000/api';
  static const String _prodBaseUrl = 'http://fauzanilyasalmeyda.space/api';

  /// Label environment aktif untuk menentukan backend yang dipakai.
  ///
  /// Bisa diubah lewat:
  /// `--dart-define=APP_ENV=dev`
  /// atau
  /// `--dart-define=APP_ENV=prod`
  static const String environmentLabel = String.fromEnvironment(
    'APP_ENV',
    defaultValue: _defaultEnvironmentLabel,
  );

  /// Base URL API tunggal untuk seluruh aplikasi.
  ///
  /// Prioritas:
  /// 1. `--dart-define=API_BASE_URL=...` jika diberikan
  /// 2. `APP_ENV=dev` atau `APP_ENV=prod`
  static const String _explicitBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get baseUrl {
    final explicitBaseUrl = _explicitBaseUrl.trim();
    if (explicitBaseUrl.isNotEmpty) {
      return explicitBaseUrl;
    }

    return switch (AppEnvironmentX.fromLabel(environmentLabel)) {
      AppEnvironment.dev => _devBaseUrlForPlatform(),
      AppEnvironment.prod => _prodBaseUrl,
    };
  }

  static String _devBaseUrlForPlatform() {
    if (kIsWeb) {
      return _webDevBaseUrl;
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => _androidDevBaseUrl,
      _ => _desktopDevBaseUrl,
    };
  }

  /// Environment yang sedang aktif setelah label dinormalisasi.
  static AppEnvironment get environment =>
      AppEnvironmentX.fromLabel(environmentLabel);

  /// Bangun URI lengkap dari path endpoint yang relatif.
  /// Contoh: `AppApiConfig.uri('/register')`.
  static Uri uri(String path) {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$normalizedBase$normalizedPath');
  }
}

class AuthEndpoints {
  AuthEndpoints._();

  static const String register = '/register';
  static const String login = '/login';
  static const String me = '/me';
  static const String logout = '/logout';
}
