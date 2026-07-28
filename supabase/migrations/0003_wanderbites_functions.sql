-- WanderBites 0003: RPCs, scoring, notifications, badges.
-- Trust math lives here, server-side. Clients never compute or write scores.

-- ---------------------------------------------------------------------------
-- Map: markers within the visible bounds. Hard capped, ordered so the most
-- recommended places win when the cap bites. RLS applies (invoker).
-- ---------------------------------------------------------------------------
create or replace function wanderbites.restaurants_in_bounds(
  min_lng double precision, min_lat double precision,
  max_lng double precision, max_lat double precision,
  max_rows int default 200
) returns table (
  id uuid, name text, lat double precision, lng double precision,
  price_level smallint, rec_count int, save_count int, score numeric,
  cover_photo_url text, city_id uuid
) language sql stable set search_path = wanderbites, extensions as $$
  select r.id, r.name,
         extensions.st_y(r.location::extensions.geometry) as lat,
         extensions.st_x(r.location::extensions.geometry) as lng,
         r.price_level, r.rec_count, r.save_count, r.score,
         r.cover_photo_url, r.city_id
  from restaurants r
  where r.deleted_at is null and r.status = 'active'
    and r.location operator(extensions.&&)
        extensions.st_makeenvelope(min_lng, min_lat, max_lng, max_lat, 4326)::extensions.geography
  order by r.rec_count desc, r.save_count desc
  limit least(greatest(max_rows, 1), 400);
$$;

-- ---------------------------------------------------------------------------
-- Nearby: distance-sorted within a radius (meters).
-- ---------------------------------------------------------------------------
create or replace function wanderbites.nearby_restaurants(
  in_lng double precision, in_lat double precision,
  radius_m double precision default 3000, max_rows int default 50
) returns table (
  id uuid, name text, lat double precision, lng double precision,
  distance_m double precision, price_level smallint, rec_count int,
  score numeric, cover_photo_url text, city_id uuid
) language sql stable set search_path = wanderbites, extensions as $$
  select r.id, r.name,
         extensions.st_y(r.location::extensions.geometry),
         extensions.st_x(r.location::extensions.geometry),
         extensions.st_distance(r.location,
           extensions.st_setsrid(extensions.st_makepoint(in_lng, in_lat), 4326)::extensions.geography),
         r.price_level, r.rec_count, r.score, r.cover_photo_url, r.city_id
  from restaurants r
  where r.deleted_at is null and r.status = 'active'
    and extensions.st_dwithin(r.location,
          extensions.st_setsrid(extensions.st_makepoint(in_lng, in_lat), 4326)::extensions.geography,
          radius_m)
  order by 5 asc
  limit least(greatest(max_rows, 1), 200);
$$;

-- ---------------------------------------------------------------------------
-- Restaurant summary: who recommends it (followed Tasters first), top quote.
-- ---------------------------------------------------------------------------
create or replace function wanderbites.restaurant_summary(rid uuid)
returns jsonb language sql stable security definer set search_path = wanderbites as $$
  select jsonb_build_object(
    'tasters', coalesce((
      select jsonb_agg(t) from (
        select p.id, p.username, p.display_name, p.avatar_url, p.is_verified,
               exists(select 1 from follows f
                      where f.follower_id = auth.uid() and f.followee_id = p.id) as followed
        from recommendations rec
        join profiles p on p.id = rec.user_id and p.deleted_at is null and not p.is_suspended
        where rec.restaurant_id = rid and rec.deleted_at is null and rec.visibility = 'public'
        order by 6 desc, rec.created_at desc
        limit 6
      ) t), '[]'::jsonb),
    'top_quote', (
      select jsonb_build_object('body', rec.body, 'what_to_order', rec.what_to_order,
                                'username', p.username, 'display_name', p.display_name)
      from recommendations rec
      join profiles p on p.id = rec.user_id and p.deleted_at is null and not p.is_suspended
      where rec.restaurant_id = rid and rec.deleted_at is null and rec.visibility = 'public'
      order by exists(select 1 from follows f
                      where f.follower_id = auth.uid() and f.followee_id = p.id) desc,
               rec.created_at desc
      limit 1
    )
  );
$$;

