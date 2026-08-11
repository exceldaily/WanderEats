-- 0033: the house account automatically follows every new real profile.
--
-- Server-side only: an AFTER INSERT trigger on profiles, so it works no
-- matter which client created the account and never depends on the admin's
-- device. The admin id lives in app_config (RLS enabled, zero policies, so
-- clients can neither read nor change it); update that row to point the
-- auto-follow at a different account later.
--
-- Safety properties:
--   * idempotent / race-safe: follows has PK (follower_id, followee_id) and
--     the insert is ON CONFLICT DO NOTHING
--   * no self-follow: guarded here and by the table CHECK constraint
--   * no loops: profiles -> follows -> notifications, nothing writes back
--   * never blocks signup: the whole body is wrapped in an exception guard
--   * no fake counts: rows land in the ordinary follows table
--   * seed/demo inserts are skipped via is_demo

create table if not exists wanderbites.app_config (
  key text primary key,
  value text not null,
  updated_at timestamptz not null default now()
);

alter table wanderbites.app_config enable row level security;

insert into wanderbites.app_config (key, value)
values ('auto_follow_user_id', '00000000-0000-4000-a000-000000000002')
on conflict (key) do update set value = excluded.value, updated_at = now();

create or replace function wanderbites.tg_auto_follow_new_profile()
returns trigger
language plpgsql
security definer
set search_path to 'wanderbites'
as $$
declare
  admin_id uuid;
begin
  begin
    select nullif(value, '')::uuid into admin_id
    from app_config
    where key = 'auto_follow_user_id';

    if admin_id is null
        or admin_id = new.id
        or coalesce(new.is_demo, false) then
      return new;
    end if;

    -- A stale config value must not surface an FK error into signup.
    if not exists (select 1 from profiles where id = admin_id) then
      return new;
    end if;

    insert into follows (follower_id, followee_id)
    values (admin_id, new.id)
    on conflict (follower_id, followee_id) do nothing;
  exception when others then
    -- Auto-follow is best-effort; account creation always wins.
    null;
  end;
  return new;
end $$;

drop trigger if exists auto_follow_new_profile on wanderbites.profiles;
create trigger auto_follow_new_profile
  after insert on wanderbites.profiles
  for each row execute function wanderbites.tg_auto_follow_new_profile();
