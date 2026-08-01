-- Premium entitlements, derived from store-verified subscriptions.
--
-- The brief requires that premium access be "verified through the backend or
-- trusted billing provider" and that no safety or access rule rely on the
-- client. That rules out the usual shortcut of storing an is_premium boolean
-- the app can set, so the shape here is:
--
--   store (Apple / Google)  ->  RevenueCat  ->  webhook edge function
--        -> wanderbites.subscriptions (service role writes ONLY)
--        -> has_entitlement() derives access at query time
--
-- Entitlements are computed rather than stored. A stored copy drifts the first
-- time a refund, a grace period or a product remap happens, and drift in an
-- access-control table is the kind of bug that quietly grants a paid feature to
-- someone who cancelled six months ago.
--
-- RevenueCat is the provider because it validates receipts for both stores and
-- exposes one webhook, which is a great deal less to get wrong than two
-- separate server-side receipt validators. Nothing below is specific to it
-- except the provider string; a different provider writes the same rows.

-- ---------------------------------------------------------------------------
-- 1. Which products grant which entitlements
--
-- Kept as data rather than hardcoded in a function so that adding a plan, or
-- changing what a plan includes, is an insert rather than a migration.
-- ---------------------------------------------------------------------------

create table if not exists wanderbites.subscription_products (
  product_id    text primary key,
  display_name  text not null,
  entitlements  text[] not null default '{}',
  is_active     boolean not null default true,
  sort_order    int not null default 0,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

alter table wanderbites.subscription_products enable row level security;

-- The catalogue is public: the app has to be able to show what is on offer to
-- someone who has not bought anything.
drop policy if exists sub_products_read on wanderbites.subscription_products;
create policy sub_products_read on wanderbites.subscription_products
  for select using (is_active);

drop policy if exists sub_products_admin on wanderbites.subscription_products;
create policy sub_products_admin on wanderbites.subscription_products
  for all using (wanderbites.is_admin()) with check (wanderbites.is_admin());

insert into wanderbites.subscription_products
  (product_id, display_name, entitlements, sort_order)
values
  ('wanderbites_premium_monthly', 'WanderBites Premium (monthly)',
   array['direct_messaging','create_taste_groups','premium_profile_layouts','advanced_trip_planning'], 1),
  ('wanderbites_premium_annual', 'WanderBites Premium (annual)',
   array['direct_messaging','create_taste_groups','premium_profile_layouts','advanced_trip_planning'], 2)
on conflict (product_id) do nothing;

-- ---------------------------------------------------------------------------
-- 2. Store-verified subscription state
--
-- Written only by the webhook running as service role. There is deliberately
-- no INSERT or UPDATE policy for authenticated users: a client being able to
-- write this table would make every premium check meaningless.
-- ---------------------------------------------------------------------------

create table if not exists wanderbites.subscriptions (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid not null references wanderbites.profiles(id) on delete cascade,
  provider         text not null default 'revenuecat',
  provider_user_id text,
  product_id       text not null,
  store            text,
  status           text not null,
  period_type      text,
  environment      text not null default 'production',
  purchased_at     timestamptz,
  expires_at       timestamptz,
  auto_renew       boolean not null default false,
  raw              jsonb not null default '{}'::jsonb,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  constraint subscriptions_status_check check (status in (
    'active','in_grace_period','in_retry','paused','expired','cancelled','refunded'
  )),
  constraint subscriptions_environment_check check (environment in ('production','sandbox'))
);

-- One live row per user per product; the webhook upserts onto this.
create unique index if not exists subscriptions_user_product_idx
  on wanderbites.subscriptions (user_id, product_id, provider);
create index if not exists subscriptions_active_idx
  on wanderbites.subscriptions (user_id, status, expires_at desc);

alter table wanderbites.subscriptions enable row level security;

-- A user may see their own subscription, so the app can show renewal dates and
-- explain why access ended. Nobody may write.
drop policy if exists subscriptions_read_own on wanderbites.subscriptions;
create policy subscriptions_read_own on wanderbites.subscriptions
  for select using (user_id = auth.uid() or wanderbites.is_admin());

-- ---------------------------------------------------------------------------
-- 3. Manual grants
--
-- Comped accounts, testers, support gestures, and the team's own devices.
-- Separate from subscriptions so a real refund can never silently revoke a
-- deliberate grant, and so admin action is auditable on its own timeline.
-- ---------------------------------------------------------------------------

create table if not exists wanderbites.entitlement_overrides (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references wanderbites.profiles(id) on delete cascade,
  entitlement  text not null,
  granted_by   uuid references wanderbites.profiles(id) on delete set null,
  reason       text,
  granted_at   timestamptz not null default now(),
  expires_at   timestamptz,
  revoked_at   timestamptz
);

create index if not exists entitlement_overrides_user_idx
  on wanderbites.entitlement_overrides (user_id) where revoked_at is null;

alter table wanderbites.entitlement_overrides enable row level security;

drop policy if exists overrides_read_own on wanderbites.entitlement_overrides;
create policy overrides_read_own on wanderbites.entitlement_overrides
  for select using (user_id = auth.uid() or wanderbites.is_admin());

drop policy if exists overrides_admin_write on wanderbites.entitlement_overrides;
create policy overrides_admin_write on wanderbites.entitlement_overrides
  for all using (wanderbites.is_admin()) with check (wanderbites.is_admin());

-- ---------------------------------------------------------------------------
-- 4. Derivation
--
-- The single place that decides whether someone has a paid feature. Everything
-- else in the app calls this rather than reasoning about subscription rows.
-- ---------------------------------------------------------------------------

-- Grace and retry both still count as paid: the store is retrying a renewal
-- and yanking access mid-retry is a bad experience for someone whose card
-- expired. Refunds and expiry do not count.
create or replace function wanderbites.subscription_is_live(
  p_status text, p_expires_at timestamptz
) returns boolean
language sql immutable as $$
  select p_status in ('active','in_grace_period','in_retry')
     and (p_expires_at is null or p_expires_at > now());
$$;

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
  ) t;
