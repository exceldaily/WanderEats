-- Seeded Tasters are fictional. Shipping them unlabelled would present
-- invented people as real recommenders, which is exactly the trust the
-- product is built on. They are marked rather than deleted so a brand new
-- install is not an empty map, and a single flag hides them once there is
-- real activity.
alter table wanderbites.profiles
  add column if not exists is_demo boolean not null default false;

update wanderbites.profiles
set is_demo = true
where id::text like 'a0000000%';

create index if not exists profiles_is_demo_idx
  on wanderbites.profiles(is_demo) where is_demo;

create table if not exists wanderbites.app_settings (
  key text primary key,
  value jsonb not null,
  updated_at timestamptz not null default now()
);

insert into wanderbites.app_settings (key, value)
values ('show_demo_content', 'true'::jsonb)
on conflict (key) do nothing;

alter table wanderbites.app_settings enable row level security;

drop policy if exists app_settings_read on wanderbites.app_settings;
create policy app_settings_read on wanderbites.app_settings
  for select to anon, authenticated using (true);

grant select on wanderbites.app_settings to anon, authenticated;

create or replace function wanderbites.demo_content_visible()
returns boolean language sql stable security definer
set search_path = wanderbites as $$
  select coalesce((select value::text::boolean from app_settings
                   where key = 'show_demo_content'), true);
$$;

grant execute on function wanderbites.demo_content_visible() to anon, authenticated;

-- Return type gains is_demo, so the old signature has to go first.
drop function if exists wanderbites.trending_tasters(int);

create function wanderbites.trending_tasters(max_rows int default 10)
returns table (
  id uuid, username text, display_name text, avatar_url text,
  is_verified boolean, is_demo boolean,
  followers bigint, reputation numeric
) language sql stable security definer
set search_path = wanderbites as $$
  select p.id, p.username, p.display_name, p.avatar_url,
         p.is_verified, p.is_demo,
         (select count(*) from follows f where f.followee_id = p.id) as followers,
         taster_reputation(p.id) as reputation
  from profiles p
  where p.deleted_at is null and not p.is_suspended and p.onboarding_completed
    and (not p.is_demo or demo_content_visible())
  order by reputation desc nulls last, followers desc
  limit greatest(max_rows, 1);
$$;

grant execute on function wanderbites.trending_tasters(int) to anon, authenticated;
