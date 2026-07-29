-- Global restaurant coverage via Google Places.
--
-- Restaurants no longer come only from the 10 seeded cities: the map asks an
-- edge function for a tile, that function calls Google Places once, and the
-- results are materialized here. Every later viewer of the same tile is served
-- from Postgres, so Google is billed once per tile per TTL rather than once
-- per pan. Seeded rows keep is_seed = true and are never touched by this path.

-- Which map tiles we have already pulled from the provider, and when.
-- Tile key is lat/lng floored to `precision` degrees (~2km at 0.02).
create table if not exists wanderbites.place_tiles (
  id uuid primary key default gen_random_uuid(),
  provider text not null default 'google_places',
  tile_lat numeric(8,4) not null,
  tile_lng numeric(8,4) not null,
  precision numeric(6,4) not null default 0.0200,
  result_count integer not null default 0,
  fetched_at timestamptz not null default now(),
  unique (provider, tile_lat, tile_lng, precision)
);
create index if not exists place_tiles_fetched_idx
  on wanderbites.place_tiles(fetched_at desc);

-- Lazily create country + city for an external place so restaurants.city_id
-- stays satisfiable worldwide without pre-seeding every city on earth.
create or replace function wanderbites.ensure_city(
  p_city_name text,
  p_country_name text,
  p_iso text,
  p_lat double precision,
  p_lng double precision
) returns uuid
language plpgsql security definer set search_path = wanderbites, extensions as $$
declare
  v_country uuid;
  v_city uuid;
  v_slug text;
  v_city_name text := nullif(btrim(coalesce(p_city_name, '')), '');
  v_country_name text := nullif(btrim(coalesce(p_country_name, '')), '');
  v_iso text := upper(nullif(btrim(coalesce(p_iso, '')), ''));
begin
  -- Unknown locality still needs a home so the row can exist.
  v_city_name := coalesce(v_city_name, 'Unknown');
  v_country_name := coalesce(v_country_name, 'Unknown');
  v_iso := coalesce(v_iso, 'XX');

  select id into v_country from countries where iso_code = v_iso;
  if v_country is null then
    insert into countries (name, iso_code)
    values (v_country_name, v_iso)
    on conflict (iso_code) do update set name = excluded.name
    returning id into v_country;
  end if;

  select id into v_city
  from cities
  where country_id = v_country and lower(name) = lower(v_city_name)
  limit 1;
  if v_city is not null then
    return v_city;
  end if;

  v_slug := regexp_replace(lower(v_city_name), '[^a-z0-9]+', '-', 'g')
            || '-' || lower(v_iso);
  insert into cities (country_id, name, slug, center)
  values (
    v_country, v_city_name, v_slug,
    extensions.st_setsrid(extensions.st_makepoint(p_lng, p_lat), 4326)::extensions.geography
  )
  on conflict (slug) do update set name = excluded.name
  returning id into v_city;

  return v_city;
end;
$$;

-- Materialize one provider result. Dedupes on (external_provider, external_id);
-- refreshes mutable fields but never clobbers curated aggregates or seed rows.
create or replace function wanderbites.upsert_external_restaurant(
  p_external_id text,
  p_name text,
  p_lat double precision,
  p_lng double precision,
  p_address text default null,
  p_price_level smallint default null,
  p_phone text default null,
  p_website text default null,
  p_photo text default null,
  p_city_name text default null,
  p_country_name text default null,
  p_iso text default null,
  p_provider text default 'google_places'
) returns uuid
language plpgsql security definer set search_path = wanderbites, extensions as $$
declare
  v_city uuid;
  v_id uuid;
begin
  if p_external_id is null or btrim(p_external_id) = '' or p_name is null then
    return null;
  end if;

  v_city := wanderbites.ensure_city(
    p_city_name, p_country_name, p_iso, p_lat, p_lng);

  insert into restaurants (
    name, city_id, address, location, price_level, phone, website,
    cover_photo_url, external_provider, external_id, status, is_seed
  ) values (
    p_name, v_city, p_address,
    extensions.st_setsrid(extensions.st_makepoint(p_lng, p_lat), 4326)::extensions.geography,
    p_price_level, p_phone, p_website, p_photo, p_provider, p_external_id,
    'active', false
  )
  on conflict (external_provider, external_id) do update set
    name = excluded.name,
    address = coalesce(excluded.address, restaurants.address),
    location = excluded.location,
    price_level = coalesce(excluded.price_level, restaurants.price_level),
    phone = coalesce(excluded.phone, restaurants.phone),
    website = coalesce(excluded.website, restaurants.website),
    cover_photo_url = coalesce(excluded.cover_photo_url, restaurants.cover_photo_url),
    updated_at = now()
  returning id into v_id;

  return v_id;
end;
$$;

-- Does this tile need a provider round trip? Cheap guard the edge function
-- calls before spending a Places request.
create or replace function wanderbites.tile_needs_fetch(
  p_lat double precision,
  p_lng double precision,
  p_precision numeric default 0.0200,
  p_ttl_days integer default 30
) returns boolean
language sql stable security definer set search_path = wanderbites as $$
  select not exists (
    select 1 from place_tiles t
    where t.provider = 'google_places'
      and t.precision = p_precision
      and t.tile_lat = floor(p_lat / p_precision) * p_precision
      and t.tile_lng = floor(p_lng / p_precision) * p_precision
      and t.fetched_at > now() - (p_ttl_days || ' days')::interval
  );
$$;

create or replace function wanderbites.mark_tile_fetched(
  p_lat double precision,
  p_lng double precision,
  p_count integer,
  p_precision numeric default 0.0200
) returns void
language sql security definer set search_path = wanderbites as $$
  insert into place_tiles (provider, tile_lat, tile_lng, precision, result_count)
  values ('google_places',
          floor(p_lat / p_precision) * p_precision,
          floor(p_lng / p_precision) * p_precision,
          p_precision, coalesce(p_count, 0))
  on conflict (provider, tile_lat, tile_lng, precision) do update
    set fetched_at = now(), result_count = excluded.result_count;
$$;

-- place_tiles is bookkeeping for the server only; no client should read or
-- write it. RLS on with zero policies = deny all for anon/authenticated,
-- while the edge function's service role bypasses it.
alter table wanderbites.place_tiles enable row level security;

revoke all on function wanderbites.ensure_city(text, text, text, double precision, double precision) from public, anon, authenticated;
revoke all on function wanderbites.upsert_external_restaurant(text, text, double precision, double precision, text, smallint, text, text, text, text, text, text, text) from public, anon, authenticated;
revoke all on function wanderbites.tile_needs_fetch(double precision, double precision, numeric, integer) from public, anon, authenticated;
revoke all on function wanderbites.mark_tile_fetched(double precision, double precision, integer, numeric) from public, anon, authenticated;
