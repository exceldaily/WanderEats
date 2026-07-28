-- WanderBites 0007: list_places - a list's ordered entries with coordinates
-- for the list map view. Invoker security: RLS decides list visibility.

create or replace function wanderbites.list_places(lid uuid)
returns table (
  entry_id uuid, sort_position int, note text,
  id uuid, name text, lat double precision, lng double precision,
  price_level smallint, rec_count int, score numeric,
  cover_photo_url text, city_id uuid
) language sql stable set search_path = wanderbites, extensions as $$
  select lr.id, lr.position, lr.note,
         r.id, r.name,
         extensions.st_y(r.location::extensions.geometry),
         extensions.st_x(r.location::extensions.geometry),
         r.price_level, r.rec_count, r.score, r.cover_photo_url, r.city_id
  from list_restaurants lr
  join restaurants r on r.id = lr.restaurant_id
  where lr.list_id = lid
    and r.deleted_at is null and r.status = 'active'
  order by lr.position asc
  limit 200;
$$;
