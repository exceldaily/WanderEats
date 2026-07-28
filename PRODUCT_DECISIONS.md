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
