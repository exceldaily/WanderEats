# Architecture

Feature-first Flutter app. Rule number one: no backend calls inside widgets, ever.

```text
lib/
  app/                 wiring: app widget, router, theme, env config
    router/            GoRouter + StatefulShellRoute (5 preserved tabs)
    theme/             design tokens (wb_tokens) + Material 3 themes (wb_theme)
    configuration/     Env (compile-time dart-defines)
  core/                cross-feature building blocks
    errors/            AppException hierarchy (sealed), the only error types UI sees
    networking/        Supabase client + schema-scoped accessor
    services/          analytics, push, crash reporting (interfaces + dev fallbacks)
    location/          geolocation service + permission flow
    storage/           Drift offline cache, image upload helpers
    widgets/           WbEmptyState, WbErrorState, WbSkeleton, shared cards
  features/<name>/
    data/              repositories + DTO mapping (only layer touching Supabase)
    domain/            Freezed models, pure logic
    presentation/      screens, controllers (Riverpod Notifiers), widgets
```

## Layers and flow

UI (ConsumerWidget) -> controller (Notifier / AsyncNotifier) -> repository -> Supabase schema('wanderbites') or Drift cache.

- Repositories return domain models and throw AppException subclasses. They catch PostgrestException / SocketException / StorageException at the boundary.
- Controllers own loading/error/data state via AsyncValue. Optimistic updates (save, follow, like) mutate state first, roll back on failure.
- Providers are the DI graph. Tests override providers (e.g. analyticsProvider, repository providers) with fakes.

## Key decisions

- **Schema isolation**: the app lives in the `wanderbites` schema of a shared Supabase project. `wbSchemaProvider` is the only door; `client.from()` without the schema wrapper is a bug.
- **Replaceable maps/data providers**: `RestaurantDataProvider` is an interface. Phase 1 ships `SeededRestaurantProvider` (Supabase-backed seed data). A GooglePlacesProvider can slot in later without touching feature code. Same for the map widget: map interactions go through a thin controller so the SDK can be swapped.
- **Offline**: Drift caches profile, follows, saves, viewed restaurants and lists. Repositories read cache-first when offline and revalidate online. Drafts (recommendations) persist locally until published.
- **Navigation**: bottom tabs are StatefulShellRoute branches (state preserved). Details (restaurant, taster, list) push over the shell. All routes named in `routes.dart`.
- **Server-side logic**: reputation scoring, trending, bounded map queries and search run as SQL functions (RPCs). The client never computes trust scores.
- **Firebase behind interfaces**: AnalyticsService, PushService, CrashReporter. Dev fallbacks log to console; real implementations activate once `flutterfire configure` has run.

## Codegen

Freezed + json_serializable for models, riverpod_generator for providers, drift_dev for the cache:

```bash
dart run build_runner build --delete-conflicting-outputs
```
