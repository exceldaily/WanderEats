-- 0036: point lookup for the profile screen: is interaction between me and
-- the target blocked in either direction. Replaces downloading the whole
-- block list client-side, and actually answers the both-directions question
-- the client documents.
create or replace function wanderbites.is_blocked(target uuid)
returns boolean
language sql
stable
security definer
set search_path to 'wanderbites'
as $$
  select case
    when auth.uid() is null then false
    else is_blocked_between(auth.uid(), target)
  end;
$$;

revoke all on function wanderbites.is_blocked(uuid) from public;
grant execute on function wanderbites.is_blocked(uuid) to authenticated;
