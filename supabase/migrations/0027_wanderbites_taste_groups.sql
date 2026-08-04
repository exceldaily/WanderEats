-- Taste Groups (Premium M5).
--
-- Creating a group is the paid capability (create_taste_groups); joining,
-- browsing and contributing picks stay free, because a community feature
-- nobody can join sells nothing. Age plays no part here - groups are food
-- talk, not private messaging.
--
-- Same shape as messaging: tables are read via RLS, every write goes through
-- a SECURITY DEFINER RPC that re-checks the rules.
--
-- Rollback: drop functions create_taste_group, join_taste_group,
-- leave_taste_group, add_group_pick, remove_group_pick, taste_groups_list;
-- drop tables taste_group_picks, taste_group_members, taste_groups.

create table wanderbites.taste_groups (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 3 and 60),
  description text check (char_length(description) <= 280),
  emoji text check (char_length(emoji) <= 8),
  creator_id uuid not null references wanderbites.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  deleted_at timestamptz
);

create index taste_groups_creator_idx on wanderbites.taste_groups (creator_id);

create table wanderbites.taste_group_members (
  group_id uuid not null references wanderbites.taste_groups(id) on delete cascade,
  user_id uuid not null references wanderbites.profiles(id) on delete cascade,
  role text not null default 'member' check (role in ('owner', 'member')),
  joined_at timestamptz not null default now(),
  primary key (group_id, user_id)
);

create index taste_group_members_user_idx on wanderbites.taste_group_members (user_id);

create table wanderbites.taste_group_picks (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references wanderbites.taste_groups(id) on delete cascade,
  restaurant_id uuid not null references wanderbites.restaurants(id) on delete cascade,
  added_by uuid not null references wanderbites.profiles(id) on delete cascade,
  note text check (char_length(note) <= 280),
  created_at timestamptz not null default now(),
  unique (group_id, restaurant_id)
);

create index taste_group_picks_group_idx
  on wanderbites.taste_group_picks (group_id, created_at desc);

alter table wanderbites.taste_groups enable row level security;
alter table wanderbites.taste_group_members enable row level security;
alter table wanderbites.taste_group_picks enable row level security;

-- Groups are discoverable by everyone signed in; membership and picks too.
-- (Private groups would add a visibility column + tighter policies later.)
create policy taste_groups_read on wanderbites.taste_groups
  for select using (deleted_at is null);
create policy taste_group_members_read on wanderbites.taste_group_members
  for select using (true);
create policy taste_group_picks_read on wanderbites.taste_group_picks
  for select using (true);

grant select on wanderbites.taste_groups to authenticated;
grant select on wanderbites.taste_group_members to authenticated;
grant select on wanderbites.taste_group_picks to authenticated;

create or replace function wanderbites.create_taste_group(
  p_name text,
  p_description text default null,
  p_emoji text default null
)
returns uuid language plpgsql security definer
set search_path = wanderbites as $$
declare
  me uuid := auth.uid();
  gid uuid;
begin
  if me is null then raise exception 'group_denied:not_signed_in'; end if;
  if exists (select 1 from profiles
              where id = me and (is_suspended or deleted_at is not null)) then
    raise exception 'group_denied:account_restricted';
  end if;
  if not has_entitlement('create_taste_groups') then
    raise exception 'group_denied:premium_required';
  end if;
  -- A cap, not a business rule: keeps a runaway client from spamming groups.
  if (select count(*) from taste_groups
       where creator_id = me and deleted_at is null) >= 10 then
    raise exception 'group_denied:limit_reached';
  end if;

  insert into taste_groups (name, description, emoji, creator_id)
  values (btrim(p_name), nullif(btrim(coalesce(p_description, '')), ''), p_emoji, me)
  returning id into gid;

  insert into taste_group_members (group_id, user_id, role)
  values (gid, me, 'owner');

  return gid;
end $$;

create or replace function wanderbites.join_taste_group(p_group uuid)
returns void language plpgsql security definer
set search_path = wanderbites as $$
declare
  me uuid := auth.uid();
  creator uuid;
begin
  if me is null then raise exception 'group_denied:not_signed_in'; end if;
  if exists (select 1 from profiles
              where id = me and (is_suspended or deleted_at is not null)) then
    raise exception 'group_denied:account_restricted';
  end if;
  select creator_id into creator
  from taste_groups where id = p_group and deleted_at is null;
  if creator is null then raise exception 'group_denied:unavailable'; end if;
  -- A block between you and the group's creator keeps you out of their
  -- space, in either direction, same as everywhere else in the app.
  if is_blocked_between(me, creator) then
    raise exception 'group_denied:unavailable';
  end if;
  insert into taste_group_members (group_id, user_id)
  values (p_group, me)
  on conflict (group_id, user_id) do nothing;
