# Lokale Mobile

Flutter Android/iOS client for the Lokale neighbourhood-help platform, powered by the existing AIDY API.

Source layout, layer boundaries, and DRY/SOLID contribution rules are documented
in [ARCHITECTURE.md](ARCHITECTURE.md).
The measured quality baseline and definition of done are in
[QUALITY.md](QUALITY.md).
Static analysis and coverage upload are configured in [sonar-project.properties](sonar-project.properties).

## Features

- Email/password registration, login, JWT persistence, session restoration and logout
- Resumable User Capabilities plus direct editing of skills, equipment, saved places, availability and help preferences
- API-driven categories and subcategories
- Urgent help, local support, and lost/found request creation with validation and review
- GPS or manual OpenStreetMap location selection and external navigation
- Personal request list, lifecycle controls, confirmed deletion and automatically refreshed chat
- Nearby helper inbox with accept/reject, ETA, live refresh and proximity location updates
- Dark mode, notification-tap routing, build identification and resilient network errors
- Notification readiness diagnostics, automatic PostGIS location sync, delivery summaries and an on-device Firebase self-test
- Admin-only management for users, requests, equipment, categories and subcategories
- Location permissions and PostGIS-ready coordinate submission
- Firebase packages installed and backend push-token APIs ready for platform configuration

## Run

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=https://lokale.onrender.com
```

Use explicit flavors so local, staging, and production builds never depend on
source edits:

```bash
flutter run \
  --dart-define=APP_FLAVOR=development \
  --dart-define=API_BASE_URL=http://localhost:3000

flutter build apk --release \
  --dart-define=APP_FLAVOR=production \
  --dart-define=API_BASE_URL=https://lokale.onrender.com
```

## Optimized Android release

```bash
flutter build apk --release --split-per-abi \
  --dart-define=API_BASE_URL=https://lokale.onrender.com
```

Use the ARM64 output for most current Android phones. Configure a private release signing key before store distribution.

## Firebase

The project runs without Firebase configuration. To enable native push notifications, add the Android `google-services.json` and iOS `GoogleService-Info.plist`, configure FlutterFire, then initialize Firebase and register the FCM token using `PUT /api/users/me/push-token`.

Do not commit Firebase Admin service-account JSON. Mobile configuration files identify the Firebase project, but server credentials must remain in Render environment variables.

## Quality checks

```bash
dart format --output=none --set-exit-if-changed lib test tool
flutter analyze
flutter test --coverage
dart run tool/check_diff_coverage.dart
```

The local gate requires at least 80% coverage on changed Dart lines. Overall
coverage is also published as a visible baseline and must rise incrementally;
it is not used as a substitute for changed-line coverage. SonarQube supplies
the final remote ratings and hotspot review.

## API

- Swagger: https://lokale.onrender.com/api/docs/
- OpenAPI: https://lokale.onrender.com/api/openapi.json
