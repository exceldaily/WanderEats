-- Advanced food-trip planning (Premium M7).
--
-- A food trip is a private, ordered itinerary of restaurants. Creating one is
-- the paid capability (advanced_trip_planning), enforced in create_food_trip;
-- everything inside an existing trip (stops, notes, reordering) works even if
-- the subscription later lapses - planning you already did stays yours.
--
-- Trips are owner-only, so stops are managed through ordinary RLS writes
-- instead of RPCs; only creation needs the server-side gate.
--
-- Rollback: drop function reorder_trip_stops, create_food_trip; drop tables
-- food_trip_stops, food_trips.

create table wanderbites.food_trips (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references wanderbites.profiles(id) on delete cascade,
  name text not null check (char_length(name) between 3 and 80),
  destination text check (char_length(destination) <= 120),
  starts_on date,
  notes text check (char_length(notes) <= 1000),
  created_at timestamptz not null default now(),
  deleted_at timestamptz
);

create index food_trips_owner_idx
  on wanderbites.food_trips (owner_id, created_at desc);

create table wanderbites.food_trip_stops (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references wanderbites.food_trips(id) on delete cascade,
  restaurant_id uuid not null references wanderbites.restaurants(id) on delete cascade,
  position integer not null default 0,
  note text check (char_length(note) <= 280),
  created_at timestamptz not null default now(),
  unique (trip_id, restaurant_id)
);

create index food_trip_stops_trip_idx
  on wanderbites.food_trip_stops (trip_id, position);

alter table wanderbites.food_trips enable row level security;
alter table wanderbites.food_trip_stops enable row level security;

create policy food_trips_own on wanderbites.food_trips
  for select using (owner_id = auth.uid());
create policy food_trips_update_own on wanderbites.food_trips
  for update using (owner_id = auth.uid());
-- No insert policy: creation goes through create_food_trip so the premium
-- gate cannot be skipped. No delete policy: deletion is a soft-delete update.

create policy trip_stops_own on wanderbites.food_trip_stops
  for select using (exists (
    select 1 from wanderbites.food_trips t
    where t.id = trip_id and t.owner_id = auth.uid()
  ));
create policy trip_stops_insert_own on wanderbites.food_trip_stops
  for insert with check (exists (
    select 1 from wanderbites.food_trips t
    where t.id = trip_id and t.owner_id = auth.uid() and t.deleted_at is null
  ));
create policy trip_stops_update_own on wanderbites.food_trip_stops
  for update using (exists (
    select 1 from wanderbites.food_trips t
    where t.id = trip_id and t.owner_id = auth.uid()
  ));
create policy trip_stops_delete_own on wanderbites.food_trip_stops
  for delete using (exists (
    select 1 from wanderbites.food_trips t
    where t.id = trip_id and t.owner_id = auth.uid()
  ));

grant select, update on wanderbites.food_trips to authenticated;
grant select, insert, update, delete on wanderbites.food_trip_stops to authenticated;

create or replace function wanderbites.create_food_trip(
  p_name text,
  p_destination text default null,
  p_starts_on date default null,
  p_notes text default null
)
returns uuid language plpgsql security definer
set search_path = wanderbites as $$
declare
  me uuid := auth.uid();
  trip uuid;
begin
  if me is null then raise exception 'trip_denied:not_signed_in'; end if;
  if exists (select 1 from profiles
              where id = me and (is_suspended or deleted_at is not null)) then
    raise exception 'trip_denied:account_restricted';
  end if;
  if not has_entitlement('advanced_trip_planning') then
    raise exception 'trip_denied:premium_required';
  end if;
  if (select count(*) from food_trips
       where owner_id = me and deleted_at is null) >= 20 then
    raise exception 'trip_denied:limit_reached';
  end if;

  insert into food_trips (owner_id, name, destination, starts_on, notes)
  values (
    me,
    btrim(p_name),
    nullif(btrim(coalesce(p_destination, '')), ''),
    p_starts_on,
    nullif(btrim(coalesce(p_notes, '')), '')
  )
  returning id into trip;
  return trip;
end $$;

-- Atomic reorder: the client sends the full stop-id order. Positions not in
-- the list keep their row but sink to the end; ids from other trips are
-- ignored rather than trusted.
create or replace function wanderbites.reorder_trip_stops(
  p_trip uuid,
  p_stop_ids uuid[]
)
returns void language plpgsql security definer
set search_path = wanderbites as $$
begin
  if not exists (select 1 from food_trips
                  where id = p_trip and owner_id = auth.uid()) then
    raise exception 'trip_denied:unavailable';
  end if;
  update food_trip_stops s
  set position = x.ord
  from (select unnest(p_stop_ids) as sid,
               generate_subscripts(p_stop_ids, 1) as ord) x
  where s.id = x.sid and s.trip_id = p_trip;
end $$;

revoke all on function wanderbites.create_food_trip(text, text, date, text) from public, anon;
revoke all on function wanderbites.reorder_trip_stops(uuid, uuid[]) from public, anon;
grant execute on function wanderbites.create_food_trip(text, text, date, text) to authenticated;
grant execute on function wanderbites.reorder_trip_stops(uuid, uuid[]) to authenticated;
