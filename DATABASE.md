# Database

Schema `wanderbites` inside the shared OrbitStack Supabase project (`pfagkivkytrvbkhsulvo`). PostGIS via the `extensions` schema. All primary keys are UUIDs, all tables carry created_at (and updated_at where rows mutate), soft deletes via deleted_at on content tables.

## Migration order (supabase/migrations/)

1. `0001_wanderbites_schema.sql` - extensions, schema, all tables, indexes, counter triggers
2. `0002_wanderbites_rls.sql` - RLS enable + policies for every table
3. `0003_wanderbites_functions.sql` - RPCs: map bounds, nearby, summaries, reputation, trending, search, account deletion
4. `0004_wanderbites_expose.sql` - append-safe PostgREST exposure (read-modify-write of pgrst.db_schemas)
5. `0005_wanderbites_storage.sql` - `wanderbites-media` bucket + ownership policies

Seed: `supabase/seed/seed.sql` (development data, all rows tagged as seed).

## Entities

Reference: countries, cities (PostGIS point center), cuisines.

People: profiles (references auth.users of the shared project, unique username, verification + admin flags), user_settings.

Restaurants: restaurants (geography point, price level, hours jsonb, external_provider + external_id dedupe key, is_seed flag, cached rec_count/save_count/score), restaurant_cuisines, restaurant_photos.

Trust core: recommendations (short text, what_to_order, visibility, one per user per restaurant), recommendation_photos, recommendation_feedback (exact/great/somewhat/mismatch, unique per user per rec, never on your own rec).

Graph: follows, city_follows, blocked_users.

Activity: restaurant_saves, restaurant_visits.

Lists: lists (public/private, collaborative flag), list_restaurants (ordered, unique per list), list_collaborators (invited/accepted), list_follows.

Interaction: comments (polymorphic over list/recommendation), likes (polymorphic).

Gamification: badges (requirement stored as jsonb in the DB, not hardcoded in UI), user_badges.

Ops: notifications, content_reports, device_tokens.

## Server-side functions (0003)

- `restaurants_in_bounds(min_lng, min_lat, max_lng, max_lat, max_rows)` - marker query for the visible map, ordered by rec_count, hard capped
- `nearby_restaurants(lng, lat, radius_m, max_rows)` - distance-sorted discovery
- `restaurant_summary(restaurant_id)` - recommending tasters, avatars, top quote
- `taster_reputation(user_id)` - internal scoring: verified feedback counts, positive share, recency, unique users influenced, breadth of cities/cuisines, sample-size confidence. Not exposed as a formula in the UI.
- `trending_restaurants(city)` / `trending_tasters()`
- `search_all(q)` - grouped results (restaurants, tasters, lists, cities, cuisines) using pg_trgm
- `delete_account()` - definer; removes the caller's profile and content

## Rules for this shared project

- Append, never overwrite, `pgrst.db_schemas`. Read `pg_db_role_setting` first; refuse to write if unreadable.
- No triggers on auth.users. Profile rows are created by the app during onboarding.
- Everything schema-qualified; `public` and sibling schemas are off limits.
- Seeded data is separable: `restaurants.is_seed`, seeded profiles use the `wb_` username prefix and fake auth users created only in development.
