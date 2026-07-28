# Product decisions

Running log of decisions made while building, with reasoning. Newest last.

## 2026-07-28 (Milestone 1)

- **Brand vs repo name**: product is WanderBites everywhere in-app; the GitHub repo stays WanderEats as created. Package id com.wanderbites.app.
- **Backend placement**: schema `wanderbites` inside the shared OrbitStack Supabase project, registered as an OrbitStack application card. Consequence: WanderBites accounts share the auth pool with other OrbitStack-connected apps, and PostgREST schema exposure must always be append-safe.
- **No auth.users trigger**: sibling apps own signup triggers in the shared project. The profile row is created during WanderBites onboarding instead. This also means a user who exists from another app simply gets onboarded on first WanderBites sign-in.
- **Restaurant data**: Phase 1 runs on seeded fictional restaurants with real coordinates. No Google Places dependency, no scraping, no licensing risk, and clustering/nearby demos work. `RestaurantDataProvider` interface keeps the door open.
- **Clustering**: server caps + client-side grid clustering instead of a third-party cluster package (stale ecosystem, and bounded queries make client clustering cheap).
- **Firebase deferred behind interfaces**: no Firebase project exists yet. Analytics logs to console in debug; push is a no-op. Uncommenting four pubspec lines + `flutterfire configure` activates it. This keeps the build green with zero fake success paths.
- **Recommendation limits**: 10 to 600 chars body, one recommendation per user per restaurant (updateable). Feedback options: exact / great / somewhat / mismatch, one per user per rec, never on your own.
- **Reputation scoring server-side only**, stored nowhere in the client, formula not exposed in UI (per spec).
- **Offline cache**: Drift, cache-first reads for profile/saves/follows/lists/recent map regions.
- **Theme**: voyage teal + ember coral + warm neutrals. No fast-food palette, no glassmorphism. Light and dark from one token set.

## 2026-07-28 (Milestones 2 through 8)

- **Seeded auth users**: 20 fictional Tasters exist as real (unloginable) rows in the shared auth pool, inserted with session_replication_role=replica so sibling apps' signup triggers never fired for them. Fixed UUID prefix a0000000-... makes them separable.
- **Account deletion scope**: delete_account() removes the WanderBites profile + content only, never the auth.users row, because that account may power sibling OrbitStack apps.
- **Feed placement**: the Following feed lives as a tab inside Discover (For you / Following) instead of a sixth nav item, keeping the bottom bar at five.
- **Clustering posture**: with bounded queries capped at 200-400 markers, default markers + info windows proved sufficient for the seed density; grid clustering remains a documented follow-up if real data outgrows it.
- **Offline scope shipped**: last map result cached (shared_preferences JSON), recommendation drafts persisted, recent searches persisted. Drift remains in the dependency set for the richer cache when real usage justifies it.
- **Feedback dedupe**: one feedback row per user per recommendation, upsert semantics so users can revise their rating; RLS rejects self-rating (probe-verified).
- **Notifications**: created exclusively by database triggers (no client insert policy); tap targets resolved server-data-first (rec -> its restaurant, list events -> the list).

## 2026-07-28 (post-launch: cloud service wiring)

- **Release signing**: keystore generated with a random password, wired via android/key.properties (gitignored) with debug-signing fallback for machines without it.
- **Google Cloud project**: `wanderbites-503816`, separate from OrbitStack's own tooling projects. OAuth consent screen is External (any Google account, not just an org). Google Sign-In client is a Web application type (not Android) because Supabase's OAuth flow is the server-side redirect handler, not the native Android SDK.
- **Google Maps SDK blocked on billing**: enabling it redirected straight into Google's billing-enablement flow, which needs a payment method. That step is left for the account owner; everything else (project, OAuth, Firebase) was completed without touching billing.
- **Firebase reuses the same GCP project** (`wanderbites-503816`) rather than a separate Firebase-only project, so Google Cloud IAM and the OAuth client are shared. Analytics account: existing "Brads Websites" account, not a new one.
- **Firebase Android app package is `com.wanderbites.app`**, matching applicationId. `google-services.json` is gitignored (like MAPS_API_KEY); the google-services Gradle plugin only applies when that file is present, so a fresh clone without it still builds.
- **Crashlytics wiring**: FlutterError.onError and PlatformDispatcher.instance.onError both route to Crashlytics, but only after Firebase.initializeApp() succeeds; a missing/misconfigured Firebase falls back to default Flutter error handling, never a crash-on-boot.
