# Quality baseline

Recorded on 2026-09-29 after migrating the complete Lokale mobile client.

| Check | Result |
| --- | --- |
| Dart formatting | Pass |
| Flutter analyzer | Pass, zero findings |
| Unit and widget tests | 19 passed |
| Overall executable-line coverage | 349 / 3,761 (9.28%) |
| Android debug compilation | Pass |

The coverage number is an honest legacy baseline, not a target. Most uncovered
code is widget orchestration and platform integration. The repository enforces
80% coverage for subsequently changed executable lines so new work cannot add
another large untested surface. Coverage should be expanded feature by feature,
starting with authentication, request creation, nearby matching, notification
registration, and messaging.

## Definition of done

A change is ready to merge only when:

1. `dart format --output=none --set-exit-if-changed lib test tool` passes.
2. `flutter analyze` reports no findings.
3. `flutter test --coverage` passes.
4. `dart run tool/check_diff_coverage.dart` reports at least 80% for changed
   executable lines.
5. `flutter build apk --debug` completes.
6. SonarQube's quality gate passes when repository credentials are configured.

Do not exclude production code from LCOV or SonarQube merely to improve the
percentage. Platform-generated Firebase options and the static translation
catalog are the only deliberate exclusions.
