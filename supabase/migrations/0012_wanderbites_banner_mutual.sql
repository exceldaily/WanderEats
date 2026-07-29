-- Banner style: preset cover treatment for profiles without a photo.
alter table wanderbites.profiles
  add column if not exists banner_style text not null default 'voyage'
  check (banner_style in ('voyage','ember','gold','aqua','night'));

-- "You both love ..." — real overlap between the signed-in viewer and
-- another profile. Returns only genuine matches; the client hides the
-- section entirely when everything comes back empty.
create or replace function wanderbites.mutual_taste(other uuid)
returns jsonb
language sql stable security definer set search_path = wanderbites as $$
  with me as (select (select auth.uid()) as uid),
  mine as (select * from profiles p, me where p.id = me.uid),
  theirs as (select * from profiles where id = other)
  select case
    when (select uid from me) is null or (select uid from me) = other
      then '{}'::jsonb
    else jsonb_build_object(
      'shared_tags', coalesce((
        select jsonb_agg(t) from (
          select unnest(m.taste_tags) t from mine m
          intersect
          select unnest(o.taste_tags) from theirs o
          limit 4) x), '[]'::jsonb),
      'same_cuisine', (
        select case when
          nullif(trim(lower(coalesce(m.taste_personality->>'favorite_cuisine',''))),'') is not null
          and lower(coalesce(m.taste_personality->>'favorite_cuisine',''))
            = lower(coalesce(o.taste_personality->>'favorite_cuisine',''))
        then initcap(m.taste_personality->>'favorite_cuisine') end
        from mine m, theirs o),
      'both_saved', (
        select count(*) from restaurant_saves a
        join restaurant_saves b on b.restaurant_id = a.restaurant_id
        where a.user_id = (select uid from me) and b.user_id = other),
      'i_saved_their_recs', (
        select count(distinct r.restaurant_id)
        from recommendations r
        join restaurant_saves s on s.restaurant_id = r.restaurant_id
        where r.user_id = other and r.deleted_at is null
          and s.user_id = (select uid from me))
    )
  end;
$$;

grant execute on function wanderbites.mutual_taste(uuid) to authenticated;
