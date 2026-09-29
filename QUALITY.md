# Quality baseline

Recorded on 2026-09-29 after migrating the complete Lokale mobile client.

| Check | Result |
| --- | --- |
| Dart formatting | Pass |
| Flutter analyzer | Pass, zero findings |
| Unit, widget, and architecture tests | 29 passed |
| Overall executable-line coverage | 374 / 3,786 (9.88%) |
| Android debug compilation | Pass |

The coverage number is an honest legacy baseline, not a target. New application
use-case code is fully covered; most remaining uncovered
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
