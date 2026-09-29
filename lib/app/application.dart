part of "../main.dart";

class DeviceSettings {
  static const channel = MethodChannel('lokale/device_settings');
  static Future<void> open(String section) async {
    if (Platform.isAndroid) {
      await channel.invokeMethod(section);
    } else if (Platform.isIOS) {
      await launchUrl(Uri.parse('app-settings:'));
    }
  }
}

class AidyApp extends StatefulWidget {
  const AidyApp({super.key});
  @override
  State<AidyApp> createState() => _AidyAppState();
}

class _AidyAppState extends State<AidyApp> with WidgetsBindingObserver {
  final api = ApiClient();
  final navigatorKey = GlobalKey<NavigatorState>();
  late final NotificationService notifications = NotificationService(api);
  Map<String, dynamic>? user;
  bool loading = true;
  bool darkMode = false;
  String language = 'en';
  String notificationStatus = 'Configuring notifications…';
  AuthorizationStatus notificationPermission =
      AuthorizationStatus.notDetermined;
  bool notificationPromptOpen = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    api.onUnauthorized = () {
      if (mounted) setState(() => user = null);
    };
    bootstrap();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && user != null) {
      unawaited(configureNotifications());
    }
  }

  Future<void> bootstrap() async {
    try {
      darkMode = await api.readLocal('lokale_dark_mode') == 'true';
      language = await api.readLocal('lokale_language') ?? 'en';
      api.language = language;
      await notifications.initialize();
      await api.restore();
      if (api.token != null) {
        final r = await api.request('GET', '/api/auth/me');
        user = Map<String, dynamic>.from(r['user']);
        await configureNotifications();
      }
    } catch (_) {}
    if (mounted) {
      setState(() => loading = false);
      scheduleNotificationPrompt();
    }
  }

  Future<void> setDarkMode(bool value) async {
    await api.writeLocal('lokale_dark_mode', '$value');
    if (mounted) setState(() => darkMode = value);
  }

  Future<void> setLanguage(String value) async {
    await api.writeLocal('lokale_language', value);
    api.language = value;
    if (mounted) setState(() => language = value);
  }

  void signedIn(Map<String, dynamic> next) {
    unawaited(completeSignIn(next));
  }

  Future<void> completeSignIn(Map<String, dynamic> next) async {
    setState(() {
      user = next;
      loading = true;
      notificationStatus = 'Preparing nearby alerts…';
    });
    await configureNotifications();
    if (mounted) {
      setState(() => loading = false);
      scheduleNotificationPrompt();
    }
  }

  Future<void> configureNotifications({bool requestPermission = false}) async {
    try {
      final coordinates = user?['primaryLocation']?['coordinates'] as List?;
      if (coordinates != null && coordinates.length == 2) {
        await api.request(
          'PUT',
          '/api/users/me/location',
          body: {
            'latitude': (coordinates[1] as num).toDouble(),
            'longitude': (coordinates[0] as num).toDouble(),
            'source': 'manual',
          },
        );
      }
      final permission = await notifications.permissionStatus();
      notificationPermission = permission;
      if (!notifications.permissionGranted(permission) && !requestPermission) {
        await notifications.unregisterCurrentDevice();
        if (mounted) {
          setState(
            () => notificationStatus = permission == AuthorizationStatus.denied
                ? 'Notifications are off. Turn them on to receive nearby help alerts.'
                : 'Enable notifications to receive nearby help alerts.',
          );
        }
        return;
      }
      await notifications.register(requestPermission: requestPermission);
      notificationPermission = await notifications.permissionStatus();
      final readiness = await api.request(
        'GET',
        '/api/users/me/notification-readiness',
      );
      final strings = AppLocalizations(Locale(language));
      final reasons = (readiness['reasons'] as List? ?? [])
          .map((reason) => strings.t(reason.toString()))
          .join(' ');
      final devices = (readiness['devices'] as List? ?? []).length;
      final status = readiness['ready'] == true
          ? 'Nearby alerts ready · $devices device${devices == 1 ? '' : 's'}'
          : 'Setup needed: ${reasons.isEmpty ? 'refresh your location and notification permission.' : reasons}';
      if (mounted) setState(() => notificationStatus = status);
    } catch (error) {
      if (mounted) {
        setState(
          () => notificationStatus = 'Notifications need attention: $error',
        );
      }
    }
  }

  void scheduleNotificationPrompt() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(offerNotificationPermission());
    });
  }

  Future<void> offerNotificationPermission() async {
    if (!mounted || user == null || notificationPromptOpen) return;
    final status = await notifications.permissionStatus();
    notificationPermission = status;
    if (notifications.permissionGranted(status)) return;
    final previous = int.tryParse(
      await api.readLocal('lokale_notification_prompt_at') ?? '',
    );
    final now = DateTime.now().millisecondsSinceEpoch;
    if (previous != null &&
        now - previous < const Duration(days: 3).inMilliseconds) {
      return;
    }
    await api.writeLocal('lokale_notification_prompt_at', '$now');
    final dialogContext = navigatorKey.currentContext;
    if (dialogContext == null || !dialogContext.mounted || !mounted) return;
    notificationPromptOpen = true;
    final proceed = await showDialog<bool>(
      context: dialogContext,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.notifications_active_outlined, size: 38),
        title: const Text('Stay informed nearby'),
        content: const Text(
          'Lokale uses notifications for nearby help requests, helper responses, arrival updates, and chat activity. We do not use them for advertising, and you can change this anytime in device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              status == AuthorizationStatus.notDetermined
                  ? 'Continue'
                  : 'Open settings',
            ),
          ),
        ],
      ),
    );
    notificationPromptOpen = false;
    if (proceed != true) return;
    if (status == AuthorizationStatus.notDetermined) {
      await configureNotifications(requestPermission: true);
    } else {
      await DeviceSettings.open('notifications');
    }
  }

  Future<void> logout() async {
    try {
      await api.request('POST', '/api/auth/logout');
    } catch (_) {}
    await api.clearToken();
    setState(() => user = null);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorKey: navigatorKey,
    debugShowCheckedModeBanner: false,
    title: 'Lokale',
    locale: Locale(language),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
    darkTheme: ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: green,
        brightness: Brightness.dark,
        primary: const Color(0xFFB7A9FF),
        secondary: const Color(0xFFFF9B91),
        surface: const Color(0xFF1B1D2B),
      ),
      scaffoldBackgroundColor: const Color(0xFF11121E),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF11121E),
        foregroundColor: Color(0xFFF4F1FF),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Color(0xFFF4F1FF),
          fontSize: 21,
          fontWeight: FontWeight.w800,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Color(0xFF1B1D2B),
        indicatorColor: Color(0xFF39335D),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? const Color(0xFFD5CCFF)
                : const Color(0xFFB8B6C8),
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF1B1D2B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Color(0xFF2C2E42)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        filled: true,
        fillColor: const Color(0xFF222434),
        labelStyle: const TextStyle(color: Color(0xFFD2CFDD)),
        hintStyle: const TextStyle(color: Color(0xFF9E9BAC)),
      ),
    ),
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: green,
        primary: green,
        secondary: coral,
        tertiary: const Color(0xFF18A999),
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: canvas,
      appBarTheme: const AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: brand,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: brand,
          fontSize: 21,
          fontWeight: FontWeight.w800,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 76,
        backgroundColor: Colors.white,
        indicatorColor: softMint,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? green
                : const Color(0xFF76758A),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE4E1ED)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE4E1ED)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: green, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0.5,
        margin: EdgeInsets.zero,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Color(0xFFE8E5F0)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: const BorderSide(color: Color(0xFFD8D3E8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    ),
    home: loading
        ? const Splash()
        : user == null
        ? AuthScreen(api: api, onDone: signedIn)
        : ((user!['onboarding']?['status'] ?? 'incomplete') == 'incomplete'
              ? CapabilitiesScreen(
                  api: api,
                  user: user!,
                  onDone: signedIn,
                  onLogout: logout,
                )
              : HomeShell(
                  api: api,
                  user: user!,
                  notificationStatus: notificationStatus,
                  notificationsEnabled: notifications.permissionGranted(
                    notificationPermission,
                  ),
                  notificationRequest: notifications.openedRequest,
                  notificationConversation: notifications.openedConversation,
                  onNotificationsRefresh: configureNotifications,
                  darkMode: darkMode,
                  onDarkMode: setDarkMode,
                  language: language,
                  onLanguage: setLanguage,
                  onUser: signedIn,
                  onLogout: logout,
                )),
  );
}

class Splash extends StatelessWidget {
  const Splash({super.key});
  @override
  Widget build(BuildContext c) => const Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BrandLogo(size: 82),
          SizedBox(height: 12),
          Text(
            'Lokale',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: brand,
            ),
          ),
          SizedBox(height: 24),
          CircularProgressIndicator(),
        ],
      ),
    ),
  );
}

class BrandLogo extends StatelessWidget {
  final double size;
  const BrandLogo({super.key, required this.size});
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    padding: EdgeInsets.all(size * .08),
    decoration: BoxDecoration(
      color: const Color(0xFFF3F8F6),
      borderRadius: BorderRadius.circular(size * .24),
    ),
    child: Image.asset(
      'assets/branding/lokale-app-icon.png',
      fit: BoxFit.contain,
    ),
  );
}
