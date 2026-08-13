-- When a user loses premium, revert stored premium cosmetics (premium banner
-- style, custom header photo). Privileges already revert live via
-- entitlements_for(); this covers the persisted display state.

create or replace function wanderbites.strip_premium_cosmetics(uid uuid)
returns void
language plpgsql
security definer
set search_path to 'wanderbites'
as $$
begin
  -- Demo profiles keep their showcase looks; entitled users keep theirs.
  if exists (select 1 from profiles p where p.id = uid and coalesce(p.is_demo, false)) then
    return;
  end if;
  if 'premium_profile_layouts' = any (entitlements_for(uid)) then
    return;
  end if;

  update profiles
  set banner_style = case when banner_style_is_premium(banner_style)
                          then 'classic:voyage' else banner_style end,
      header_url = null,
      header_focus_y = 0.5
  where id = uid
    and (banner_style_is_premium(banner_style) or header_url is not null);
end $$;

-- Fires on webhook writes: any subscription row landing in a non-live state.
create or replace function wanderbites.tg_subscription_downgrade_revert()
returns trigger
language plpgsql
security definer
set search_path to 'wanderbites'
as $$
begin
  begin
    if not subscription_is_live(new.status, new.expires_at) then
      perform strip_premium_cosmetics(new.user_id);
    end if;
  exception when others then
    null; -- never block the webhook write
  end;
  return new;
end $$;

drop trigger if exists subscription_downgrade_revert on wanderbites.subscriptions;
create trigger subscription_downgrade_revert
after insert or update of status, expires_at on wanderbites.subscriptions
for each row execute function wanderbites.tg_subscription_downgrade_revert();

-- Fires when an admin comp is revoked, expired, or deleted.
create or replace function wanderbites.tg_override_downgrade_revert()
returns trigger
language plpgsql
security definer
set search_path to 'wanderbites'
as $$
declare
  affected uuid;
begin
  begin
    affected := coalesce(new.user_id, old.user_id);
    if tg_op = 'DELETE'
       or new.revoked_at is not null
       or (new.expires_at is not null and new.expires_at <= now()) then
      perform strip_premium_cosmetics(affected);
    end if;
  exception when others then
    null;
  end;
  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end $$;

drop trigger if exists override_downgrade_revert on wanderbites.entitlement_overrides;
create trigger override_downgrade_revert
after insert or update or delete on wanderbites.entitlement_overrides
for each row execute function wanderbites.tg_override_downgrade_revert();

-- One-time cleanup: strip anyone currently unentitled but still wearing
-- premium cosmetics.
do $$
declare
  r record;
begin
  for r in
    select id from wanderbites.profiles
    where deleted_at is null
      and not coalesce(is_demo, false)
      and (wanderbites.banner_style_is_premium(banner_style) or header_url is not null)
      and not ('premium_profile_layouts' = any (wanderbites.entitlements_for(id)))
  loop
    perform wanderbites.strip_premium_cosmetics(r.id);
  end loop;
end $$;
