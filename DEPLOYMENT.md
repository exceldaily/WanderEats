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

---

# Play Store submission runbook

Written 29 July 2026. Steps marked **[you]** need a human — payment, Play
Console access, or a hosting decision.

## Before the first upload

1. **[you] Play Console account** — $25 one-time, developer identity
   verification. https://play.google.com/console/signup
2. **[you] Host the privacy policy.** `PRIVACY.md` is written and ready.
   Any public URL works (GitHub Pages, a Vercel page, a Notion page). Two
   places need the link: the Play listing, and the account-deletion section
   below.
3. **[you] Host a deletion-request page.** Play requires a URL reachable
   *without installing the app*. It can be one paragraph pointing at
   exceldaily7@gmail.com; the content is already drafted in PRIVACY.md
   under "Your choices and rights".

## Build

```bash
python tool/generate_icons.py          # only if branding changed
dart run flutter_launcher_icons        # only if branding changed
flutter build appbundle --release --dart-define-from-file=dart_defines/prod.json
```

**The `--dart-define-from-file` is not optional.** Without it the bundle
compiles fine and then launches to a "Configuration missing" screen, because
the Supabase URL and keys are injected at compile time. A bundle built without
it is uploadable and completely non-functional.

Artifact: `build/app/outputs/bundle/release/app-release.aab`.
Play requires the .aab, not the .apk.

Bump `version:` in pubspec.yaml for every upload — Play rejects a reused
versionCode. Format `x.y.z+N`; N is the versionCode.

## Play Console, step by step

Everything below happens at https://play.google.com/console. The developer
account and identity verification are already done.

### 1. Create the app

**All apps → Create app.**

- App name: `WanderBites`
- Default language: English (United States)
- App or game: **App**
- Free or paid: **Free** (this cannot be changed to paid later, only the
  reverse — free is correct here since monetization is subscriptions and
  in-app, not a paid download)
- Tick both declarations, then **Create app**.

### 2. Upload the bundle first, before filling in any forms

Counter-intuitive, but the SHA-1 you need for Maps does not exist until Google
has re-signed a bundle, and several forms are easier once the app exists.

**Test and release → Testing → Internal testing → Create new release.**

- Play App Signing is opt-in on the first release. **Accept it.** It lets
  Google re-sign with their own key and is required for app bundles.
- Upload `build/app/outputs/bundle/release/app-release.aab`.
- Release name autofills from the versionCode (`1 (1.0.0)`).
- Release notes: anything for internal testing, e.g. "First internal build."
- **Next → Save**, then **Go to overview → Publish**.

Internal testing goes live in minutes rather than the days review takes, and
it is the fastest way to confirm the Play-signed build actually works.

### 3. Do the SHA-1 step immediately (see the next section)

Do this before testing the internal build, or the map will be blank and you
will think something is broken.

### 4. Add internal testers

**Internal testing → Testers → Create email list.** Add your own address, save,
then copy the **join link** at the bottom. Open that link on the phone, accept,
and install from Play. This is the build to check — it is signed with Google's
key, which the sideloaded APK is not.

### 5. Fill in the forms Play requires before production

**Test and release → Publishing overview** lists everything outstanding. The
ones that need real answers:

| Section | Where | Source |
|---|---|---|
| App access | Monitor and improve → Policy → App content | All functionality available without restrictions; no login needed to browse |
| Ads | App content | **No**, the app contains no ads |
| Content rating | App content | Questionnaire answers are in `STORE_LISTING.md` |
| Target audience | App content | 13+; not directed at children |
| Data safety | App content | Full table is in `STORE_LISTING.md` |
| Privacy policy | App content | https://wanderbites-gamma.vercel.app/privacy |
| Data deletion | App content → Data safety | https://wanderbites-gamma.vercel.app/delete-account |
| Government apps | App content | No |
| Financial features | App content | No |
| Store listing | Grow → Store presence | Copy in `STORE_LISTING.md`, assets in `branding/` and `store/screenshots/play/` |

Data safety is the one people get wrong. It is a self-declaration, and it must
match what the app actually does — the table in `STORE_LISTING.md` was written
from the real code, not aspirationally.

### 6. Promote to production when ready

**Test and release → Production → Create new release**, then promote the same
bundle. First production review typically takes a few days; later ones are
faster. Closed testing first is optional but sensible if you want feedback
before the listing is public.

## Maps will break on the first Play build unless you do this

Play App Signing re-signs the app with **Google's** certificate, not the
upload keystore. The Maps key is restricted to specific SHA-1 fingerprints,
so a Play-signed build hits a key it is not allowed to use and **the map
renders blank** — while the sideloaded build keeps working perfectly. This
is easy to miss.

