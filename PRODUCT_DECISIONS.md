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
