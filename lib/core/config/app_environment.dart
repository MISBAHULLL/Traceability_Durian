enum AppEnvironment {
  dev,
  prod,
}

extension AppEnvironmentX on AppEnvironment {
  static AppEnvironment fromLabel(String label) {
    switch (label.trim().toLowerCase()) {
      case 'prod':
      case 'production':
        return AppEnvironment.prod;
      case 'dev':
      case 'development':
      default:
        return AppEnvironment.dev;
    }
  }

  String get label {
    switch (this) {
      case AppEnvironment.dev:
        return 'dev';
      case AppEnvironment.prod:
        return 'prod';
    }
  }
}
