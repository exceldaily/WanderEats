-- Custom profile banner photos join premium_profile_layouts (M6 follow-up).
--
-- Setting or changing header_url now requires the entitlement, same guard
-- trigger as premium banner styles. Deliberately asymmetric: clearing the
-- banner (null) is always allowed, and an already-set banner survives a
-- lapsed subscription - set-time enforcement only, like the styles.
--
-- Rollback: recreate tg_profiles_guard from 0028.

create or replace function wanderbites.tg_profiles_guard()
returns trigger language plpgsql security definer set search_path = wanderbites as $$
begin
  if (new.is_admin is distinct from old.is_admin
      or new.is_verified is distinct from old.is_verified
      or new.is_suspended is distinct from old.is_suspended)
     and not is_admin() then
    raise exception 'not allowed to change moderation flags';
  end if;
  if new.banner_style is distinct from old.banner_style
     and banner_style_is_premium(new.banner_style)
     and not is_admin()
     and not has_entitlement('premium_profile_layouts') then
    raise exception 'premium_denied:premium_required';
  end if;
  if new.header_url is distinct from old.header_url
     and new.header_url is not null
     and not is_admin()
     and not has_entitlement('premium_profile_layouts') then
    raise exception 'premium_denied:premium_required';
  end if;
  return new;
end $$;
