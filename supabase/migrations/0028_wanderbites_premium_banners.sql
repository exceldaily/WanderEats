-- Premium profile layouts (Premium M6).
--
-- The premium banner designs and colors are ordinary banner_style tokens; the
-- only difference is that setting one requires the premium_profile_layouts
-- entitlement, enforced in the same guard trigger that protects moderation
-- flags. Enforcement is at set-time only: if a subscription lapses, an
-- already-chosen premium banner stays - taking a profile's look away over a
-- lapsed card would read as punishment.
--
-- Rollback: recreate tg_profiles_guard from 0002 and drop
-- banner_style_is_premium.

create or replace function wanderbites.banner_style_is_premium(style text)
returns boolean language sql immutable as $$
  select split_part(style, ':', 1) = any (array['wander', 'feast'])
      or split_part(style, ':', 2) = any (array['aurora', 'rosegold', 'obsidian', 'lagoon']);
$$;

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
  return new;
end $$;
