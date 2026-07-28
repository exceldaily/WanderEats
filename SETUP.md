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

## 5. Google Maps key

1. Google Cloud console -> create/select project -> enable "Maps SDK for Android"
2. Create an API key, restrict it to Android apps with package `com.wanderbites.app` plus your SHA-1 (`cd android && ./gradlew signingReport`)
3. Put the key in two places:
   - `dart_defines/dev.json` -> GOOGLE_MAPS_API_KEY (runtime feature checks)
   - `android/local.properties` -> `MAPS_API_KEY=...` (native SDK)

## 6. Firebase (when ready)

```bash
dart pub global activate flutterfire_cli
flutterfire configure   # package com.wanderbites.app
```
Then uncomment firebase_* in pubspec.yaml. Until then the app uses the built-in dev fallbacks (console analytics, no push).

## 7. Run

```bash
flutter run --dart-define-from-file=dart_defines/dev.json
flutter test
```