-- ---------------------------------------------------------------------------
-- Reputation. Inputs: verified feedback volume, positive share, recency,
-- unique users influenced, breadth, sample-size confidence. 0..10.
-- Formula intentionally not exposed in the UI.
-- ---------------------------------------------------------------------------
create or replace function wanderbites.taster_reputation(uid uuid)
returns numeric language sql stable security definer set search_path = wanderbites as $$
  with fb as (
    select f.rating, f.user_id as rater, f.created_at,
           r.restaurant_id, rest.city_id
    from recommendation_feedback f
    join recommendations r on r.id = f.recommendation_id and r.deleted_at is null
    join restaurants rest on rest.id = r.restaurant_id
    where r.user_id = uid
  ), agg as (
    select count(*)::numeric as n,
           coalesce(sum(case rating when 'exact' then 1.0 when 'great' then 1.0
                                    when 'somewhat' then 0.5 else 0.0 end), 0) as pos,
           count(distinct rater)::numeric as unique_raters,
           count(distinct city_id)::numeric as cities,
           coalesce(sum(case when created_at > now() - interval '90 days' then 1 else 0 end), 0)::numeric as recent
    from fb
  )
  select round(least(10.0,
    case when n = 0 then 0
         else (pos / n)                                -- positive share
              * (n / (n + 5.0))                        -- sample-size confidence
              * (0.85 + 0.15 * least(recent / greatest(n,1), 1.0))  -- recency
              * 10.0
              + least(unique_raters, 20) * 0.05        -- unique users influenced
              + least(cities, 10) * 0.05               -- breadth
    end), 2)
  from agg;
$$;

create or replace function wanderbites.taster_stats(uid uuid)
returns jsonb language sql stable security definer set search_path = wanderbites as $$
  select jsonb_build_object(
    'followers', (select count(*) from follows where followee_id = uid),
    'following', (select count(*) from follows where follower_id = uid),
    'recommendations', (select count(*) from recommendations
                        where user_id = uid and deleted_at is null),
    'saves', (select count(*) from restaurant_saves where user_id = uid),
    'visits', (select count(*) from restaurant_visits where user_id = uid),
    'cities_explored', (select count(distinct r.city_id)
                        from restaurant_visits v join restaurants r on r.id = v.restaurant_id
                        where v.user_id = uid),
    'countries_visited', (select count(distinct c.country_id)
                          from restaurant_visits v
                          join restaurants r on r.id = v.restaurant_id
                          join cities c on c.id = r.city_id
                          where v.user_id = uid),
    'reputation', taster_reputation(uid)
  );
$$;

-- ---------------------------------------------------------------------------
-- Trending
-- ---------------------------------------------------------------------------
create or replace function wanderbites.trending_restaurants(city_slug text default null, max_rows int default 20)
returns setof wanderbites.restaurants language sql stable set search_path = wanderbites as $$
  select r.* from restaurants r
  left join cities c on c.id = r.city_id
  where r.deleted_at is null and r.status = 'active'
    and (city_slug is null or c.slug = city_slug)
  order by (select count(*) from recommendations rec
            where rec.restaurant_id = r.id and rec.deleted_at is null
              and rec.created_at > now() - interval '30 days') * 3
         + (select count(*) from restaurant_saves s
            where s.restaurant_id = r.id
              and s.created_at > now() - interval '30 days') desc,
           r.rec_count desc
  limit least(greatest(max_rows, 1), 50);
$$;

create or replace function wanderbites.trending_tasters(max_rows int default 20)
returns table (
  id uuid, username text, display_name text, avatar_url text,
  is_verified boolean, bio text, home_city_id uuid,
  followers bigint, reputation numeric
) language sql stable security definer set search_path = wanderbites as $$
  select p.id, p.username, p.display_name, p.avatar_url, p.is_verified, p.bio, p.home_city_id,
         (select count(*) from follows f where f.followee_id = p.id) as followers,
         taster_reputation(p.id) as reputation
  from profiles p
  where p.deleted_at is null and not p.is_suspended and p.onboarding_completed
  order by (select count(*) from follows f
            where f.followee_id = p.id and f.created_at > now() - interval '30 days') desc,
           reputation desc
  limit least(greatest(max_rows, 1), 50);
$$;

