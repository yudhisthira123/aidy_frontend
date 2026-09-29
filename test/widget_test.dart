import 'package:aidy_mobile/main.dart';
import 'package:aidy_mobile/presentation/localization/app_localizations.dart';
import 'package:aidy_mobile/presentation/localization/localized_text.dart'
    as localized;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows Lokale while restoring the session', (tester) async {
    await tester.pumpWidget(const AidyApp());
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Lokale'), findsOneWidget);
  });

  test('all static option keys resolve in every supported language', () {
    for (final locale in AppLocalizations.supportedLocales) {
      final translations = AppLocalizations(Locale(locale.languageCode));
      for (final key in AppLocalizations.supportedStaticOptionKeys) {
        expect(translations.enumValue(key), isNotEmpty);
        expect(translations.enumValue(key), isNot(key));
      }
    }
  });

  test('all static content keys exist in every supported language', () {
    for (final locale in AppLocalizations.supportedLocales) {
      final translations = AppLocalizations(Locale(locale.languageCode));
      for (final key in AppLocalizations.supportedStaticContentKeys) {
        expect(
          translations.hasStaticContentTranslation(key),
          isTrue,
          reason: '${locale.languageCode} is missing "$key"',
        );
      }
    }
  });

  testWidgets('localized system text remains readable in dark mode', (
    tester,
  ) async {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6757D9),
      brightness: Brightness.dark,
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(colorScheme: scheme, brightness: Brightness.dark),
        home: const Scaffold(
          body: localized.Text(
            'Nearby notifications',
            style: TextStyle(color: Color(0xFF1B1D36)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Benachrichtigungen in der Nähe'), findsOneWidget);
    final rendered = tester.widget<Text>(
      find.text('Benachrichtigungen in der Nähe'),
    );
    expect(rendered.style?.color, scheme.onSurface);
  });

  testWidgets('input labels and hints use the selected language', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: Builder(
            builder: (context) => TextField(
              decoration: localized.localizedInput(
                context,
                const InputDecoration(
                  labelText: 'Location label',
                  hintText: 'Address or landmark',
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Standortbezeichnung'), findsOneWidget);
    expect(find.text('Adresse oder Orientierungspunkt'), findsOneWidget);
  });

  test(
    'dynamic notification feedback is localized without changing counts',
    () {
      const translations = AppLocalizations(Locale('de'));
      expect(
        translations.t('2 nearby devices notified successfully.'),
        '2 Geräte in der Nähe erfolgreich benachrichtigt.',
      );
      expect(
        translations.t('Test notification sent to 1 device.'),
        'Testbenachrichtigung an 1 Gerät gesendet.',
      );
    },
  );
}
