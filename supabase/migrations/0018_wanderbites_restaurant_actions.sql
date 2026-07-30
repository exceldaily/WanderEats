-- Milestone 2: trackable restaurant actions + conversion attribution.
-- Additive only. Nothing existing is renamed or dropped.
--
-- Rollback: drop the two tables and delete the eight app_settings rows. No
-- existing table is altered, so rollback cannot lose user data.

-- ---------------------------------------------------------------------------
-- Action links. Multiple per restaurant, so no single reservation or delivery
-- provider is baked into the app. When a restaurant has no row here the app
-- falls back to restaurants.website / .phone.
-- ---------------------------------------------------------------------------
create table if not exists wanderbites.restaurant_action_links (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references wanderbites.restaurants(id) on delete cascade,
  action_type text not null check (action_type in (
    'directions','website','phone','menu','reservation',
    'order_delivery','order_pickup','book_experience','social_profile')),
  provider text,
  label text,
  destination_url text,
  phone_number text,
  priority smallint not null default 100,
  is_verified boolean not null default false,
  is_active boolean not null default true,
  -- Never a secret: a public campaign/partner id appended to the outbound URL.
  -- Private affiliate credentials stay server-side.
  affiliate_tracking_code text,
  created_by uuid references wanderbites.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint action_link_has_destination check (
    destination_url is not null or phone_number is not null)
);

create index if not exists idx_action_links_restaurant
  on wanderbites.restaurant_action_links (restaurant_id, action_type, priority)
  where is_active;

-- ---------------------------------------------------------------------------
-- Conversion events. Deliberately a real table rather than only a Firebase
-- event: a business dashboard has to query this, and Firebase cannot be joined
-- against restaurants or tasters.
--
-- Attribution columns are first-class and indexed; metadata is for secondary
-- detail only.
-- ---------------------------------------------------------------------------
create table if not exists wanderbites.restaurant_conversion_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references wanderbites.profiles(id) on delete set null,
  -- Signed-out browsing still converts; a rotating client id keeps those
  -- countable without identifying anyone.
  anonymous_session_id text,
  restaurant_id uuid not null references wanderbites.restaurants(id) on delete cascade,
  taster_id uuid references wanderbites.profiles(id) on delete set null,
  recommendation_id uuid references wanderbites.recommendations(id) on delete set null,
  list_id uuid references wanderbites.lists(id) on delete set null,
  city_id uuid references wanderbites.cities(id) on delete set null,
  source_screen text,
  source_feature text,
  action_type text not null,
  provider text,
  destination text,
  session_id text,
  app_version text,
  platform text,
  occurred_at timestamptz not null default now(),
  metadata jsonb not null default '{}'::jsonb
);

create index if not exists idx_conversion_restaurant_time
  on wanderbites.restaurant_conversion_events (restaurant_id, occurred_at desc);
create index if not exists idx_conversion_taster
  on wanderbites.restaurant_conversion_events (taster_id) where taster_id is not null;
create index if not exists idx_conversion_list
  on wanderbites.restaurant_conversion_events (list_id) where list_id is not null;
create index if not exists idx_conversion_recommendation
  on wanderbites.restaurant_conversion_events (recommendation_id) where recommendation_id is not null;
create index if not exists idx_conversion_user
  on wanderbites.restaurant_conversion_events (user_id) where user_id is not null;

-- ---------------------------------------------------------------------------
-- RLS. New policies use (select auth.uid()) so the planner evaluates it once
-- per statement rather than once per row - the auth_rls_initplan warning the
-- older policies still carry.
-- ---------------------------------------------------------------------------
alter table wanderbites.restaurant_action_links enable row level security;
alter table wanderbites.restaurant_conversion_events enable row level security;

-- Action links are public information, like the restaurant itself.
drop policy if exists action_links_read on wanderbites.restaurant_action_links;
create policy action_links_read on wanderbites.restaurant_action_links
  for select using (is_active);

-- Admins only for now. Verified business users get their own policy in the
-- claiming milestone, once restaurant_business_users exists.
drop policy if exists action_links_admin_write on wanderbites.restaurant_action_links;
create policy action_links_admin_write on wanderbites.restaurant_action_links
  for all using (wanderbites.is_admin()) with check (wanderbites.is_admin());

-- Anyone may record their own outbound action, but only their own: without the
-- user_id check a client could forge conversions against any account.
drop policy if exists conversion_insert_self on wanderbites.restaurant_conversion_events;
create policy conversion_insert_self on wanderbites.restaurant_conversion_events
  for insert with check (
    user_id is null or user_id = (select auth.uid())
  );

-- Raw events are not publicly readable. Businesses get aggregates only, from a
-- separate table written by a scheduled job.
drop policy if exists conversion_admin_read on wanderbites.restaurant_conversion_events;
create policy conversion_admin_read on wanderbites.restaurant_conversion_events
  for select using (wanderbites.is_admin());

-- ---------------------------------------------------------------------------
-- Feature flags. Reuses the existing app_settings table rather than adding a
-- parallel system. Everything seeds to false so merging this activates nothing.
-- ---------------------------------------------------------------------------
insert into wanderbites.app_settings (key, value)
values
  ('subscriptions_enabled', 'false'::jsonb),
  ('premium_paywall_enabled', 'false'::jsonb),
  ('restaurant_claiming_enabled', 'false'::jsonb),
  ('business_analytics_enabled', 'false'::jsonb),
  ('affiliate_links_enabled', 'false'::jsonb),
  ('premium_guides_enabled', 'false'::jsonb),
  ('creator_payouts_enabled', 'false'::jsonb),
  ('sponsored_collections_enabled', 'false'::jsonb)
on conflict (key) do nothing;
