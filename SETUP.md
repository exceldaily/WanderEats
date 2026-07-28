# Setup (from a clean Windows machine)

## 1. Toolchain

```bash
# Flutter
git clone --depth 1 -b stable https://github.com/flutter/flutter.git %USERPROFILE%\dev\flutter
# add %USERPROFILE%\dev\flutter\bin to PATH

# JDK 17
winget install Microsoft.OpenJDK.17

# Android SDK (no Android Studio needed)
# download commandlinetools from https://developer.android.com/studio#command-line-tools-only
# unzip to %USERPROFILE%\dev\android-sdk\cmdline-tools\latest
sdkmanager "platform-tools" "platforms;android-36" "build-tools;36.0.0"
sdkmanager --licenses

flutter config --android-sdk %USERPROFILE%\dev\android-sdk
flutter config --jdk-dir "C:\Program Files\Microsoft\jdk-17..."
flutter doctor   # Android toolchain must be green
```

## 2. Project

```bash
git clone https://github.com/exceldaily/WanderEats.git wanderbites
cd wanderbites
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

## 3. Environment

```bash
cp dart_defines/dev.example.json dart_defines/dev.json
```

Fill in:
- SUPABASE_URL: https://pfagkivkytrvbkhsulvo.supabase.co
- SUPABASE_PUBLISHABLE_KEY: Supabase dashboard -> Project Settings -> API keys -> publishable
- GOOGLE_MAPS_API_KEY: see step 5 (optional to start)

## 4. Database

Migrations in `supabase/migrations/` run in numeric order against the shared project (already applied there). For a brand new project: run 0001 through 0005 in the SQL editor, then `supabase/seed/seed.sql` for development data.

## 5. Google Cloud project (already provisioned)

Project `wanderbites-503816` exists in the exceldaily7 Google account with:
- OAuth consent screen configured (External, app name WanderBites)
- OAuth 2.0 Web client "WanderBites Web Client" with redirect URI `https://pfagkivkytrvbkhsulvo.supabase.co/auth/v1/callback`, credentials enabled as the Google provider in the shared Supabase project (Google sign-in works end to end)
- Firebase attached to the same project (Spark/free plan), Android app registered as `com.wanderbites.app`

`android/app/google-services.json` is gitignored; pull a fresh copy from the Firebase console (Project settings -> your apps -> google-services.json) if it's missing on a new machine. Without it the app still builds and runs with the debug-log analytics and no-op push fallbacks.

## 5b. Auth emails (done July 28 2026)

The shared Supabase project sends auth emails (confirmations, resets) through
Brevo custom SMTP: host smtp-relay.brevo.com:587, login ae4300001@smtp-brevo.com,
sender noreply@phase-forge.com ("OrbitStack Apps"), key named "Supabase Shared
Auth" in the Brevo dashboard. Rate limit is 30 auth emails/hour (adjustable in
Supabase Auth -> Rate Limits). Note: signing up with an email that already has
an account in the shared pool intentionally sends nothing (anti-enumeration) —
those users must sign in instead.

## 6. Google Maps key (the one manual step left)

Maps SDK for Android could not be enabled without a billing account attached to `wanderbites-503816` — that's a payment step only the account owner can complete.

1. https://console.cloud.google.com/billing?project=wanderbites-503816 -> attach or create a billing account
2. https://console.cloud.google.com/apis/library/maps-android-backend.googleapis.com?project=wanderbites-503816 -> Enable
3. https://console.cloud.google.com/google/maps-apis/credentials?project=wanderbites-503816 -> create an API key, restrict it to Android apps with package `com.wanderbites.app` plus your release SHA-1 (get it with `cd android && ./gradlew signingReport`, or from Firebase project settings once the app is registered)
4. Put the key in two places:
   - `dart_defines/dev.json` -> GOOGLE_MAPS_API_KEY (runtime feature checks)
   - `android/local.properties` -> `MAPS_API_KEY=...` (native SDK)

Everything else in the app works without this; only the map tab shows a setup notice until it's done.

## 7. Run

```bash
flutter run --dart-define-from-file=dart_defines/dev.json
flutter test
```
