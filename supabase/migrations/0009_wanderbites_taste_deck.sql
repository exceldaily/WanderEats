-- Taste Deck: swipe discovery. An optional mode layered on the map, never a
-- replacement for it. Impressions and skips exist to improve ranking, not to
-- power engagement mechanics, and every table here is private to its owner.

create table if not exists wanderbites.taste_deck_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references wanderbites.profiles(id) on delete cascade,
  city_id uuid references wanderbites.cities(id) on delete set null,
  center_lat double precision,
  center_lng double precision,
  radius_m integer not null default 3000,
  filters jsonb not null default '{}'::jsonb,
  saved_count integer not null default 0,
  skipped_count integer not null default 0,
  tasters_discovered integer not null default 0,
  started_at timestamptz not null default now(),
  ended_at timestamptz
);
create index if not exists tds_user_idx
  on wanderbites.taste_deck_sessions(user_id, started_at desc);

create table if not exists wanderbites.taste_deck_impressions (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references wanderbites.taste_deck_sessions(id) on delete cascade,
  user_id uuid not null references wanderbites.profiles(id) on delete cascade,
  restaurant_id uuid not null references wanderbites.restaurants(id) on delete cascade,
  position integer not null,
  reason text,
  via_taster_id uuid references wanderbites.profiles(id) on delete set null,
  action text check (action in ('shown','saved','skipped','opened','undone')),
  acted_at timestamptz,
  created_at timestamptz not null default now()
);
create index if not exists tdi_user_rest_idx
  on wanderbites.taste_deck_impressions(user_id, restaurant_id);
create index if not exists tdi_session_idx
  on wanderbites.taste_deck_impressions(session_id, position);

-- Skips are soft: they damp ranking and decay, they never blacklist.
create table if not exists wanderbites.restaurant_skips (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references wanderbites.profiles(id) on delete cascade,
  restaurant_id uuid not null references wanderbites.restaurants(id) on delete cascade,
  skip_count integer not null default 1,
  last_skipped_at timestamptz not null default now(),
  unique (user_id, restaurant_id)
);
create index if not exists rs_user_idx
  on wanderbites.restaurant_skips(user_id, last_skipped_at desc);

-- Where a save came from, so the deck can be credited without guessing.
create table if not exists wanderbites.restaurant_save_sources (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references wanderbites.profiles(id) on delete cascade,
  restaurant_id uuid not null references wanderbites.restaurants(id) on delete cascade,
  source text not null default 'map'
    check (source in ('map','deck','list','search','details','feed')),
  session_id uuid references wanderbites.taste_deck_sessions(id) on delete set null,
  via_taster_id uuid references wanderbites.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  unique (user_id, restaurant_id)
);

create table if not exists wanderbites.taste_preference_feedback (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references wanderbites.profiles(id) on delete cascade,
  restaurant_id uuid references wanderbites.restaurants(id) on delete set null,
  reason text not null
    check (reason in ('too_far','too_expensive','cuisine','visited','not_now')),
  created_at timestamptz not null default now()
);
create index if not exists tpf_user_idx
  on wanderbites.taste_preference_feedback(user_id, created_at desc);

alter table wanderbites.taste_deck_sessions enable row level security;
alter table wanderbites.taste_deck_impressions enable row level security;
alter table wanderbites.restaurant_skips enable row level security;
alter table wanderbites.restaurant_save_sources enable row level security;
alter table wanderbites.taste_preference_feedback enable row level security;

do $$
declare t text;
begin
  foreach t in array array[
    'taste_deck_sessions','taste_deck_impressions','restaurant_skips',
    'restaurant_save_sources','taste_preference_feedback']
  loop
    execute format('drop policy if exists %I_own on wanderbites.%I', t, t);
    execute format(
      'create policy %I_own on wanderbites.%I for all to authenticated
         using (user_id = (select auth.uid()))
         with check (user_id = (select auth.uid()))', t, t);
  end loop;
end $$;

grant select, insert, update, delete on
  wanderbites.taste_deck_sessions,
  wanderbites.taste_deck_impressions,
  wanderbites.restaurant_skips,
  wanderbites.restaurant_save_sources,
  wanderbites.taste_preference_feedback
to authenticated;
