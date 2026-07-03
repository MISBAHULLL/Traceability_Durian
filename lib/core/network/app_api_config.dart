class AppApiConfig {
  AppApiConfig._();

  static const String _fallbackBaseUrl = 'http://fauzanilyasalmeyda.space/api';

  /// Base URL API tunggal untuk seluruh aplikasi.
  ///
  /// Bisa dioverride saat build dengan:
  /// `--dart-define=API_BASE_URL=http://192.168.1.10:8000/api`
  static String get baseUrl => const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _fallbackBaseUrl,
  );

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
