# iOS setup and TestFlight/App Store submission

Written 2026-07-31, before any of this has actually run. Nobody on this
project has a Mac — every build so far has been Android, from Windows. iOS
builds are only possible through Xcode, which only runs on macOS, so this
plan routes through **Codemagic**, a cloud CI service that builds on real
Apple hardware and can publish straight to TestFlight. `codemagic.yaml` at
the repo root is the pipeline; this file is the manual setup around it.

**This is now verified.** As of 2026-07-31 the pipeline builds, signs, uploads
and reaches TestFlight on its own. Build `1.0.0 (2)` is sitting there as Ready
to Submit and `1.0.0 (3)` processed Complete. It took five attempts to get
there, and the four failures are documented in place below rather than tidied
away, because each one was a trap that is easy to fall into again:

1. Signing files that are fetched, never created (step 7)
2. A missing Podfile, plus a deployment target too low for Firebase (step 9)
3. Export compliance silently gating every upload (step 9)
4. Build numbers being permanently consumed on upload (step 9)

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

### 4. Create the app record — done

In App Store Connect → Apps → **+** → New App:

- Platform: iOS
- Bundle ID: `com.wanderbites.app` (register it here if App Store Connect
  hasn't seen it before)
- SKU: anything unique, e.g. `wanderbites-ios`

### 5. A separate Google Maps key for iOS — done

Created as `WanderBites Maps iOS`. Note that "Maps SDK for iOS" was not an
enabled API on the project (only the Android one was), so it does not appear
in the key's API-restriction picker until you enable it in the API Library
first. Enable it, reload the credentials page, then create the key.


**Do not reuse the Android Maps key** — its restriction is Android-specific
(package name + SHA-1 fingerprint, the exact mechanism that caused the
blank-map issue on Android). iOS keys are restricted by bundle ID instead.

In the same Google Cloud project as the Android key
(console.cloud.google.com/apis/credentials?project=wanderbites-503816):

1. Create credentials → API key
2. Application restrictions → **iOS apps** → add bundle ID `com.wanderbites.app`
3. API restrictions → **Maps SDK for iOS**
4. Name it something findable, e.g. `WanderBites Maps iOS`

### 6. Codemagic environment variables — done

One thing to know first: this app has to be in **codemagic.yaml mode**, not
the Workflow Editor. New Codemagic apps default to the editor, and in that
mode `codemagic.yaml` is ignored entirely and the env-var form has no group
field at all (groups are a YAML-only concept). Switch via the app's
**Switch to YAML configuration** link. The env-var page only grows its
"Select group" dropdown after that switch.

Codemagic → this app → Environment variables → new group named
**`wanderbites_prod`** (referenced by `codemagic.yaml`'s `groups:`). Typing a
name that doesn't exist yet offers a "Create ... group" option. Add,
each marked **Secure**:

| Variable | Value |
|---|---|
| `SUPABASE_URL` | same as `dart_defines/prod.json` |
| `SUPABASE_PUBLISHABLE_KEY` | same as `dart_defines/prod.json` |
| `SUPABASE_SCHEMA` | `wanderbites` |
| `GOOGLE_MAPS_API_KEY_IOS` | the iOS key from step 5 — deliberately a
  different variable name from the Android build's `GOOGLE_MAPS_API_KEY`, so
  the two never get mixed up in a shared CI config |

### 7. Code signing, without ever touching a private key — done

Build #1 failed in seconds, before a Mac was even allocated:

> No matching profiles found for bundle identifier "com.wanderbites.app" and
> distribution type "app_store"

Worth writing down, because the error is misleading. The `ios_signing:` block
does **not** create signing files. It only fetches ones already saved in
Codemagic's Code signing identities, and nothing had been saved yet. The
message reads like a signing failure when it actually means an empty shelf.

The obvious fix (`app-store-connect fetch-signing-files --create`) works but
drags in a `CERTIFICATE_PRIVATE_KEY` secret you have to generate and paste by
hand. There's a better route that avoids handling key material entirely:

**Certificate** — Settings → Code signing identities → iOS certificates →
**Generate certificate**. Name it `wanderbites_distribution`, type **Apple
Distribution**, pick the App Store Connect API key. Codemagic generates the
keypair, registers the certificate with Apple, and keeps the private key on its
side. It offers a one-time password-protected download as a backup; skipping it
is fine, since builds use Codemagic's stored copy.

**Profile** — this one has to start in Apple's portal, because Codemagic can
fetch profiles but cannot create them. At developer.apple.com → Certificates,
Identifiers & Profiles → Profiles → **+** → Distribution → **App Store
Connect**, pick App ID `com.wanderbites.app`, tick the certificate from the
previous step, and name it. Then back in Codemagic → iOS provisioning profiles
→ **Fetch profiles**, tick it, and save it under the reference name
`wanderbites_appstore_profile`. No download needed, it comes over the API.

`codemagic.yaml` then references both by those exact reference names. If you
ever regenerate either one, the names in the yaml have to be updated to match.

### 8. Push, and watch the build

Push to `main`, or trigger a run from the Codemagic dashboard. It builds an
`.ipa` and, if `submit_to_testflight: true` in `codemagic.yaml` stays as-is,
uploads it straight to TestFlight. First Apple processing after upload
usually takes a few minutes to an hour, and the build shows up under
**Build Uploads** (with a processing status) before it appears in the list of
builds available to test. Do not read that gap as a failure.

### 9. Four things that broke the first four builds

Kept because none of them announce themselves clearly.

**The build number is spent the moment it uploads.** App Store Connect
permanently consumes a `CFBundleVersion` on upload, whatever happens to that
build afterwards. Re-running CI without bumping `pubspec.yaml`'s `+N` fails at
upload, after paying for the whole build. Bump it every time.

**Export compliance gates every single upload.** Without
`ITSAppUsesNonExemptEncryption` in `Info.plist`, Apple parks each build on a
manual question and the automatic TestFlight submission fails. It surfaces as
Codemagic reporting "post-processing failed" on a build that actually uploaded
perfectly, and as "Missing Compliance" in TestFlight. Build 1 is still stuck
there as a monument to it.

**CocoaPods reports only the first conflict it hits.** Build 2 blamed
`google_maps_flutter_ios` needing iOS 14.0. Raising to 14.0 would have failed
again on Firebase, which needs 15.0. When a deployment-target error appears,
read every plugin's podspec and take the maximum rather than the one named.

**`ios/Podfile` did not exist.** The "CocoaPods install" step was passing in 3
seconds because `find . -name Podfile` matched nothing, which reads as success.
Flutter then generated one at build time with its platform line commented out.
A step that finishes suspiciously fast is worth checking.

## Still to do

- **Install via TestFlight** on a real iPhone. App Store Connect → TestFlight →
  Internal Testing, add yourself, install through the TestFlight app. Internal
  testers skip Apple review, so it is immediate. This is the iOS equivalent of
  the Play internal-testing track, and the first time anyone will see this app
  actually run on an iPhone.
- **Push notifications** need one more piece. The app side is done: build 3
  carries `aps-environment` via `ios/Runner/Runner.entitlements`, and the App ID
  has the Push Notifications capability. But nothing will deliver until an APNs
  auth key exists — developer.apple.com → Keys → **+** → Apple Push
  Notifications service (APNs) — and is uploaded to the Firebase project
  (`wanderbites-503816`) under Project Settings → Cloud Messaging → Apple app
  configuration. That download is a `.p8` private key: upload it straight into
  Firebase and keep it out of any chat, the same rule as the App Store Connect
  key in step 3.
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
