# WanderBites

A social travel map for food discovery. Follow people with great taste (Tasters), discover unforgettable places, and build your own map of the world, one bite at a time.

Not another review directory. The central question is: whose taste do I trust, and where do they recommend eating?

- Flutter (Android first, iOS from the same codebase)
- Supabase backend (schema `wanderbites` inside the shared OrbitStack project)
- Google Maps SDK for the map centerpiece
- Riverpod, GoRouter, Freezed, Drift

Repo: https://github.com/exceldaily/WanderEats

## Quick start

```bash
# 1. Requirements: Flutter (stable), JDK 17, Android SDK 36
flutter doctor

# 2. Configure environment
cp dart_defines/dev.example.json dart_defines/dev.json
#    Fill in SUPABASE_PUBLISHABLE_KEY (Supabase dashboard -> Settings -> API)
#    GOOGLE_MAPS_API_KEY is optional; map shows a notice without it

# 3. Google Maps key for the native Android SDK (optional but needed for the map)
#    android/local.properties -> add: MAPS_API_KEY=your_key

# 4. Run
flutter pub get
flutter run --dart-define-from-file=dart_defines/dev.json
```

## Environment variables

All injected at compile time via `--dart-define-from-file` (never a bundled .env asset):

| Variable | Required | Notes |
|---|---|---|
| SUPABASE_URL | yes | Shared project URL |
| SUPABASE_PUBLISHABLE_KEY | yes | Publishable key (sb_publishable_...), safe on clients, protected by RLS |
| SUPABASE_SCHEMA | yes | `wanderbites` (the app never touches sibling schemas) |
| GOOGLE_MAPS_API_KEY | for map | Also mirror it into android/local.properties as MAPS_API_KEY for the native SDK |
| APP_ENV | yes | development / staging / production |

No service-role keys exist anywhere in this app. See SECURITY.md.

## Supabase setup

The database lives in the shared OrbitStack Supabase project (`pfagkivkytrvbkhsulvo`), schema `wanderbites`. Migrations are in `supabase/migrations/` and are numbered; apply them in order against a clean project (SQL editor or `supabase db push`). Details and the append-safe PostgREST exposure rule are in DATABASE.md.

Seed data (fictional tasters, ~100 restaurants across 10 cities) is `supabase/seed/seed.sql`. Every seeded row is marked (`is_seed = true` on restaurants, seeded profiles use reserved usernames) so it can be cleanly separated from production data.

## Firebase setup (optional right now)

Push, analytics and crashlytics are wired behind interfaces in `lib/core/services/` with dev fallbacks (debug logging, no-op push). To go live:

1. Create a Firebase project, add an Android app with package `com.wanderbites.app`
2. `dart pub global activate flutterfire_cli && flutterfire configure`
3. Uncomment the firebase_* dependencies in pubspec.yaml
4. Swap the provider overrides noted in `lib/core/services/analytics/analytics_service.dart`

## Android permissions

Declared in the manifest, all requested in context at runtime:

- INTERNET: Supabase + images
- ACCESS_FINE_LOCATION / ACCESS_COARSE_LOCATION: center the map on you (app fully works when denied)
- POST_NOTIFICATIONS: push (Android 13+)

## Tests

```bash
flutter test
```

Covers repositories, scoring logic, auth/session flows, navigation and the core user journeys. RLS policy test cases live in `supabase/tests/` and run as SQL against a migrated database.

## Production build

```bash
flutter build apk --release --dart-define-from-file=dart_defines/prod.json
# or app bundle for Play:
flutter build appbundle --release --dart-define-from-file=dart_defines/prod.json
```

Release signing: create `android/key.properties` (see DEPLOYMENT.md). The debug-signed release config in git is for local testing only.

## Docs

- ARCHITECTURE.md: feature-first structure, state, data flow
- DATABASE.md: entities, RPCs, migration order
- SECURITY.md: RLS model, storage rules, what is server-side and why
- SETUP.md: step-by-step machine setup from zero
- DEPLOYMENT.md: release builds, signing, Play prep
- PRODUCT_DECISIONS.md: what got decided and why