$$;

-- What the app calls on launch and after a purchase.
create or replace function wanderbites.my_entitlements()
returns text[]
language sql stable security definer set search_path = wanderbites as $$
  select case
    when auth.uid() is null then '{}'::text[]
    else entitlements_for(auth.uid())
  end;
$$;

-- What every server-side gate calls. Takes no user argument on purpose: a
-- caller must never be able to ask "does *that* user have premium".
create or replace function wanderbites.has_entitlement(code text)
returns boolean
language sql stable security definer set search_path = wanderbites as $$
  select auth.uid() is not null and code = any(entitlements_for(auth.uid()));
$$;

revoke all on function wanderbites.my_entitlements() from public;
revoke all on function wanderbites.has_entitlement(text) from public;
grant execute on function wanderbites.my_entitlements() to authenticated;
grant execute on function wanderbites.has_entitlement(text) to authenticated;

-- entitlements_for takes a uid and so must not be reachable by clients, or a
-- user could enumerate other people's paid status.
revoke all on function wanderbites.entitlements_for(uuid) from public;
revoke all on function wanderbites.entitlements_for(uuid) from authenticated;

-- ---------------------------------------------------------------------------
-- 5. Webhook upsert
--
-- Called by the edge function as service role. Kept as a function rather than
-- letting the function write tables directly so the mapping from provider
-- payload to row shape lives with the schema and can be tested in SQL.
-- ---------------------------------------------------------------------------

create or replace function wanderbites.record_subscription_event(
  p_user_id uuid,
  p_product_id text,
  p_status text,
  p_expires_at timestamptz,
  p_store text default null,
  p_period_type text default null,
  p_environment text default 'production',
  p_auto_renew boolean default false,
  p_provider_user_id text default null,
  p_purchased_at timestamptz default null,
  p_raw jsonb default '{}'::jsonb
) returns uuid
language plpgsql volatile security definer set search_path = wanderbites as $$
declare
  sub_id uuid;
begin
  insert into subscriptions (
    user_id, provider, provider_user_id, product_id, store, status,
    period_type, environment, purchased_at, expires_at, auto_renew, raw
  ) values (
    p_user_id, 'revenuecat', p_provider_user_id, p_product_id, p_store, p_status,
    p_period_type, coalesce(p_environment,'production'), p_purchased_at,
    p_expires_at, coalesce(p_auto_renew,false), coalesce(p_raw,'{}'::jsonb)
  )
  on conflict (user_id, product_id, provider) do update set
    status        = excluded.status,
    store         = coalesce(excluded.store, subscriptions.store),
    period_type   = coalesce(excluded.period_type, subscriptions.period_type),
    environment   = excluded.environment,
    expires_at    = excluded.expires_at,
    auto_renew    = excluded.auto_renew,
    purchased_at  = coalesce(subscriptions.purchased_at, excluded.purchased_at),
    provider_user_id = coalesce(excluded.provider_user_id, subscriptions.provider_user_id),
    raw           = excluded.raw,
    updated_at    = now()
  returning id into sub_id;

  return sub_id;
end;
$$;

revoke all on function wanderbites.record_subscription_event(
  uuid, text, text, timestamptz, text, text, text, boolean, text, timestamptz, jsonb
) from public;
revoke all on function wanderbites.record_subscription_event(
  uuid, text, text, timestamptz, text, text, text, boolean, text, timestamptz, jsonb
) from authenticated;
