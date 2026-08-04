-- Age eligibility (18+) for age-restricted premium features.
--
-- Date of birth is identity data, not a preference, and profiles is publicly
-- readable - so it lives in its own owner-only table instead of growing the
-- public row. It is also write-once for the owner: letting people edit their
-- own birth date would let a minor "become" an adult with a single update, so
-- corrections go through an admin.
--
-- The gate composes with billing INSIDE entitlements_for: an entitlement
-- listed in adults_only_entitlements() is never returned for a non-adult,
-- regardless of what they paid. Every existing has_entitlement() call site -
-- and every future one, like M4 messaging - inherits the age rule without
-- remembering to check it.
--
-- Rollback: recreate entitlements_for from 0024, then drop my_age_status,
-- is_adult, adults_only_entitlements, adult_age_years, min_age_years,
-- tg_profile_private_guard and table profile_private, and delete the three
-- app_settings rows.

create table wanderbites.profile_private (
  user_id uuid primary key references wanderbites.profiles(id) on delete cascade,
  date_of_birth date not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table wanderbites.profile_private is
  'Owner-only identity data (date of birth). Never expose through public views or joins.';

alter table wanderbites.profile_private enable row level security;

create policy private_read_own on wanderbites.profile_private
  for select using (user_id = auth.uid() or wanderbites.is_admin());

create policy private_insert_own on wanderbites.profile_private
  for insert with check (user_id = auth.uid());

create policy private_update_own on wanderbites.profile_private
  for update using (user_id = auth.uid() or wanderbites.is_admin());

-- No delete policy on purpose: the row follows the profile via cascade.

grant select, insert, update on wanderbites.profile_private to authenticated;

-- Thresholds live in app_settings so they can be tuned without a release.
insert into wanderbites.app_settings (key, value) values
  ('age_minimum_years', '13'::jsonb),
  ('age_adult_years', '18'::jsonb),
  ('adults_only_entitlements', '["direct_messaging"]'::jsonb)
on conflict (key) do nothing;

create or replace function wanderbites.min_age_years()
returns integer language sql stable set search_path = wanderbites as $$
  select coalesce(
    (select (value #>> '{}')::int from wanderbites.app_settings
      where key = 'age_minimum_years'),
    13);
$$;

create or replace function wanderbites.adult_age_years()
returns integer language sql stable set search_path = wanderbites as $$
  select coalesce(
    (select (value #>> '{}')::int from wanderbites.app_settings
      where key = 'age_adult_years'),
    18);
$$;

-- Sanity + write-once guard. Mirrors tg_profiles_guard: the client is free to
-- insert, but the interesting transitions are locked down here rather than in
-- app code the user does not have to run.
create or replace function wanderbites.tg_profile_private_guard()
returns trigger language plpgsql security definer set search_path = wanderbites as $$
begin
  if new.date_of_birth > current_date then
    raise exception 'date of birth cannot be in the future';
  end if;
  if new.date_of_birth < date '1900-01-01' then
    raise exception 'date of birth is implausible';
  end if;
  if new.date_of_birth > current_date - make_interval(years => min_age_years()) then
    raise exception 'WanderBites requires users to be at least % years old', min_age_years();
  end if;
  if tg_op = 'UPDATE'
     and new.date_of_birth is distinct from old.date_of_birth
     and not is_admin() then
    raise exception 'date of birth can only be corrected by support';
  end if;
  new.updated_at := now();
  return new;
end $$;

create trigger profile_private_guard
  before insert or update on wanderbites.profile_private
  for each row execute function wanderbites.tg_profile_private_guard();

-- Internal predicate. Like entitlements_for, never callable by clients: an app
-- must not be able to ask whether *another* user is an adult.
create or replace function wanderbites.is_adult(p uuid)
returns boolean language sql stable security definer set search_path = wanderbites as $$
  select p is not null and exists (
    select 1 from profile_private pp
    where pp.user_id = p
      and pp.date_of_birth <= current_date - make_interval(years => adult_age_years())
  );
$$;

-- What the app calls to decide which gate copy to show. 'confirmed' and
-- 'adult' are separate on purpose: an unconfirmed user gets a "confirm your
-- age" prompt, a confirmed minor gets a refusal that must never mention
-- buying anything.
create or replace function wanderbites.my_age_status()
returns jsonb language sql stable security definer set search_path = wanderbites as $$
  select case
    when auth.uid() is null then
      jsonb_build_object('confirmed', false, 'adult', false)
    else
      jsonb_build_object(
        'confirmed', exists (select 1 from profile_private where user_id = auth.uid()),
        'adult', is_adult(auth.uid())
      )
  end;
$$;

create or replace function wanderbites.adults_only_entitlements()
returns text[] language sql stable set search_path = wanderbites as $$
  select coalesce(
    (select array(select jsonb_array_elements_text(value))
       from wanderbites.app_settings
      where key = 'adults_only_entitlements'),
    array['direct_messaging']);
$$;

-- Same body as 0024 plus the age filter. A non-adult (including anyone who
-- never confirmed a date of birth) simply never receives an adults-only code,
-- so has_entitlement('direct_messaging') fails closed for them everywhere.
create or replace function wanderbites.entitlements_for(uid uuid)
returns text[]
language sql stable security definer set search_path = wanderbites as $$
  select coalesce(array_agg(distinct e), '{}')
  from (
    select unnest(p.entitlements) as e
    from subscriptions s
    join subscription_products p on p.product_id = s.product_id
    where s.user_id = uid
      and p.is_active
      and subscription_is_live(s.status, s.expires_at)
    union
    select o.entitlement
    from entitlement_overrides o
    where o.user_id = uid
      and o.revoked_at is null
      and (o.expires_at is null or o.expires_at > now())
  ) t
  where t.e <> all (adults_only_entitlements()) or is_adult(uid);
$$;

revoke all on function wanderbites.is_adult(uuid) from public, authenticated, anon;
revoke all on function wanderbites.tg_profile_private_guard() from public, authenticated, anon;
grant execute on function wanderbites.my_age_status() to authenticated;
