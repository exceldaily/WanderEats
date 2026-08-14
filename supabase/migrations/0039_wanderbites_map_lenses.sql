-- Map lenses: bounds-aware reads for the map's Following / Saved / Visited /
-- Hidden Gems views.
--
-- Every one of these could be done client-side over restaurants_in_bounds,
-- and that is exactly the bug we are fixing: that RPC caps at 200 rows ranked
-- by rec_count, so filtering afterwards can hide a place the user has saved
-- simply because a busier restaurant outranked it. Filtering belongs next to
-- the data.
--
-- All four are SECURITY INVOKER so restaurant + recommendation RLS still
-- applies, and all four take the same bounds shape as restaurants_in_bounds.

-- Restaurants inside the viewport recommended by people the caller follows.
-- The heart of the product: "show me the map according to people I trust".
create or replace function wanderbites.following_map_markers(
  min_lng double precision, min_lat double precision,
  max_lng double precision, max_lat double precision,
  max_rows int default 200
) returns table (
  id uuid, name text, lat double precision, lng double precision,
  price_level smallint, rec_count int, save_count int, score numeric,
  cover_photo_url text, city_id uuid,
  follower_recs int, via_taster_id uuid
) language sql stable set search_path = wanderbites, extensions as $$
  select r.id, r.name,
         extensions.st_y(r.location::extensions.geometry),
         extensions.st_x(r.location::extensions.geometry),
         r.price_level, r.rec_count, r.save_count, r.score,
         r.cover_photo_url, r.city_id,
         count(distinct rec.user_id)::int as follower_recs,
         -- One representative Taster for the pin's avatar, newest first; the
         -- count carries the rest.
         (array_agg(rec.user_id order by rec.created_at desc))[1] as via_taster_id
  from restaurants r
  join recommendations rec on rec.restaurant_id = r.id and rec.deleted_at is null
  join follows f on f.followee_id = rec.user_id and f.follower_id = auth.uid()
  where r.deleted_at is null
    and r.status = 'active'
    and r.location operator(extensions.&&)
        extensions.st_makeenvelope(min_lng, min_lat, max_lng, max_lat, 4326)::extensions.geography
  group by r.id
  order by follower_recs desc, r.score desc nulls last
  limit least(greatest(max_rows, 1), 400);
$$;

-- The caller's saved places inside the viewport.
create or replace function wanderbites.saved_map_markers(
  min_lng double precision, min_lat double precision,
  max_lng double precision, max_lat double precision,
  max_rows int default 200
) returns table (
  id uuid, name text, lat double precision, lng double precision,
  price_level smallint, rec_count int, save_count int, score numeric,
  cover_photo_url text, city_id uuid
) language sql stable set search_path = wanderbites, extensions as $$
  select r.id, r.name,
         extensions.st_y(r.location::extensions.geometry),
         extensions.st_x(r.location::extensions.geometry),
         r.price_level, r.rec_count, r.save_count, r.score,
         r.cover_photo_url, r.city_id
  from restaurants r
  join restaurant_saves s on s.restaurant_id = r.id and s.user_id = auth.uid()
  where r.deleted_at is null
    and r.status = 'active'
    and r.location operator(extensions.&&)
        extensions.st_makeenvelope(min_lng, min_lat, max_lng, max_lat, 4326)::extensions.geography
  order by s.created_at desc
  limit least(greatest(max_rows, 1), 400);
$$;

-- The caller's visited places inside the viewport: a personal food history.
create or replace function wanderbites.visited_map_markers(
  min_lng double precision, min_lat double precision,
  max_lng double precision, max_lat double precision,
  max_rows int default 200
) returns table (
  id uuid, name text, lat double precision, lng double precision,
  price_level smallint, rec_count int, save_count int, score numeric,
  cover_photo_url text, city_id uuid
) language sql stable set search_path = wanderbites, extensions as $$
  select r.id, r.name,
         extensions.st_y(r.location::extensions.geometry),
         extensions.st_x(r.location::extensions.geometry),
         r.price_level, r.rec_count, r.save_count, r.score,
         r.cover_photo_url, r.city_id
  from restaurants r
  join restaurant_visits v on v.restaurant_id = r.id and v.user_id = auth.uid()
  where r.deleted_at is null
    and r.status = 'active'
    and r.location operator(extensions.&&)
        extensions.st_makeenvelope(min_lng, min_lat, max_lng, max_lat, 4326)::extensions.geography
  order by v.visited_on desc nulls last
  limit least(greatest(max_rows, 1), 400);
$$;

-- Hidden gems: well regarded but under-discovered.
--
-- Deliberately NOT "a restaurant with few reviews" - that is just an empty
-- listing. The bar is real evidence of quality (a score, from at least one
-- recommendation) paired with low exposure (few saves relative to how well it
-- is rated). Ranking rewards quality per unit of attention.
create or replace function wanderbites.hidden_gems_in_bounds(
  min_lng double precision, min_lat double precision,
  max_lng double precision, max_lat double precision,
  max_rows int default 200
) returns table (
  id uuid, name text, lat double precision, lng double precision,
  price_level smallint, rec_count int, save_count int, score numeric,
  cover_photo_url text, city_id uuid
) language sql stable set search_path = wanderbites, extensions as $$
  select r.id, r.name,
         extensions.st_y(r.location::extensions.geometry),
         extensions.st_x(r.location::extensions.geometry),
         r.price_level, r.rec_count, r.save_count, r.score,
         r.cover_photo_url, r.city_id
  from restaurants r
  where r.deleted_at is null
    and r.status = 'active'
    and r.rec_count >= 1
    and r.score >= 7.0
    and r.save_count <= greatest(3, r.rec_count * 2)
    and r.location operator(extensions.&&)
        extensions.st_makeenvelope(min_lng, min_lat, max_lng, max_lat, 4326)::extensions.geography
  order by (r.score / (1 + r.save_count)) desc, r.score desc
  limit least(greatest(max_rows, 1), 400);
$$;

-- Hot-path index matching what every lens actually filters on. The existing
-- GIST covers location alone; this one skips deleted and inactive rows
-- entirely instead of filtering them after the index scan.
create index if not exists restaurants_active_loc_gix
  on wanderbites.restaurants using gist(location)
  where deleted_at is null and status = 'active';

-- Following/saved/visited all join from the restaurant side; this makes the
-- reverse lookup cheap.
create index if not exists recommendations_restaurant_user_idx
  on wanderbites.recommendations (restaurant_id, user_id)
  where deleted_at is null;
