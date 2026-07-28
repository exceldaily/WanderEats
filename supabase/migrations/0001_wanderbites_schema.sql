-- WanderBites 0001: schema, extensions, tables, indexes
-- Lives inside the shared OrbitStack Supabase project as its own schema.
-- Additive only: never touches sibling schemas (orbitstack, gamespeak, phaseforge, ...).

create extension if not exists postgis with schema extensions;

create schema if not exists wanderbites;

grant usage on schema wanderbites to anon, authenticated, service_role;
alter default privileges in schema wanderbites grant all on tables to anon, authenticated, service_role;
alter default privileges in schema wanderbites grant all on functions to anon, authenticated, service_role;
alter default privileges in schema wanderbites grant all on sequences to anon, authenticated, service_role;

-- ---------------------------------------------------------------------------
-- Reference data
-- ---------------------------------------------------------------------------

create table wanderbites.countries (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  iso_code text not null unique,
  flag_emoji text,
  created_at timestamptz not null default now()
);

create table wanderbites.cities (
  id uuid primary key default gen_random_uuid(),
  country_id uuid not null references wanderbites.countries(id) on delete cascade,
  name text not null,
  slug text not null unique,
  center extensions.geography(point, 4326) not null,
  hero_photo_url text,
  created_at timestamptz not null default now()
);
create index cities_country_idx on wanderbites.cities(country_id);
create index cities_center_gix on wanderbites.cities using gist(center);

create table wanderbites.cuisines (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  slug text not null unique,
  emoji text,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- People
-- ---------------------------------------------------------------------------

create table wanderbites.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null unique check (username ~ '^[a-z0-9_]{3,24}$'),
  display_name text not null check (char_length(display_name) between 1 and 60),
  bio text check (char_length(bio) <= 280),
  avatar_url text,
  header_url text,
  home_city_id uuid references wanderbites.cities(id) on delete set null,
  is_verified boolean not null default false,
  is_admin boolean not null default false,
  is_suspended boolean not null default false,
  onboarding_completed boolean not null default false,
  favorite_cuisines uuid[] not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);
create index profiles_username_trgm on wanderbites.profiles using gin (username extensions.gin_trgm_ops);
create index profiles_display_trgm on wanderbites.profiles using gin (display_name extensions.gin_trgm_ops);

create table wanderbites.user_settings (
  user_id uuid primary key references wanderbites.profiles(id) on delete cascade,
  notif_follows boolean not null default true,
  notif_comments boolean not null default true,
  notif_list_activity boolean not null default true,
  notif_taster_activity boolean not null default true,
  notif_badges boolean not null default true,
  push_enabled boolean not null default true,
  profile_public boolean not null default true,
  show_visited_publicly boolean not null default true,
  theme text not null default 'system' check (theme in ('system','light','dark')),
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Restaurants
-- ---------------------------------------------------------------------------

create table wanderbites.restaurants (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  city_id uuid not null references wanderbites.cities(id) on delete cascade,
  address text,
  location extensions.geography(point, 4326) not null,
  price_level smallint check (price_level between 1 and 4),
  phone text,
  website text,
  opening_hours jsonb,
  cover_photo_url text,
  external_provider text,          -- 'seed' | 'google_places' | ...
  external_id text,                -- provider id, dedupe key
  status text not null default 'active' check (status in ('active','pending','removed')),
  is_seed boolean not null default false,
  created_by uuid references wanderbites.profiles(id) on delete set null,
  -- cached aggregates, maintained by triggers below
  rec_count integer not null default 0,
  save_count integer not null default 0,
  score numeric(4,2),              -- 0..10 aggregate recommendation quality
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  unique (external_provider, external_id)
);
create index restaurants_loc_gix on wanderbites.restaurants using gist(location);
create index restaurants_city_idx on wanderbites.restaurants(city_id);
create index restaurants_name_trgm on wanderbites.restaurants using gin (name extensions.gin_trgm_ops);
create index restaurants_rec_count_idx on wanderbites.restaurants(rec_count desc);

create table wanderbites.restaurant_cuisines (
  restaurant_id uuid not null references wanderbites.restaurants(id) on delete cascade,
  cuisine_id uuid not null references wanderbites.cuisines(id) on delete cascade,
  primary key (restaurant_id, cuisine_id)
);

create table wanderbites.restaurant_photos (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references wanderbites.restaurants(id) on delete cascade,
  user_id uuid references wanderbites.profiles(id) on delete set null,
  storage_path text not null,
  source text not null default 'user' check (source in ('user','seed','provider')),
  created_at timestamptz not null default now(),
  deleted_at timestamptz
);
create index restaurant_photos_rest_idx on wanderbites.restaurant_photos(restaurant_id);

-- ---------------------------------------------------------------------------
-- Recommendations (the trust core)
-- ---------------------------------------------------------------------------

create table wanderbites.recommendations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references wanderbites.profiles(id) on delete cascade,
  restaurant_id uuid not null references wanderbites.restaurants(id) on delete cascade,
  body text not null check (char_length(body) between 10 and 600),
  what_to_order text check (char_length(what_to_order) <= 300),
  price_impression smallint check (price_impression between 1 and 4),
  visited_on date,
  visibility text not null default 'public' check (visibility in ('public','followers','private')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  unique (user_id, restaurant_id)
);
create index recs_user_idx on wanderbites.recommendations(user_id);
create index recs_restaurant_idx on wanderbites.recommendations(restaurant_id);
create index recs_created_idx on wanderbites.recommendations(created_at desc);

create table wanderbites.recommendation_photos (
  id uuid primary key default gen_random_uuid(),
  recommendation_id uuid not null references wanderbites.recommendations(id) on delete cascade,
  storage_path text not null,
  position smallint not null default 0,
  created_at timestamptz not null default now()
);
create index rec_photos_rec_idx on wanderbites.recommendation_photos(recommendation_id);

create table wanderbites.recommendation_feedback (
  id uuid primary key default gen_random_uuid(),
  recommendation_id uuid not null references wanderbites.recommendations(id) on delete cascade,
  user_id uuid not null references wanderbites.profiles(id) on delete cascade,
  rating text not null check (rating in ('exact','great','somewhat','mismatch')),
  note text check (char_length(note) <= 300),
  created_at timestamptz not null default now(),
  unique (recommendation_id, user_id)
);
create index rec_feedback_rec_idx on wanderbites.recommendation_feedback(recommendation_id);

-- ---------------------------------------------------------------------------
-- Social graph
-- ---------------------------------------------------------------------------

create table wanderbites.follows (
  follower_id uuid not null references wanderbites.profiles(id) on delete cascade,
  followee_id uuid not null references wanderbites.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower_id, followee_id),
  check (follower_id <> followee_id)
);
create index follows_followee_idx on wanderbites.follows(followee_id);

