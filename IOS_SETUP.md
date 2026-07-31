# iOS setup and TestFlight/App Store submission

Written 2026-07-31, before any of this has actually run. Nobody on this
project has a Mac — every build so far has been Android, from Windows. iOS
builds are only possible through Xcode, which only runs on macOS, so this
plan routes through **Codemagic**, a cloud CI service that builds on real
Apple hardware and can publish straight to TestFlight. `codemagic.yaml` at
the repo root is the pipeline; this file is the manual setup around it.

**Nothing in this file has been verified.** It's written from Codemagic's
documented Flutter iOS recipe and from what the codebase actually needs, but
the first real signal is Codemagic's own build log on the first push. Expect
to paste an error back for a fix — that's normal for a first CI setup, not a
sign something was done wrong.

## What's already done in the repo

- `ios/Runner/Info.plist` — camera, photo library and location usage
  descriptions (iOS crashes on first access to any of these without a
  description string; the project had none). Also declares `GMSApiKey`,
  substituted at build time — see below.
- `ios/Runner/AppDelegate.swift` — calls `GMSServices.provideAPIKey(...)` at
  launch, the documented setup step for `google_maps_flutter` on iOS. Reads
  the key from Info.plist rather than hardcoding it.
- `ios/Flutter/Secrets.xcconfig.example` — template for the local-only file
  that holds the iOS Maps key. Codemagic writes the real one at build time;
  it's gitignored and never committed.
- iOS bundle identifier changed from the Flutter-default
  `com.wanderbites.wanderbites` to `com.wanderbites.app`, matching the
  Android package name. Changed now because it's a one-line edit before
  anything exists in App Store Connect — changing it after the app record is
  created would mean starting a new one.
- App icons generated for iOS (`flutter_launcher_icons` had `ios: false`;
  the icon set literally didn't exist). Same source art as Android
  (`branding/source/wanderbites_globe.png`), rendered at the resolutions
  Apple asks for via `branding/ios_icon_1024.png` — a dedicated 1024px
  opaque render, not the Android 512 asset upscaled.

## What only you can do (Apple account, real money, real credentials)

Do these in order — later steps depend on earlier ones existing.

### 1. Apple Developer Program — done

### 2. Codemagic account — done

Repo connected as `exceldaily/WanderEats`.

### 3. App Store Connect API key → Codemagic integration — done

Found under **Settings → Integrations → Developer Portal**, not "Teams →
Integrations → App Store Connect" as Codemagic's own docs say — that path is
for Team accounts, and this is a Personal Account. Connected with the API
Manager key, saved under the name **"Codemagic"**.

`codemagic.yaml`'s `integrations.app_store_connect` value matches that name.
If you ever rename the key or add a second one, that value needs updating to
match — Codemagic references it by exactly that name.

One thing worth flagging from how this went: the first key generated
(`FUBUYZJMFC`) got pasted into a chat with its private key content, which
means treating it as compromised — it was revoked and replaced with a fresh
one (now `4J9V26467`) before connecting. If you ever need to regenerate again,
keep the `.p8` file and its contents out of any chat, ours included; upload it
straight into Codemagic's form instead.

### 4. Create the app record

In App Store Connect → Apps → **+** → New App:

- Platform: iOS
- Bundle ID: `com.wanderbites.app` (register it here if App Store Connect
  hasn't seen it before)
- SKU: anything unique, e.g. `wanderbites-ios`

### 5. A separate Google Maps key for iOS

**Do not reuse the Android Maps key** — its restriction is Android-specific
(package name + SHA-1 fingerprint, the exact mechanism that caused the
blank-map issue on Android). iOS keys are restricted by bundle ID instead.

In the same Google Cloud project as the Android key
(console.cloud.google.com/apis/credentials?project=wanderbites-503816):

1. Create credentials → API key
2. Application restrictions → **iOS apps** → add bundle ID `com.wanderbites.app`
3. API restrictions → **Maps SDK for iOS**
4. Name it something findable, e.g. `WanderBites Maps iOS`

### 6. Codemagic environment variables

Codemagic → this app → Environment variables → new group named
**`wanderbites_prod`** (referenced by `codemagic.yaml`'s `groups:`).  Add,
each marked **Secure**:

| Variable | Value |
|---|---|
| `SUPABASE_URL` | same as `dart_defines/prod.json` |
| `SUPABASE_PUBLISHABLE_KEY` | same as `dart_defines/prod.json` |
| `SUPABASE_SCHEMA` | `wanderbites` |
| `GOOGLE_MAPS_API_KEY_IOS` | the iOS key from step 5 — deliberately a
  different variable name from the Android build's `GOOGLE_MAPS_API_KEY`, so
  the two never get mixed up in a shared CI config |

### 7. Push, and watch the first build

Push to `main`, or trigger a run from the Codemagic dashboard. It builds an
`.ipa` and, if `submit_to_testflight: true` in `codemagic.yaml` stays as-is,
uploads it straight to TestFlight. First Apple processing after upload
usually takes a few minutes to an hour.

## After the first successful build

- **Install via TestFlight** on a real iPhone (the TestFlight app, an invite
  from App Store Connect → TestFlight → internal testers). This is the iOS
  equivalent of the Play internal-testing track — the first time to actually
  see the app run, since nothing here has been run before.
- **Push notifications**, if wanted on iOS: needs an APNs key uploaded to the
  Firebase project (`wanderbites-503816`) under Project Settings → Cloud
  Messaging → Apple app configuration. Not done yet; not required for
  TestFlight testing to work, only for push to actually deliver.
- **Screenshots for the App Store listing**: different aspect ratios from
  Play (6.9" and 6.5" iPhone sizes, plus iPad if supporting it). `STORE_LISTING.md`'s copy
  and data-safety answers carry over conceptually, but App Store Connect's
  privacy/data-safety form has its own different shape from Play's — it will
  need filling in separately, not copy-pasted.
- **App Review**: distinct from Play's review. Historically faster
  (24–48h common vs. Play's few days) but stricter about things like sign-in
  before showing content, and about matching what's described to what the
  app actually does — the honesty bar this project has already been holding
  to on the Android side applies the same way here.
