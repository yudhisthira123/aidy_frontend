import 'package:aidy_mobile/app/config/app_environment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses the production API defaults for ordinary builds', () {
    expect(AppEnvironment.current.flavor, AppFlavor.production);
    expect(AppEnvironment.current.apiBaseUrl, 'https://lokale.onrender.com');
  });
}
