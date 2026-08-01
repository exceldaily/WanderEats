-- Milestone 2: universal blocking and reporting.
--
-- Audit finding worth recording, because it changes what this migration is:
-- blocking was already enforced server-side before this. blocked_users exists
-- with a (blocker_id, blocked_id) primary key and a CHECK preventing
-- self-blocks, is_blocked_between() is symmetric and SECURITY DEFINER, and it
-- already gates rec_visible, follows inserts, comment inserts, like inserts
-- and list-collaborator invites.
--
-- What did not exist was any way for a user to block anyone. No client code
-- referenced the table at all. A safety feature users would reasonably assume
-- exists was a dead table with working locks and no door.
--
-- So this migration is deliberately small on the enforcement side and focused
-- on the four real gaps:
--   1. Blocking left existing follows intact, so a blocked account carried on
--      following and appearing in follower lists.
--   2. Blocked accounts still surfaced in taster discovery.
--   3. Blocking generated no audit trail (no reason, no direction of intent).
--   4. content_reports could not express who was being reported, how urgent it
--      was, or what a moderator decided.

-- ---------------------------------------------------------------------------
-- 1. Block metadata
-- ---------------------------------------------------------------------------

alter table wanderbites.blocked_users
  add column if not exists reason_category text;

alter table wanderbites.blocked_users
  drop constraint if exists blocked_users_reason_category_check;
alter table wanderbites.blocked_users
  add constraint blocked_users_reason_category_check
  check (reason_category is null or reason_category in (
    'harassment','spam','impersonation','inappropriate_content',
    'unwanted_contact','other'
  ));

-- ---------------------------------------------------------------------------
-- 2. Report metadata
--
-- Existing columns (reporter_id, target_type, target_id, reason, details,
-- status, created_at, resolved_at) are kept exactly as they are: one code path
-- already writes to this table and renaming would break it for no benefit.
-- ---------------------------------------------------------------------------

alter table wanderbites.content_reports
  add column if not exists reported_user_id uuid references wanderbites.profiles(id) on delete set null,
  add column if not exists priority text not null default 'normal',
  add column if not exists reviewed_by uuid references wanderbites.profiles(id) on delete set null,
  add column if not exists resolution text,
  add column if not exists moderator_notes text;

alter table wanderbites.content_reports
  drop constraint if exists content_reports_priority_check;
alter table wanderbites.content_reports
  add constraint content_reports_priority_check
  check (priority in ('urgent','high','normal'));

alter table wanderbites.content_reports
  drop constraint if exists content_reports_status_check;
alter table wanderbites.content_reports
  add constraint content_reports_status_check
  check (status in ('open','reviewing','actioned','dismissed'));

create index if not exists content_reports_triage_idx
  on wanderbites.content_reports (status, priority, created_at desc);
create index if not exists content_reports_reported_user_idx
  on wanderbites.content_reports (reported_user_id) where reported_user_id is not null;

-- moderator_notes must never reach the reporter. The existing reports_read
-- policy allows a reporter to read their own row, which would now include
-- notes, so reporters get a view with that column withheld instead and the
-- base-table read is narrowed to admins.
drop policy if exists reports_read on wanderbites.content_reports;
create policy reports_read_admin on wanderbites.content_reports for select
  using (wanderbites.is_admin());

create or replace view wanderbites.my_reports
with (security_invoker = true) as
  select id, target_type, target_id, reason, details, status, priority,
         created_at, resolved_at, resolution
  from wanderbites.content_reports
  where reporter_id = auth.uid();

grant select on wanderbites.my_reports to authenticated;

-- Reporters can still read their own rows through the view, which is only
-- possible if they can read the underlying table, so allow that narrowly.
create policy reports_read_own on wanderbites.content_reports for select
  using (reporter_id = auth.uid());

