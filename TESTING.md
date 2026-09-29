# Lokale Flutter testing

## Fast quality gate

```bash
flutter analyze
flutter test --coverage
```

## Device integration tests

Integration tests exercise complete user journeys and require a connected
Android/iOS device or emulator. Web execution is not supported by Flutter's
integration-test runner for this project.

```bash
flutter devices
flutter test integration_test/authentication_journey_test.dart -d <device-id>
```

The authentication journey uses a deterministic in-process API gateway. It
checks form entry, request payload normalization, JWT persistence, and the
signed-in callback without modifying a shared backend account.

Future device journeys should cover location permissions, request creation,
nearby matching, notification routing, helper acceptance, and chat delivery.
