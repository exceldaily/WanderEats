-- Suggested Tasters: who to follow, based on actual fit rather than raw
-- popularity. Three independent signals, each optional so a caller with no
-- taste tags yet or no location still gets a sane (if shorter) result rather
-- than an error:
--
--   tag overlap        - shared taste_tags, the strongest "you'll like their
--                         recommendations" signal we have
--   personality match   - spice/flavor/dining_style/favorite_cuisine equality
--   area relevance      - the candidate has actually recommended places near
--                         the given point. This is deliberately NOT "lives in
--                         the same city" - a Bangkok local whose recs cluster
--                         in Chiang Mai is exactly who you want suggested when
--                         browsing Chiang Mai. Falls back to the caller's
--                         home_city_id center when no live point is passed.
--
-- Reputation is included only as a small tiebreaker, not a primary weight -
-- "suggested" is about fit, "popular" (below) is the separate raw-popularity
-- signal, and conflating them would make suggestions just re-show trending.
create or replace function wanderbites.suggested_tasters(
  uid uuid,
  area_lat double precision default null,
  area_lng double precision default null,
  max_rows integer default 10
)
returns table(
  id uuid,
  username text,
  display_name text,
  avatar_url text,
  is_verified boolean,
  is_demo boolean,
  followers bigint,
  reputation numeric,
  shared_tags text[],
  nearby_recs integer
)
language sql stable security definer set search_path = wanderbites, extensions as $$
  with me as (
    select p.taste_tags, p.taste_personality, c.center as home_center
    from profiles p
    left join cities c on c.id = p.home_city_id
    where p.id = uid
  ),
  area as (
    -- An explicit point wins; otherwise fall back to the caller's home city.
    select coalesce(
      case when area_lat is not null and area_lng is not null
        then st_setsrid(st_makepoint(area_lng, area_lat), 4326)::geography
      end,
      (select home_center from me)
    ) as point
  ),
  candidates as (
    select
      p.id, p.username, p.display_name, p.avatar_url,
      p.is_verified, p.is_demo,
      (select count(*) from follows f where f.followee_id = p.id) as followers,
      taster_reputation(p.id) as reputation,
      array(
        select unnest(p.taste_tags)
        intersect
        select unnest((select taste_tags from me))
      ) as shared_tags,
      (
        select count(*)::int from recommendations r
        join restaurants rest on rest.id = r.restaurant_id
        where r.user_id = p.id and r.deleted_at is null
          and (select point from area) is not null
          and st_dwithin(rest.location, (select point from area), 50000)
      ) as nearby_recs
    from profiles p
    where p.id <> uid
      and p.deleted_at is null
      and not p.is_suspended
      and p.onboarding_completed
      and (not p.is_demo or demo_content_visible())
      and p.id not in (select followee_id from follows where follower_id = uid)
  ),
  scored as (
    select c.*,
      cardinality(shared_tags) as tag_overlap,
      (
        select count(*) from (values
          ((select taste_personality->>'spice' from me) is not distinct from
            (select taste_personality->>'spice' from profiles where id = c.id)
            and (select taste_personality->>'spice' from me) is not null),
          ((select taste_personality->>'flavor' from me) is not distinct from
            (select taste_personality->>'flavor' from profiles where id = c.id)
            and (select taste_personality->>'flavor' from me) is not null),
          ((select taste_personality->>'dining_style' from me) is not distinct from
            (select taste_personality->>'dining_style' from profiles where id = c.id)
            and (select taste_personality->>'dining_style' from me) is not null),
          ((select taste_personality->>'favorite_cuisine' from me) is not distinct from
            (select taste_personality->>'favorite_cuisine' from profiles where id = c.id)
            and (select taste_personality->>'favorite_cuisine' from me) is not null)
        ) as t(matched) where matched = true
      ) as personality_matches
    from candidates c
  )
  select id, username, display_name, avatar_url, is_verified, is_demo,
         followers, reputation, shared_tags, nearby_recs
  from scored
  where tag_overlap > 0 or personality_matches > 0 or nearby_recs > 0
  order by
    (tag_overlap * 3.0
      + personality_matches * 2.0
      + least(nearby_recs, 5) * 4.0
      + coalesce(reputation, 0) * 0.3) desc,
    followers desc
  limit greatest(max_rows, 1);
$$;

-- Popular: a real trust-and-reach threshold, not "top N regardless of scale".
-- Thresholds live in app_settings so they can be tuned as the userbase grows
-- without a release - the same pattern as the guide-eligibility threshold.
insert into wanderbites.app_settings (key, value)
values
  ('popular_taster_min_followers', '10'::jsonb),
  ('popular_taster_min_reputation', '5.0'::jsonb)
on conflict (key) do nothing;

create or replace function wanderbites.is_popular_taster(uid uuid)
returns boolean language sql stable security definer set search_path = wanderbites as $$
  select
    (select count(*) from follows where followee_id = uid)
      >= coalesce((select (value #>> '{}')::int from app_settings
                    where key = 'popular_taster_min_followers'), 10)
    and taster_reputation(uid)
      >= coalesce((select (value #>> '{}')::numeric from app_settings
                    where key = 'popular_taster_min_reputation'), 5.0);
$$;

-- Surface it on the existing trending list too, so "Trending Tasters" cards
-- can show the same badge without a second round trip. Signature is changing
-- (new output column), so the old one has to go first.
drop function if exists wanderbites.trending_tasters(integer);

create function wanderbites.trending_tasters(max_rows integer default 10)
returns table(id uuid, username text, display_name text, avatar_url text,
              is_verified boolean, is_demo boolean, followers bigint,
              reputation numeric, is_popular boolean)
language sql stable security definer set search_path = wanderbites as $$
  select p.id, p.username, p.display_name, p.avatar_url,
         p.is_verified, p.is_demo,
         (select count(*) from follows f where f.followee_id = p.id) as followers,
         taster_reputation(p.id) as reputation,
         is_popular_taster(p.id) as is_popular
  from profiles p
  where p.deleted_at is null and not p.is_suspended and p.onboarding_completed
    and (not p.is_demo or demo_content_visible())
  order by reputation desc nulls last, followers desc
  limit greatest(max_rows, 1);
$$;