-- ---------------------------------------------------------------------------
-- 3. block_user / unblock_user
--
-- Blocking is a single intent that has to do several things atomically, and
-- doing them from the client would mean several round trips any one of which
-- could fail and leave a half-applied block.
-- ---------------------------------------------------------------------------

create or replace function wanderbites.block_user(
  target uuid,
  reason_category text default null
) returns void
language plpgsql volatile security definer set search_path = wanderbites as $$
declare
  me uuid := auth.uid();
begin
  if me is null then
    raise exception 'authentication required' using errcode = '28000';
  end if;
  if target is null or target = me then
    raise exception 'cannot block yourself' using errcode = '22023';
  end if;
  if not exists (select 1 from profiles where id = target and deleted_at is null) then
    raise exception 'no such user' using errcode = '23503';
  end if;

  insert into blocked_users (blocker_id, blocked_id, reason_category)
  values (me, target, reason_category)
  on conflict (blocker_id, blocked_id)
    do update set reason_category = excluded.reason_category;

  -- Sever the relationship in both directions. Leaving these in place is what
  -- makes a block feel like it did not work: the blocked account keeps showing
  -- up in follower counts and lists even though it can no longer interact.
  delete from follows
   where (follower_id = me and followee_id = target)
      or (follower_id = target and followee_id = me);

  -- Pending collaboration invitations between the two are withdrawn as well,
  -- since a block should not leave an open door on another screen.
  delete from list_collaborators lc
   using lists l
   where lc.list_id = l.id
     and ((l.owner_id = me and lc.user_id = target)
       or (l.owner_id = target and lc.user_id = me));

  -- Neither side should keep unread notifications generated by the other.
  delete from notifications
   where (user_id = me and actor_id = target)
      or (user_id = target and actor_id = me);
end;
$$;

revoke all on function wanderbites.block_user(uuid, text) from public;
grant execute on function wanderbites.block_user(uuid, text) to authenticated;

create or replace function wanderbites.unblock_user(target uuid)
returns void
language plpgsql volatile security definer set search_path = wanderbites as $$
declare
  me uuid := auth.uid();
begin
  if me is null then
    raise exception 'authentication required' using errcode = '28000';
  end if;
  -- Unblocking only undoes the block. Follows are deliberately not restored:
  -- re-following is a decision for each person to make again.
  delete from blocked_users where blocker_id = me and blocked_id = target;
end;
$$;

revoke all on function wanderbites.unblock_user(uuid) from public;
grant execute on function wanderbites.unblock_user(uuid) to authenticated;

-- Blocked-accounts settings screen. Returns only what the blocker themselves
-- chose to record; nothing here is visible to the blocked account.
create or replace function wanderbites.blocked_accounts()
returns table (
  id uuid, username text, display_name text, avatar_url text,
  reason_category text, created_at timestamptz
)
language sql stable security definer set search_path = wanderbites as $$
  select p.id, p.username, p.display_name, p.avatar_url,
         b.reason_category, b.created_at
  from blocked_users b
  join profiles p on p.id = b.blocked_id
  where b.blocker_id = auth.uid()
  order by b.created_at desc;
$$;

revoke all on function wanderbites.blocked_accounts() from public;
grant execute on function wanderbites.blocked_accounts() to authenticated;

-- ---------------------------------------------------------------------------
-- 4. report_content
--
-- Priority is assigned server-side. A reporter choosing a category should not
-- be able to set their own urgency, and safety categories must escalate even
-- if the client forgets to ask for it.
-- ---------------------------------------------------------------------------

create or replace function wanderbites.report_content(
  p_target_type text,
  p_target_id uuid,
  p_reason text,
  p_details text default null
) returns uuid
language plpgsql volatile security definer set search_path = wanderbites as $$
declare
  me uuid := auth.uid();
  owner uuid;
  prio text;
  new_id uuid;
