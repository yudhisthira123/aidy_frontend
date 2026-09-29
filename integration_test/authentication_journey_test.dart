import 'package:aidy_mobile/application/auth/authentication_service.dart';
import 'package:aidy_mobile/domain/entities/aidy_request.dart';
import 'package:aidy_mobile/domain/gateways/lokale_api.dart';
import 'package:aidy_mobile/presentation/features/auth/auth_screen.dart';
import 'package:aidy_mobile/presentation/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

final class _JourneyApi implements LokaleApi {
  @override
  String get baseUrl => 'https://integration.test';
  @override
  String language = 'en';
  @override
  String? token;
  @override
  void Function()? onUnauthorized;

  Object? submittedBody;

  @override
  Future<dynamic> request(String method, String path, {Object? body}) async {
    submittedBody = body;
    return {
      'token': 'integration-token',
      'user': {'id': 'integration-user', 'name': 'Integration User'},
    };
  }

  @override
  Future<void> saveToken(String value) async => token = value;
  @override
  Future<void> clearToken() async => token = null;
  @override
  Future<void> restore() async {}
  @override
  Future<String?> readLocal(String key) async => null;
  @override
  Future<void> writeLocal(String key, String value) async {}
  @override
  Future<List<AidyRequestModel>> getRequests({
    int limit = 50,
    String? cursor,
  }) async => const [];
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('user can complete the email-password sign-in journey', (
    tester,
  ) async {
    final api = _JourneyApi();
    Map<String, dynamic>? signedInUser;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: AuthScreen(
          authentication: AuthenticationService(api),
          onDone: (user) => signedInUser = user,
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextField, 'Email'),
      'user@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Password'),
      'password',
    );
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(api.token, 'integration-token');
    expect(api.submittedBody, {
      'email': 'user@example.com',
      'password': 'password',
    });
    expect(signedInUser?['id'], 'integration-user');
  });
}
