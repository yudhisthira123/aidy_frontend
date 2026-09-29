# Lokale Flutter architecture

Lokale uses a **feature-first layered architecture**. Product domains own their
screens and state, while transport, persistence, notifications, localization,
and reusable UI remain outside those domains. This is a pragmatic modular
monolith: it keeps the application easy to navigate without creating a package
for every small class.

```text
lib/
  app/                    composition root, app lifecycle, theme and navigation
  application/            typed use cases and endpoint orchestration
    auth/                 authentication and session workflows
    admin/                administration queries and mutations
    equipment/            shared-equipment catalog workflows
    messages/             messaging REST contracts and pagination
    profile/              profile, preferences and account lifecycle
    requests/             request discovery, matching and coordination
  domain/                 entities and gateway contracts
  data/                   HTTP and persistence implementations
  infrastructure/         Firebase and device/platform adapters
  presentation/
    features/
    admin/                administrator workflows
    auth/                 registration and sign-in
    capabilities/         matching-profile setup
    equipment/            equipment catalog
    home/                 dashboard
    messages/             channels and direct messages
    news/                 community content
    profile/              profile and capability editing
    requests/             creation, nearby inbox, tracking and details
    localization/         localized system and catalog presentation
    shared/               reusable presentation components
  main.dart               bootstrap and library composition only
```

## Layer boundaries

1. **Application** (`app`) composes dependencies and owns app-wide lifecycle
   state. It may depend on every lower layer.
2. **Application** (`application`) coordinates use cases and application state
   through domain contracts. It contains no widgets, HTTP, Firebase, or storage
   implementation details.
3. **Presentation** (`presentation/features`, `presentation/shared`) owns
   widgets and view state. Screens delegate reusable endpoint orchestration to
   application services and never own response-envelope mapping.
4. **Domain** (`domain`) owns request entities, gateway contracts, and
   validation/serialization
   invariants. It has no Flutter UI dependency.
5. **Data** (`data`) implements domain gateways using HTTP and secure storage.
   `ApiClient` implements `LokaleApi` and remains replaceable in tests.
6. **Infrastructure** (`infrastructure`) contains Firebase and device adapters.
   It receives presentation concerns such as translation as callbacks rather
   than importing the presentation layer.

Dependencies point inward: `presentation -> application/domain` and
`data/infrastructure -> domain`. The app composition root wires the concrete
implementations. A feature must not instantiate an HTTP client, secure store,
Firebase client, or another feature's controller.

These rules are executable. `test/architecture/dependency_rules_test.dart`
fails when an import crosses a forbidden boundary.

## DRY and SOLID rules

- Put an API path and its response mapping in one service/contract method when
  it is used by more than one feature.
- Presentation screens must not contain API URLs. Endpoint paths, methods, and
  response envelopes belong to application services.
- Put reusable visual behavior in `shared`; do not share widgets that still
  contain feature-specific business rules.
- Keep request variants in the single `AidyRequestModel` contract so help,
  lost, and found records cannot drift.
- Depend on `LokaleApi` at feature boundaries (dependency inversion). Tests may
  substitute a fake without platform plugins or a live server.
- Add new behavior by adding a feature/service implementation rather than
  extending the app shell with endpoint-specific conditionals.
- Keep classes responsible for one concern; split a file when presentation,
  transport, and serialization logic begin to mix.

## Quality gates

Every pull request runs formatting, `flutter analyze`, unit/widget tests with
LCOV, an 80% changed-line coverage gate, and a debug Android build. SonarQube
consumes the same LCOV report when its repository secrets are configured.

Overall coverage is reported separately from changed-line coverage. The ported
legacy UI currently has a low overall baseline, so new and changed executable
lines must remain at or above 80% while feature coverage is raised
incrementally. Do not lower the gate to make a pull request pass.