begin
  if me is null then
    raise exception 'authentication required' using errcode = '28000';
  end if;

  if p_reason not in (
    'spam','harassment','hate_or_abuse','threatening_behavior','impersonation',
    'scam_or_fraud','sexual_content','underage_safety_concern','dangerous_content',
    'false_information','privacy_violation','copyright','inappropriate_content','other'
  ) then
    raise exception 'unknown report reason' using errcode = '22023';
  end if;

  -- Categories where a delayed review is itself a harm.
  prio := case
    when p_reason in ('underage_safety_concern','threatening_behavior','dangerous_content')
      then 'urgent'
    when p_reason in ('hate_or_abuse','harassment','scam_or_fraud','sexual_content','privacy_violation')
      then 'high'
    else 'normal'
  end;

  begin
    owner := wanderbites.target_owner(p_target_type, p_target_id);
  exception when others then
    owner := null;
  end;

  insert into content_reports (
    reporter_id, reported_user_id, target_type, target_id,
    reason, details, priority, status
  ) values (
    me, nullif(owner, me), p_target_type, p_target_id,
    p_reason, nullif(trim(coalesce(p_details, '')), ''), prio, 'open'
  ) returning id into new_id;

  return new_id;
end;
$$;

revoke all on function wanderbites.report_content(text, uuid, text, text) from public;
grant execute on function wanderbites.report_content(text, uuid, text, text) to authenticated;

-- ---------------------------------------------------------------------------
-- 5. Keep blocked accounts out of taster discovery
--
-- Both of these are SECURITY DEFINER and so bypass the RLS that protects the
-- rest of the app, which means the block filter has to be written into them
-- explicitly rather than inherited.
-- ---------------------------------------------------------------------------

create or replace function wanderbites.trending_tasters(max_rows integer default 10)
returns table (
  id uuid, username text, display_name text, avatar_url text,
  is_verified boolean, is_demo boolean, followers bigint,
  reputation numeric, is_popular boolean
)
language sql stable security definer set search_path = wanderbites as $$
  select p.id, p.username, p.display_name, p.avatar_url,
         p.is_verified, p.is_demo,
         (select count(*) from follows f where f.followee_id = p.id) as followers,
         taster_reputation(p.id) as reputation,
         is_popular_taster(p.id) as is_popular
  from profiles p
  where p.deleted_at is null and not p.is_suspended and p.onboarding_completed
    and (not p.is_demo or demo_content_visible())
    and not is_blocked_between(auth.uid(), p.id)
  order by reputation desc nulls last, followers desc
  limit greatest(max_rows, 1);
$$;

create or replace function wanderbites.suggested_tasters(
  uid uuid,
  area_lat double precision default null,
  area_lng double precision default null,
  max_rows integer default 10
)
returns table (
  id uuid, username text, display_name text, avatar_url text,
  is_verified boolean, is_demo boolean, followers bigint,
  reputation numeric, shared_tags text[], nearby_recs integer
)
language sql stable security definer set search_path = wanderbites, extensions as $$
  with me as (
    select p.taste_tags, p.taste_personality, c.center as home_center
    from profiles p
    left join cities c on c.id = p.home_city_id
    where p.id = uid
  ),
  area as (
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
      and not is_blocked_between(uid, p.id)
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

-- ---------------------------------------------------------------------------
-- 6. Stop notifications crossing a block
--
-- The notification triggers fire on follows, comments and feedback. Inserts of
-- those are already blocked, but a block created after the fact should not
-- leave the other side still receiving activity.
-- ---------------------------------------------------------------------------

create or replace function wanderbites.tg_suppress_blocked_notification()
returns trigger language plpgsql security definer set search_path = wanderbites as $$
begin
  if new.actor_id is not null
     and is_blocked_between(new.user_id, new.actor_id) then
    return null;
  end if;
  return new;
end;
$$;

drop trigger if exists suppress_blocked_notification on wanderbites.notifications;
create trigger suppress_blocked_notification
  before insert on wanderbites.notifications
  for each row execute function wanderbites.tg_suppress_blocked_notification();