-- ---------------------------------------------------------------------------
-- Universal search, grouped. pg_trgm + prefix matching.
-- ---------------------------------------------------------------------------
create or replace function wanderbites.search_all(q text, per_group int default 5)
returns jsonb language sql stable security definer set search_path = wanderbites, extensions as $$
  with needle as (select trim(q) as t)
  select jsonb_build_object(
    'restaurants', coalesce((select jsonb_agg(x) from (
      select r.id, r.name, r.cover_photo_url, r.price_level, r.rec_count,
             c.name as city_name
      from restaurants r join cities c on c.id = r.city_id, needle
      where r.deleted_at is null and r.status = 'active'
        and (r.name ilike '%' || needle.t || '%' or r.name % needle.t)
      order by extensions.similarity(r.name, needle.t) desc, r.rec_count desc
      limit per_group) x), '[]'::jsonb),
    'tasters', coalesce((select jsonb_agg(x) from (
      select p.id, p.username, p.display_name, p.avatar_url, p.is_verified
      from profiles p, needle
      where p.deleted_at is null and not p.is_suspended and p.onboarding_completed
        and (p.username ilike '%' || needle.t || '%'
             or p.display_name ilike '%' || needle.t || '%')
      order by extensions.similarity(p.display_name, needle.t) desc
      limit per_group) x), '[]'::jsonb),
    'lists', coalesce((select jsonb_agg(x) from (
      select l.id, l.title, l.cover_url, l.owner_id,
             (select count(*) from list_restaurants lr where lr.list_id = l.id) as restaurant_count
      from lists l, needle
      where l.deleted_at is null and l.visibility = 'public'
        and l.title ilike '%' || needle.t || '%'
      order by extensions.similarity(l.title, needle.t) desc
      limit per_group) x), '[]'::jsonb),
    'cities', coalesce((select jsonb_agg(x) from (
      select c.id, c.name, c.slug, c.hero_photo_url, co.name as country_name
      from cities c join countries co on co.id = c.country_id, needle
      where c.name ilike '%' || needle.t || '%'
      order by extensions.similarity(c.name, needle.t) desc
      limit per_group) x), '[]'::jsonb),
    'cuisines', coalesce((select jsonb_agg(x) from (
      select cu.id, cu.name, cu.slug, cu.emoji
      from cuisines cu, needle
      where cu.name ilike '%' || needle.t || '%'
      limit per_group) x), '[]'::jsonb)
  );
$$;

-- ---------------------------------------------------------------------------
-- Restaurant aggregate score: kept in sync by trigger on feedback.
-- ---------------------------------------------------------------------------
create or replace function wanderbites.tg_restaurant_score()
returns trigger language plpgsql security definer set search_path = wanderbites as $$
declare
  rid uuid;
begin
  select r.restaurant_id into rid from recommendations r
  where r.id = coalesce(new.recommendation_id, old.recommendation_id);
  if rid is not null then
    update restaurants set score = (
      select round(avg(case f.rating when 'exact' then 10 when 'great' then 9
                                     when 'somewhat' then 6 else 2 end)::numeric, 2)
      from recommendation_feedback f
      join recommendations r2 on r2.id = f.recommendation_id
      where r2.restaurant_id = rid and r2.deleted_at is null
    ) where id = rid;
  end if;
  return coalesce(new, old);
end $$;

create trigger restaurant_score_maintain
  after insert or update or delete on wanderbites.recommendation_feedback
  for each row execute function wanderbites.tg_restaurant_score();

-- ---------------------------------------------------------------------------
-- Notifications: created server-side by triggers (no client insert policy).
-- ---------------------------------------------------------------------------
create or replace function wanderbites.tg_notify_follow()
returns trigger language plpgsql security definer set search_path = wanderbites as $$
begin
  insert into notifications (user_id, actor_id, type, payload)
  values (new.followee_id, new.follower_id, 'follow', '{}');
  return new;
end $$;
create trigger notify_follow after insert on wanderbites.follows
  for each row execute function wanderbites.tg_notify_follow();

create or replace function wanderbites.tg_notify_feedback()
returns trigger language plpgsql security definer set search_path = wanderbites as $$
declare author uuid;
begin
  select user_id into author from recommendations where id = new.recommendation_id;
  if author is not null and author <> new.user_id then
    insert into notifications (user_id, actor_id, type, payload)
    values (author, new.user_id, 'rec_feedback',
            jsonb_build_object('recommendation_id', new.recommendation_id, 'rating', new.rating));
  end if;
  return new;
end $$;
create trigger notify_feedback after insert on wanderbites.recommendation_feedback
  for each row execute function wanderbites.tg_notify_feedback();

