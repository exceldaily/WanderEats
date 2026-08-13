# WanderBites Operations Guide

Every console and service the app runs on, what it does, and where the
common tasks live. Accounts matter: Play Console must be opened as
exceldaily7@gmail.com (the u/1 profile, "Harvey Creates"); App Store
Connect signs in as the Apple ID gatorcntryboy32@hotmail.com.

---

## The services

### 1. Google Play Console (Android store)
https://play.google.com/console/u/1/
Everything Android: releases, testers, store listing, data safety,
subscriptions on the Google side, and review status.

- App: WanderBites, package `com.wanderbites.app`
- Tracks: Internal testing (instant, build 15 live) and
  Closed testing - Alpha (Google-reviewed, counts toward the
  12-testers/14-days production requirement)

Common tasks:
- **See or edit testers**: Test and release (left nav) → Testing →
  Internal testing → Testers tab. Testers live inside email lists;
  click the arrow next to "WanderBites testers" to see the actual
  emails, add new ones in the "Add email addresses" box, press Enter,
  Save changes. The same list is attached to the Alpha track, so one
  edit covers both.
- **Copy the tester join link**: same Testers tab, bottom section
  "How testers join your test" → Copy link.
  - Internal testing link: https://play.google.com/apps/internaltest/4701479750891464428
  - Closed Alpha link (Join on Android): https://play.google.com/store/apps/details?id=com.wanderbites.app
- **Ship a new Android build**: Internal testing → Create new release →
  upload the AAB. The AAB must be built with
  `flutter build appbundle --release --dart-define-from-file=dart_defines/prod.json`
  or it boots to "Configuration missing".
- **Review status of submitted changes**: Publishing overview (left nav).
- **Google-side subscriptions**: Monetize with Play → Subscriptions.

### 2. App Store Connect (iOS store)
https://appstoreconnect.apple.com
Everything iOS: the 1.0 release submission, store listing, App Privacy,
age rating, Apple-side subscriptions, and TestFlight testers.

- App: WanderBites, Apple ID 6796729743

Common tasks:
- **iOS testers**: TestFlight tab (top of the app page) → tester groups.
  Add testers by email; they get an invite for the TestFlight app.
- **Release/version status**: Distribution tab → the version under
  "iOS App" top left.
- **Apple-side subscriptions**: Distribution → Monetization →
  Subscriptions → WanderBites Premium group.
- **Submission bundle**: blue "Draft Submissions" button bottom right
  shows what's queued for review.

### 3. TestFlight (tester-facing iOS app)
The app testers install from the App Store to get beta builds. You
manage who gets in from ASC's TestFlight tab; testers just accept the
email invite.

### 4. Codemagic (iOS build machine)
https://codemagic.io
Builds the iOS app in the cloud (no Mac needed) and uploads straight to
TestFlight. Config lives in `codemagic.yaml` in the repo; prod secrets
come from its `wanderbites_prod` environment group. Start a build from
the Codemagic dashboard → WanderBites → Start new build → main branch.

### 5. RevenueCat (subscription plumbing)
https://app.revenuecat.com
Sits between the app and both stores. Validates purchases with
Apple/Google and reports every subscription event to our backend via
webhook. The webhook is the only writer of subscription state in the
database; the app never decides entitlements on its own.

- Offering "default": $rc_monthly → wanderbites_premium_monthly
  ($2.99/mo + free week), $rc_annual → wanderbites_premium_annual
  ($24.99/yr)
- Dashboard shows revenue, active subs, customer timelines.

### 6. Supabase (backend: database, auth, storage, functions)
https://supabase.com/dashboard/project/pfagkivkytrvbkhsulvo
The entire backend. WanderBites lives in the `wanderbites` schema of the
shared OrbitStack project.

- SQL editor: run queries against profiles, follows, subscriptions, etc.
- Edge function `revenuecat-webhook`: receives RevenueCat events.
- Auth: user accounts and sessions.
- Notable server logic: auto-follow trigger (brad follows every new
  user), entitlement overrides (admin comps), premium downgrade revert
  (migration 0037).

### 7. GitHub (code)
https://github.com/exceldaily/WanderEats
The Flutter codebase, branch main. Local checkout:
C:\Users\ADMIN\Desktop\wanderbites

### 8. Firebase (push, analytics, crashes)
https://console.firebase.google.com → project wanderbites-503816
Push notifications (FCM), analytics events, and Crashlytics crash
reports. Check Crashlytics after every release.

### 9. Google Cloud Console (Maps + Places APIs)
https://console.cloud.google.com
Holds the Google Maps API keys (one per platform) and the Places API
the server uses to load restaurants worldwide. Billing for map usage
lives here.

### 10. Vercel (legal/marketing site)
https://wanderbites-gamma.vercel.app
Hosts the privacy policy (/privacy) and account deletion page
(/delete-account) that both stores link to.

---

## Quick "where do I go to..." table

| I want to... | Go to |
|---|---|
| Add or view Android testers | Play Console → Test and release → Testing → Internal testing → Testers tab → arrow on "WanderBites testers" |
| Send someone the Android join link | Same Testers tab → "How testers join your test" → Copy link |
| Add iOS testers | App Store Connect → TestFlight tab |
| Ship Android build | Build AAB with prod defines → Play Console → Internal testing → Create new release |
| Ship iOS build | Codemagic → Start new build (auto-lands in TestFlight) |
| Check Apple review status | ASC → Distribution → version status top left |
| Check Google review status | Play Console → Publishing overview |
| See revenue / active subs | RevenueCat dashboard |
| Change subscription prices | ASC Subscriptions + Play Console Monetize (both stores separately), keep RevenueCat products in sync |
| Look at crashes | Firebase console → Crashlytics |
| Query or fix user data | Supabase SQL editor (wanderbites schema) |
| Comp or revoke premium for a user | App admin screen, or Supabase `entitlement_overrides` table |

---

## Current tester roster (WanderBites testers list, both Android tracks)

- bang.prepress@gmail.com
- david.c@targetstudentmedia.com
- dnv2424@gmail.com
- exceldaily7@gmail.com
- jquach1979@gmail.com
