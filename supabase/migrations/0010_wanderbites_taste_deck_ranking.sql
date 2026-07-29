-- Ranked deck for a point. Trust first, popularity last: a place recommended
-- by someone you follow outranks a place merely saved by many strangers.
-- Returns a labelled reason so the card can state WHY it surfaced, and keeps
-- all ranking logic server-side, out of presentation code.
create or replace function wanderbites.taste_deck(
  p_lat double precision,
  p_lng double precision,
  p_radius_m integer default 3000,
  p_limit integer default 30,
  p_max_price smallint default null,
  p_cuisine_id uuid default null
) returns table (
  id uuid, name text, lat double precision, lng double precision,
  price_level smallint, distance_m double precision,
  score numeric, rec_count integer, save_count integer,
  cover_photo_url text, city_name text,
  reason text, via_taster_id uuid, rank_score numeric
)
language sql stable security definer set search_path = wanderbites, extensions as $$
with me as (select (select auth.uid()) as uid),
origin as (
  select extensions.st_setsrid(
    extensions.st_makepoint(p_lng, p_lat), 4326)::extensions.geography as g
),
my_cuisines as (
  select unnest(coalesce(p.favorite_cuisines, '{}'))::uuid as cuisine_id
  from profiles p, me where p.id = me.uid
),
candidates as (
  select r.*, extensions.st_distance(r.location, o.g) as dist
  from restaurants r, origin o
  where r.deleted_at is null and r.status = 'active'
    and extensions.st_dwithin(r.location, o.g, greatest(p_radius_m, 250))
    and (p_max_price is null or r.price_level is null or r.price_level <= p_max_price)
    and (p_cuisine_id is null or exists (
          select 1 from restaurant_cuisines rc
          where rc.restaurant_id = r.id and rc.cuisine_id = p_cuisine_id))
    -- Already saved or visited: nothing left to decide.
    and not exists (select 1 from restaurant_saves s, me
                    where s.restaurant_id = r.id and s.user_id = me.uid)
    and not exists (select 1 from restaurant_visits v, me
                    where v.restaurant_id = r.id and v.user_id = me.uid)
),
followed_rec as (
  -- Strongest signal: a taster this user follows recommended this place.
  select c.id as rid, f.followee_id as taster, taster_reputation(f.followee_id) as rep
  from candidates c
  join recommendations rec on rec.restaurant_id = c.id and rec.deleted_at is null
  join follows f on f.followee_id = rec.user_id
  join me on f.follower_id = me.uid
),
trusted_rec as (
  -- Next: high-reputation tasters the user does not follow yet.
  select c.id as rid, rec.user_id as taster, taster_reputation(rec.user_id) as rep
  from candidates c
  join recommendations rec on rec.restaurant_id = c.id and rec.deleted_at is null
),
cuisine_match as (
  select distinct c.id as rid
  from candidates c
  join restaurant_cuisines rc on rc.restaurant_id = c.id
  join my_cuisines mc on mc.cuisine_id = rc.cuisine_id
),
skips as (
  select s.restaurant_id as rid, s.skip_count, s.last_skipped_at
  from restaurant_skips s, me where s.user_id = me.uid
),
scored as (
  select c.id, c.name,
    extensions.st_y(c.location::extensions.geometry) as lat,
    extensions.st_x(c.location::extensions.geometry) as lng,
    c.price_level, c.dist as distance_m, c.score, c.rec_count, c.save_count,
    c.cover_photo_url, ci.name as city_name,
    (select fr.taster from followed_rec fr where fr.rid = c.id
      order by fr.rep desc nulls last limit 1) as followed_taster,
    (select tr.taster from trusted_rec tr where tr.rid = c.id
      order by tr.rep desc nulls last limit 1) as trusted_taster,
    (select max(fr.rep) from followed_rec fr where fr.rid = c.id) as followed_rep,
    (select max(tr.rep) from trusted_rec tr where tr.rid = c.id) as trusted_rep,
    exists (select 1 from cuisine_match cm where cm.rid = c.id) as cuisine_hit,
    coalesce((select sk.skip_count from skips sk where sk.rid = c.id), 0) as skip_count,
    (select sk.last_skipped_at from skips sk where sk.rid = c.id) as last_skipped
  from candidates c
  left join cities ci on ci.id = c.city_id
),
ranked as (
  select s.*,
    round((
        -- trust signals dominate
        (case when s.followed_taster is not null then 45 else 0 end)
      + coalesce(s.followed_rep, 0) * 1.5
      + (case when s.followed_taster is null and s.trusted_rep >= 6 then 18 else 0 end)
      + coalesce(s.score, 0) * 2.0
      + (case when s.cuisine_hit then 12 else 0 end)
        -- proximity: full credit nearby, tapering to zero at the radius edge
      + greatest(0, 15 * (1 - (s.distance_m / greatest(p_radius_m, 250))))
        -- a nod to popularity, deliberately small and capped
      + least(coalesce(s.rec_count, 0), 10) * 0.6
      + least(coalesce(s.save_count, 0), 20) * 0.2
        -- hidden gems: quality without the crowd
      + (case when coalesce(s.score, 0) >= 7 and coalesce(s.save_count, 0) < 5
              then 10 else 0 end)
        -- skips damp rather than exclude, and decay back over a fortnight
      - (s.skip_count * 22
         * (case when s.last_skipped is null then 0
                 else greatest(0, 1 - (extract(epoch from (now() - s.last_skipped)) / 1209600.0))
            end))
    )::numeric, 3) as rank_score
  from scored s
)
select id, name, lat, lng, price_level, distance_m, score, rec_count, save_count,
  cover_photo_url, city_name,
  case
    when followed_taster is not null then 'Recommended by someone you follow'
    when cuisine_hit and trusted_rep >= 6 then 'Matches your taste, loved by trusted Tasters'
    when cuisine_hit then 'Matches cuisines you like'
    when coalesce(score,0) >= 7 and coalesce(save_count,0) < 5 then 'Hidden gem nearby'
    when trusted_rep >= 6 then 'Popular with trusted Tasters'
    when rec_count > 0 then 'Recommended nearby'
    else 'New nearby'
  end as reason,
  coalesce(followed_taster, trusted_taster) as via_taster_id,
  rank_score
from ranked
order by rank_score desc, distance_m asc
limit least(greatest(p_limit, 1), 60);
$$;

grant execute on function wanderbites.taste_deck(
  double precision, double precision, integer, integer, smallint, uuid)
to authenticated;