**Play Console's own settings page for this has moved twice** (App signing →
App integrity → now folded into "Protected with Play" → Play Store
protection → App signing) and, as of writing, that page can show more than
one certificate — an upload-key cert and the actual app-signing cert are both
visible, and it is easy to copy the wrong one. On 2026-07-31 that happened:
the copied SHA-1 was added to the Maps key, saved cleanly, and the map still
rendered blank.

**The reliable source of truth is the device, not the console.** If the map
is still blank after adding a SHA-1 from Play Console, don't trust the
console — pull the real error:

```bash
adb logcat -c
# relaunch the app, open the map screen
adb logcat -d | grep -i "Google Android Maps SDK"
```

The failure logs the exact fingerprint it wanted and didn't get, e.g.:

```
E Google Android Maps SDK: Authorization failure.
E Google Android Maps SDK:   API Key: AIza...
E Google Android Maps SDK:   Android Application (<cert_fingerprint>;<package_name>): XX:XX:...;com.wanderbites.app
```

Register *that* fingerprint — not whichever one the console page showed —
against `com.wanderbites.app` in
https://console.cloud.google.com/apis/credentials?project=wanderbites-503816
→ "WanderBites Maps Android" → Android restrictions → **Add**.

Registering an extra fingerprint is harmless; multiple certs can be listed
for the same package. Don't remove the existing entries — the upload-key and
local debug SHA-1s are already there for the sideloaded/debug builds.

Wait up to 5 minutes for the change to propagate, then relaunch the app
(force-stop, don't need to reinstall) and re-check the map.

## Store listing

All copy, data-safety answers and the content-rating questionnaire are in
`STORE_LISTING.md`. Assets:

- Icon: `branding/play_icon_512.png` (512×512, no alpha — Play rejects alpha)
- Feature graphic: `branding/feature_graphic.png` (1024×500)
- Screenshots: capture list is in STORE_LISTING.md

### Capturing screenshots

Shoot them off a real phone running the **release** APK, not a debug build —
the release build is what has the final icon, and the map only renders on a
build signed with a registered SHA-1.

```
flutter build apk --release
pwsh tool/capture_screenshots.ps1 -Install       # sideload, then shot 1
pwsh tool/capture_screenshots.ps1 -Shot 2        # navigate first, then run
```

The script pulls the current screen over adb, names it after the shot list,
and checks it against Play's size and aspect limits before you find out from a
rejected listing. `-List` prints the shot order. Output lands in
`store/screenshots/`.

Play needs a minimum of 2. Shot 1 is the one that sells the app, so make it the
map with a preview card open.

## Public site

`web/` is a static site on Vercel (project `wanderbites`, free tier) that
exists to satisfy the two URLs Play insists on:

- Privacy policy: https://wanderbites-gamma.vercel.app/privacy
- Data deletion: https://wanderbites-gamma.vercel.app/delete-account

`PRIVACY.md` and `web/privacy.html` say the same thing; keep them in step.
Redeploy after editing — the site is deployed from the file tree, not from a
git integration, so pushing to GitHub alone does not publish it.

## Branding

Every icon layer is derived from one file, `branding/source/wanderbites_globe.png`.
Replace that and re-run:

```
python tool/generate_icons.py
dart run flutter_launcher_icons
```

## Release order

1. **Internal testing** first. Verify: map renders (see SHA-1 step above),
   Google sign-in works, a recommendation posts with a photo, account
   deletion completes.
2. **Closed testing** with real people if you want feedback before launch.
3. **Production**.

## Demo content

Seeded Tasters are flagged `is_demo` and render a "Sample" badge everywhere
they appear. To hide them entirely once real users are posting:

```sql
update wanderbites.app_settings
set value = 'false'::jsonb, updated_at = now()
where key = 'show_demo_content';
```

No app release needed — it takes effect on next fetch. Seeded *restaurants*
are real places and stay regardless.

## Operational limits to watch at launch

- **Auth email**: Brevo SMTP, 30/hour. Fine for a soft launch; raise the
  Supabase rate limit and Brevo plan before any real volume.
- **Maps/Places**: $200/month standing credit plus 10K free calls per SKU;
  tile caching means panning over covered ground costs nothing. Budget alert
  set at $10 with emails at 50/90/100%.
- **Shared auth pool**: WanderBites signups land in the same `auth.users` as
  the other OrbitStack apps. Account deletion removes the WanderBites profile
  only, never the shared auth row.
