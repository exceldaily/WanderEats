# Deployment (Android)

## 1. Release signing

```bash
keytool -genkey -v -keystore %USERPROFILE%\wanderbites-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias wanderbites
```

Create `android/key.properties` (gitignored):

```
storePassword=...
keyPassword=...
keyAlias=wanderbites
storeFile=C:/Users/YOU/wanderbites-release.jks
```

Wire it in `android/app/build.gradle.kts` signingConfigs (template comment lives there). Never commit the keystore or passwords.

## 2. Production environment

Create `dart_defines/prod.json` (gitignored) with the production values and `APP_ENV: "production"`. Same Supabase project/schema; a separate staging schema can be provisioned later if needed.

## 3. Build

```bash
flutter build appbundle --release --dart-define-from-file=dart_defines/prod.json
# output: build/app/outputs/bundle/release/app-release.aab
```

APK for direct install/testing:

```bash
flutter build apk --release --dart-define-from-file=dart_defines/prod.json
```

## 4. Play Console checklist

- App name WanderBites, package com.wanderbites.app
- Data safety: account data (email, profile), user content (photos, text), location (approximate + precise, for map centering), all encrypted in transit, deletable via in-app account deletion
- Restrict the production Maps key to the release SHA-1 as well
- Point Supabase auth redirect URLs at wanderbites://callback

## 5. OTA-free updates

Flutter has no OTA equivalent to Expo Updates; every change ships through a store build. Keep versionCode bumping in pubspec version (x.y.z+N).
