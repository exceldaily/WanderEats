-- Provider photo resource names are request-scoped: Google returns a
-- different `places/X/photos/Y` string for the same underlying photo on every
-- call. Deduping by path therefore never matches, so appending grew the
-- gallery without bound. Provider photos are REPLACED wholesale, and a
-- refresh timestamp makes backfill batches idempotent.

alter table wanderbites.restaurants
  add column if not exists photos_refreshed_at timestamptz;

create or replace function wanderbites.set_provider_photos(
  p_restaurant_id uuid,
  p_best text,
  p_all text[] default '{}'
) returns void
language plpgsql security definer set search_path = wanderbites as $$
begin
  if p_best is not null and p_best <> '' then
    update restaurants
    set cover_photo_url = p_best, updated_at = now()
    where id = p_restaurant_id
      and cover_source = 'provider';   -- never clobber a community cover
  end if;

  -- Replace rather than append: these refs are not stable identities.
  delete from restaurant_photos
  where restaurant_id = p_restaurant_id and source = 'provider';

  insert into restaurant_photos (restaurant_id, storage_path, source)
  select p_restaurant_id, path, 'provider'
  from unnest(coalesce(p_all, '{}')) as path
  where path is not null and path <> '';

  update restaurants
  set photos_refreshed_at = now()
  where id = p_restaurant_id;
end;
$$;

revoke all on function wanderbites.set_provider_photos(uuid, text, text[])
  from public, anon, authenticated;
