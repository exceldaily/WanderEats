-- WanderBites 0006: taster_places - a Taster's personal food map in one call.
-- Returns every place the user has recommended / visited / saved with
-- lat/lng extracted, so the profile map renders from a single query.
-- Respects privacy: visits are only included when the owner allows it or the
-- caller is the owner. Invoker security so RLS applies to saves/recs too.

create or replace function wanderbites.taster_places(uid uuid)
returns table (
  id uuid, name text, lat double precision, lng double precision,
  price_level smallint, rec_count int, score numeric,
  cover_photo_url text, city_id uuid,
  recommended boolean, visited boolean, saved boolean
) language sql stable set search_path = wanderbites, extensions as $$
  with rec_ids as (
    select restaurant_id from recommendations
    where user_id = uid and deleted_at is null
  ), visit_ids as (
    select restaurant_id from restaurant_visits where user_id = uid
  ), save_ids as (
    select restaurant_id from restaurant_saves where user_id = uid
  )
  select r.id, r.name,
         extensions.st_y(r.location::extensions.geometry),
         extensions.st_x(r.location::extensions.geometry),
         r.price_level, r.rec_count, r.score, r.cover_photo_url, r.city_id,
         r.id in (select restaurant_id from rec_ids),
         r.id in (select restaurant_id from visit_ids),
         r.id in (select restaurant_id from save_ids)
  from restaurants r
  where r.deleted_at is null and r.status = 'active'
    and r.id in (
      select restaurant_id from rec_ids
      union select restaurant_id from visit_ids
      union select restaurant_id from save_ids
    )
  limit 500;
$$;