create or replace function wanderbites.tg_notify_comment()
returns trigger language plpgsql security definer set search_path = wanderbites as $$
declare owner uuid;
begin
  owner := target_owner(new.target_type, new.target_id);
  if owner is not null and owner <> new.user_id then
    insert into notifications (user_id, actor_id, type, payload)
    values (owner, new.user_id, 'comment',
            jsonb_build_object('target_type', new.target_type, 'target_id', new.target_id,
                               'comment_id', new.id));
  end if;
  return new;
end $$;
create trigger notify_comment after insert on wanderbites.comments
  for each row execute function wanderbites.tg_notify_comment();

create or replace function wanderbites.tg_notify_list_invite()
returns trigger language plpgsql security definer set search_path = wanderbites as $$
begin
  insert into notifications (user_id, actor_id, type, payload)
  values (new.user_id, (select owner_id from lists where id = new.list_id),
          'list_invite', jsonb_build_object('list_id', new.list_id));
  return new;
end $$;
create trigger notify_list_invite after insert on wanderbites.list_collaborators
  for each row execute function wanderbites.tg_notify_list_invite();

-- Followers of a list hear about new entries.
create or replace function wanderbites.tg_notify_list_update()
returns trigger language plpgsql security definer set search_path = wanderbites as $$
begin
  insert into notifications (user_id, actor_id, type, payload)
  select lf.user_id, new.added_by, 'saved_list_update',
         jsonb_build_object('list_id', new.list_id, 'restaurant_id', new.restaurant_id)
  from list_follows lf
  where lf.list_id = new.list_id and lf.user_id <> coalesce(new.added_by, lf.user_id);
  return new;
end $$;
create trigger notify_list_update after insert on wanderbites.list_restaurants
  for each row execute function wanderbites.tg_notify_list_update();

-- ---------------------------------------------------------------------------
-- Badges: definitions live in the badges table; this awards what is earned.
-- Called by the app after meaningful actions (visit, rec, list publish).
-- ---------------------------------------------------------------------------
create or replace function wanderbites.check_and_award_badges()
returns setof wanderbites.badges language plpgsql security definer set search_path = wanderbites as $$
declare
  uid uuid := auth.uid();
  b record;
  earned boolean;
  req_count int;
begin
  if uid is null then return; end if;
  for b in select * from badges loop
    continue when exists (select 1 from user_badges ub
                          where ub.user_id = uid and ub.badge_id = b.id);
    req_count := coalesce((b.requirement->>'count')::int, 0);
    earned := case b.requirement->>'type'
      when 'recs_count' then
        (select count(*) from recommendations
         where user_id = uid and deleted_at is null) >= req_count
      when 'visits_count' then
        (select count(*) from restaurant_visits where user_id = uid) >= req_count
      when 'saves_count' then
        (select count(*) from restaurant_saves where user_id = uid) >= req_count
      when 'cities_visited' then
        (select count(distinct r.city_id) from restaurant_visits v
         join restaurants r on r.id = v.restaurant_id
         where v.user_id = uid) >= req_count
      when 'countries_visited' then
        (select count(distinct c.country_id) from restaurant_visits v
         join restaurants r on r.id = v.restaurant_id
         join cities c on c.id = r.city_id
         where v.user_id = uid) >= req_count
      when 'cuisine_recs' then
        (select count(*) from recommendations rec
         join restaurant_cuisines rc on rc.restaurant_id = rec.restaurant_id
         join cuisines cu on cu.id = rc.cuisine_id
         where rec.user_id = uid and rec.deleted_at is null
           and cu.slug = b.requirement->>'cuisine') >= req_count
      when 'lists_count' then
        (select count(*) from lists
         where owner_id = uid and deleted_at is null and visibility = 'public') >= req_count
      else false
    end;
    if earned then
      insert into user_badges (user_id, badge_id) values (uid, b.id)
      on conflict do nothing;
      insert into notifications (user_id, type, payload)
      values (uid, 'badge', jsonb_build_object('badge_slug', b.slug));
      return next b;
    end if;
  end loop;
  return;
end $$;

-- ---------------------------------------------------------------------------
-- Account deletion. IMPORTANT (shared auth pool): this deletes the
-- WanderBites profile and all owned content via cascades. It does NOT delete
-- the auth.users row, because that account may also power sibling apps in
-- this shared Supabase project. Full auth deletion stays a dashboard/admin
-- operation.
-- ---------------------------------------------------------------------------
create or replace function wanderbites.delete_account()
returns void language plpgsql security definer set search_path = wanderbites as $$
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;
  delete from profiles where id = auth.uid();
end $$;
