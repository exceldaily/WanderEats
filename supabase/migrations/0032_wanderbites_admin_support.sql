-- Admin support tooling (in-app admin panel).
--
-- Most admin powers already exist: profiles_update_own carries is_admin(),
-- entitlement_overrides has overrides_admin_write, content_reports has
-- admin read/update policies, and the DOB guard defers to admins. This adds
-- the two missing pieces: a user search that can see auth emails (support
-- needs "which account is this person"), and the ability for an admin to
-- INSERT a date of birth for a user who never set one.
--
-- Rollback: drop function admin_user_search; drop policy
-- private_insert_admin on profile_private.

-- Support search across username / display name / email. SECURITY DEFINER is
-- what grants the auth.users read; the is_admin() gate is therefore the
-- entire protection and comes first.
create or replace function wanderbites.admin_user_search(p_query text)
returns table (
  id uuid,
  username text,
  display_name text,
  email text,
  is_suspended boolean,
  is_demo boolean,
  age_confirmed boolean,
  is_adult boolean,
  entitlements text[],
  created_at timestamptz
)
language plpgsql stable security definer
set search_path = wanderbites as $$
begin
  if not is_admin() then
    raise exception 'admin_only';
  end if;
  return query
  select p.id,
         p.username,
         p.display_name,
         u.email::text,
         p.is_suspended,
         p.is_demo,
         pp.user_id is not null,
         is_adult(p.id),
         entitlements_for(p.id),
         p.created_at
  from profiles p
  join auth.users u on u.id = p.id
  left join profile_private pp on pp.user_id = p.id
  where p.deleted_at is null
    and (
      p.username ilike '%' || p_query || '%'
      or p.display_name ilike '%' || p_query || '%'
      or u.email ilike '%' || p_query || '%'
    )
  order by p.created_at desc
  limit 25;
end $$;

revoke all on function wanderbites.admin_user_search(text) from public, anon;
grant execute on function wanderbites.admin_user_search(text) to authenticated;

-- Admins may create a DOB row for support corrections; the guard trigger
-- still validates the date itself.
create policy private_insert_admin on wanderbites.profile_private
  for insert with check (wanderbites.is_admin());
