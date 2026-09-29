# Lokale Flutter architecture

Lokale uses a **feature-first layered architecture**. Product domains own their
screens and state, while transport, persistence, notifications, localization,
and reusable UI remain outside those domains. This is a pragmatic modular
monolith: it keeps the application easy to navigate without creating a package
for every small class.

```text
lib/
  app/                    composition root, app lifecycle, theme and navigation
  core/                   contracts plus API, storage, localization and platform adapters
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
  models/                 stable domain entities and API serialization
  shared/                 reusable presentation components
  main.dart               bootstrap and library composition only
```

## Layer boundaries

1. **Application** (`app`) composes dependencies and owns app-wide lifecycle
   state. It may depend on every lower layer.
2. **Presentation** (`features`, `shared`) owns widgets and view state. Features
   depend on `LokaleApi`, not on HTTP, secure storage, or Firebase details.
3. **Domain** (`models`) owns request entities and validation/serialization
   invariants. It has no Flutter UI dependency.
4. **Infrastructure** (`core`) implements network, secure storage, Firebase,
   localization, and device adapters. `ApiClient` implements the `LokaleApi`
   application contract and is replaceable in tests.

Dependency direction is `application -> presentation -> contract/domain`, with
infrastructure supplied by the composition root. A feature must not instantiate
an HTTP client, secure store, Firebase client, or another feature's controller.

## DRY and SOLID rules

- Put an API path and its response mapping in one service/contract method when
  it is used by more than one feature.
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
