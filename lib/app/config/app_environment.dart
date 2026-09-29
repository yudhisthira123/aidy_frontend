enum AppFlavor { development, staging, production }

final class AppEnvironment {
  const AppEnvironment({required this.flavor, required this.apiBaseUrl});

  final AppFlavor flavor;
  final String apiBaseUrl;

  static AppEnvironment get current {
    const flavorName = String.fromEnvironment(
      'APP_FLAVOR',
      defaultValue: 'production',
    );
    const apiBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://lokale.onrender.com',
    );
    return AppEnvironment(
      flavor: switch (flavorName) {
        'development' => AppFlavor.development,
        'staging' => AppFlavor.staging,
        _ => AppFlavor.production,
      },
      apiBaseUrl: apiBaseUrl.replaceFirst(RegExp(r'/$'), ''),
    );
  }
}