end $$;

-- The owner leaving deletes the group: ownerless groups rot, and v1 has no
-- ownership transfer. Members are told in the UI before it happens.
create or replace function wanderbites.leave_taste_group(p_group uuid)
returns void language plpgsql security definer
set search_path = wanderbites as $$
declare
  me uuid := auth.uid();
  my_role text;
begin
  select role into my_role
  from taste_group_members where group_id = p_group and user_id = me;
  if my_role is null then return; end if;
  if my_role = 'owner' then
    update taste_groups set deleted_at = now() where id = p_group;
  else
    delete from taste_group_members
    where group_id = p_group and user_id = me;
  end if;
end $$;

create or replace function wanderbites.add_group_pick(
  p_group uuid,
  p_restaurant uuid,
  p_note text default null
)
returns uuid language plpgsql security definer
set search_path = wanderbites as $$
declare
  me uuid := auth.uid();
  pick uuid;
begin
  if not exists (select 1 from taste_group_members
                  where group_id = p_group and user_id = me) then
    raise exception 'group_denied:members_only';
  end if;
  if not exists (select 1 from taste_groups
                  where id = p_group and deleted_at is null) then
    raise exception 'group_denied:unavailable';
  end if;
  insert into taste_group_picks (group_id, restaurant_id, added_by, note)
  values (p_group, p_restaurant, me, nullif(btrim(coalesce(p_note, '')), ''))
  on conflict (group_id, restaurant_id) do nothing
  returning id into pick;
  return pick; -- null when the restaurant was already picked
end $$;

-- Your own pick, or anything as the owner (their group, their moderation).
create or replace function wanderbites.remove_group_pick(p_pick uuid)
returns void language sql security definer
set search_path = wanderbites as $$
  delete from taste_group_picks p
  where p.id = p_pick
    and (p.added_by = auth.uid()
         or exists (select 1 from taste_group_members m
                     where m.group_id = p.group_id
                       and m.user_id = auth.uid()
                       and m.role = 'owner'));
$$;

-- Browse + my-groups in one call. Blocked creators' groups are hidden the
-- same way blocked people vanish everywhere else.
create or replace function wanderbites.taste_groups_list()
returns table (
  id uuid,
  name text,
  description text,
  emoji text,
  creator_id uuid,
  creator_username text,
  member_count integer,
  pick_count integer,
  is_member boolean,
  my_role text,
  created_at timestamptz
)
language sql stable security definer
set search_path = wanderbites as $$
  select g.id,
         g.name,
         g.description,
         g.emoji,
         g.creator_id,
         p.username,
         (select count(*)::int from taste_group_members m where m.group_id = g.id),
         (select count(*)::int from taste_group_picks k where k.group_id = g.id),
         mm.user_id is not null,
         mm.role,
         g.created_at
  from taste_groups g
  join profiles p on p.id = g.creator_id
  left join taste_group_members mm
    on mm.group_id = g.id and mm.user_id = auth.uid()
  where g.deleted_at is null
    and p.deleted_at is null
    and (auth.uid() is null or not is_blocked_between(auth.uid(), g.creator_id))
  order by (mm.user_id is not null) desc, g.created_at desc;
$$;

revoke all on function wanderbites.create_taste_group(text, text, text) from public, anon;
revoke all on function wanderbites.join_taste_group(uuid) from public, anon;
revoke all on function wanderbites.leave_taste_group(uuid) from public, anon;
revoke all on function wanderbites.add_group_pick(uuid, uuid, text) from public, anon;
revoke all on function wanderbites.remove_group_pick(uuid) from public, anon;
revoke all on function wanderbites.taste_groups_list() from public, anon;

grant execute on function wanderbites.create_taste_group(text, text, text) to authenticated;
grant execute on function wanderbites.join_taste_group(uuid) to authenticated;
grant execute on function wanderbites.leave_taste_group(uuid) to authenticated;
grant execute on function wanderbites.add_group_pick(uuid, uuid, text) to authenticated;
grant execute on function wanderbites.remove_group_pick(uuid) to authenticated;
grant execute on function wanderbites.taste_groups_list() to authenticated;
