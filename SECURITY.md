# Security

## Principles

1. The mobile app holds only publishable credentials (Supabase publishable key, Google Maps client key). Service-role keys never ship, never appear in git.
2. Every exposed table has Row-Level Security enabled, deny by default.
3. Anything trust-related (reputation scores, trending, feed ranking) is computed server-side in SQL functions. Clients cannot write score fields.
4. The app lives in the `wanderbites` schema of a shared Supabase project and must never read or write sibling schemas.

## RLS model (summary; policies live in supabase/migrations/0002)

- profiles: anyone can read public profiles; users update only their own row; no client deletes (account deletion goes through a definer function that cascades).
- user_settings: owner only, read and write.
- restaurants: readable by all; inserts by authenticated users (status pending unless seeded/admin); updates restricted to admins, plus the cached counter columns are trigger-maintained only.
- recommendations: public ones readable by all; followers visibility checks the follows table; private only by the author. Insert/update/delete only by the author.
- recommendation_feedback: readable with the parent rec; insert only by authenticated users who are NOT the rec author (enforced in policy) and not blocked by the author.
- follows / saves / visits / city_follows / list_follows / likes: the acting user's own rows only; reads where the parent content is visible.
- lists: public readable by all; private readable by owner + accepted collaborators; writes by owner; list_restaurants writable by owner + accepted collaborators.
- comments: readable where the target is visible; write own; blocked users cannot comment on each other's content.
- blocked_users: visible only to the blocker; blocks sever interactions both ways in policies.
- notifications: owner read/update (mark read); inserts happen in definer functions triggered by actions, not raw client inserts.
- content_reports: insert by any authenticated user; readable only by admins.
- device_tokens: owner only.
- badges: readable by all; user_badges written only by the definer awarding function.

## Storage

Bucket `wanderbites-media`. Upload path must start with the uploader's uid (`<uid>/...`), enforced by storage policies. Client compresses images before upload; size capped, images only. Public read for recommendation/restaurant photos, avatars and covers.

## Shared-project rules

- PostgREST exposure: `wanderbites` was APPENDED to `pgrst.db_schemas` by reading the current value first. Never overwrite that list; it carries sibling apps.
- No triggers on `auth.users` (sibling apps own signup triggers). The WanderBites profile row is created during onboarding by the app.
- Migrations are additive and schema-qualified. Nothing touches `public` or sibling schemas.

## Abuse and hygiene

- Feedback requires can't-rate-yourself + unique (rec, user), so reputation cannot be farmed with likes or self-votes.
- Text inputs length-checked in SQL and sanitized for display in the app (no markdown/html rendering of user text).
- Content reporting and user blocking are first-class tables with UI.
- Statement timeouts exist project-wide (8s); paginated queries and bounded map queries keep result sets small.
- Account deletion: definer function removes the profile and owned content, auth user delete cascades. Documented in DATABASE.md.