create table wanderbites.city_follows (
  user_id uuid not null references wanderbites.profiles(id) on delete cascade,
  city_id uuid not null references wanderbites.cities(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, city_id)
);

create table wanderbites.blocked_users (
  blocker_id uuid not null references wanderbites.profiles(id) on delete cascade,
  blocked_id uuid not null references wanderbites.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);
create index blocked_users_blocked_idx on wanderbites.blocked_users(blocked_id);

-- ---------------------------------------------------------------------------
-- Saves and visits
-- ---------------------------------------------------------------------------

create table wanderbites.restaurant_saves (
  user_id uuid not null references wanderbites.profiles(id) on delete cascade,
  restaurant_id uuid not null references wanderbites.restaurants(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, restaurant_id)
);
create index saves_restaurant_idx on wanderbites.restaurant_saves(restaurant_id);

create table wanderbites.restaurant_visits (
  user_id uuid not null references wanderbites.profiles(id) on delete cascade,
  restaurant_id uuid not null references wanderbites.restaurants(id) on delete cascade,
  visited_on date not null default current_date,
  created_at timestamptz not null default now(),
  primary key (user_id, restaurant_id)
);
create index visits_restaurant_idx on wanderbites.restaurant_visits(restaurant_id);

-- ---------------------------------------------------------------------------
-- Lists
-- ---------------------------------------------------------------------------

create table wanderbites.lists (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references wanderbites.profiles(id) on delete cascade,
  title text not null check (char_length(title) between 1 and 80),
  description text check (char_length(description) <= 500),
  cover_url text,
  visibility text not null default 'public' check (visibility in ('public','private')),
  is_collaborative boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);
create index lists_owner_idx on wanderbites.lists(owner_id);
create index lists_title_trgm on wanderbites.lists using gin (title extensions.gin_trgm_ops);

create table wanderbites.list_restaurants (
  id uuid primary key default gen_random_uuid(),
  list_id uuid not null references wanderbites.lists(id) on delete cascade,
  restaurant_id uuid not null references wanderbites.restaurants(id) on delete cascade,
  added_by uuid references wanderbites.profiles(id) on delete set null,
  position integer not null default 0,
  note text check (char_length(note) <= 300),
  created_at timestamptz not null default now(),
  unique (list_id, restaurant_id)
);
create index list_restaurants_list_idx on wanderbites.list_restaurants(list_id);

create table wanderbites.list_collaborators (
  list_id uuid not null references wanderbites.lists(id) on delete cascade,
  user_id uuid not null references wanderbites.profiles(id) on delete cascade,
  status text not null default 'invited' check (status in ('invited','accepted')),
  created_at timestamptz not null default now(),
  primary key (list_id, user_id)
);
create index list_collabs_user_idx on wanderbites.list_collaborators(user_id);

create table wanderbites.list_follows (
  user_id uuid not null references wanderbites.profiles(id) on delete cascade,
  list_id uuid not null references wanderbites.lists(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, list_id)
);
create index list_follows_list_idx on wanderbites.list_follows(list_id);

-- ---------------------------------------------------------------------------
-- Interactions
-- ---------------------------------------------------------------------------

create table wanderbites.comments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references wanderbites.profiles(id) on delete cascade,
  target_type text not null check (target_type in ('list','recommendation')),
  target_id uuid not null,
  body text not null check (char_length(body) between 1 and 500),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);
create index comments_target_idx on wanderbites.comments(target_type, target_id);

create table wanderbites.likes (
  user_id uuid not null references wanderbites.profiles(id) on delete cascade,
  target_type text not null check (target_type in ('list','recommendation','comment')),
  target_id uuid not null,
  created_at timestamptz not null default now(),
  primary key (user_id, target_type, target_id)
);
create index likes_target_idx on wanderbites.likes(target_type, target_id);

-- ---------------------------------------------------------------------------
-- Gamification
-- ---------------------------------------------------------------------------

create table wanderbites.badges (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name text not null,
  description text not null,
  icon text not null,               -- material icon name or emoji
  category text not null default 'exploration',
  requirement jsonb not null,       -- e.g. {"type":"cities_visited","count":10}
  sort integer not null default 0,
  created_at timestamptz not null default now()
);

create table wanderbites.user_badges (
  user_id uuid not null references wanderbites.profiles(id) on delete cascade,
  badge_id uuid not null references wanderbites.badges(id) on delete cascade,
  awarded_at timestamptz not null default now(),
  primary key (user_id, badge_id)
);

-- ---------------------------------------------------------------------------
-- Notifications, moderation, devices
-- ---------------------------------------------------------------------------

create table wanderbites.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references wanderbites.profiles(id) on delete cascade,
  actor_id uuid references wanderbites.profiles(id) on delete cascade,
  type text not null check (type in (
    'follow','rec_feedback','comment','like','list_invite','list_update',
    'badge','city_activity','taster_activity','saved_list_update'
  )),
  payload jsonb not null default '{}',
  read_at timestamptz,
  created_at timestamptz not null default now()
);
create index notifications_user_idx on wanderbites.notifications(user_id, created_at desc);

create table wanderbites.content_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references wanderbites.profiles(id) on delete cascade,
  target_type text not null check (target_type in ('restaurant','recommendation','list','comment','profile','photo')),
  target_id uuid not null,
  reason text not null check (reason in ('spam','inappropriate','incorrect_info','harassment','other')),
  details text check (char_length(details) <= 500),
  status text not null default 'open' check (status in ('open','resolved','dismissed')),
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);

create table wanderbites.device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references wanderbites.profiles(id) on delete cascade,
  token text not null unique,
  platform text not null check (platform in ('android','ios')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index device_tokens_user_idx on wanderbites.device_tokens(user_id);

-- ---------------------------------------------------------------------------
-- Triggers: updated_at + cached counters
-- ---------------------------------------------------------------------------

create or replace function wanderbites.tg_touch_updated_at()
returns trigger language plpgsql security definer set search_path = wanderbites as $$
begin
  new.updated_at := now();
  return new;
end $$;

create trigger touch_profiles before update on wanderbites.profiles
  for each row execute function wanderbites.tg_touch_updated_at();
create trigger touch_restaurants before update on wanderbites.restaurants
  for each row execute function wanderbites.tg_touch_updated_at();
create trigger touch_recommendations before update on wanderbites.recommendations
  for each row execute function wanderbites.tg_touch_updated_at();
create trigger touch_lists before update on wanderbites.lists
  for each row execute function wanderbites.tg_touch_updated_at();
create trigger touch_comments before update on wanderbites.comments
  for each row execute function wanderbites.tg_touch_updated_at();

create or replace function wanderbites.tg_rec_count()
returns trigger language plpgsql security definer set search_path = wanderbites as $$
begin
  if tg_op = 'INSERT' then
    update restaurants set rec_count = rec_count + 1 where id = new.restaurant_id;
  elsif tg_op = 'DELETE' then
    update restaurants set rec_count = greatest(rec_count - 1, 0) where id = old.restaurant_id;
  end if;
  return coalesce(new, old);
end $$;

create trigger rec_count_maintain after insert or delete on wanderbites.recommendations
  for each row execute function wanderbites.tg_rec_count();

create or replace function wanderbites.tg_save_count()
returns trigger language plpgsql security definer set search_path = wanderbites as $$
begin
  if tg_op = 'INSERT' then
    update restaurants set save_count = save_count + 1 where id = new.restaurant_id;
  elsif tg_op = 'DELETE' then
    update restaurants set save_count = greatest(save_count - 1, 0) where id = old.restaurant_id;
  end if;
  return coalesce(new, old);
end $$;

create trigger save_count_maintain after insert or delete on wanderbites.restaurant_saves
  for each row execute function wanderbites.tg_save_count();
