-- Restaurant cover photos improve over time.
--
-- Provider photos are a cold start: Google's first photo is frequently a
-- vertical user snap of a menu or a car park. As soon as a Taster posts a real
-- photo with a recommendation, that becomes the cover — a human food photo
-- beats a scraped one every time.

alter table wanderbites.restaurants
  add column if not exists cover_source text not null default 'provider'
  check (cover_source in ('provider','community','seed'));

update wanderbites.restaurants
set cover_source = 'seed'
where is_seed and cover_source = 'provider';

-- Promote the first photo of a new recommendation to the restaurant cover,
-- unless a human photo is already there.
create or replace function wanderbites.tg_promote_rec_photo()
returns trigger language plpgsql security definer
set search_path = wanderbites as $$
declare
  rid uuid;
begin
  select r.restaurant_id into rid
  from recommendations r where r.id = new.recommendation_id;
  if rid is null then return new; end if;

  update restaurants
  set cover_photo_url = new.storage_path,
      cover_source = 'community',
      updated_at = now()
  where id = rid
    and cover_source <> 'community';

  insert into restaurant_photos (restaurant_id, storage_path, source)
  select rid, new.storage_path, 'user'
  where not exists (
    select 1 from restaurant_photos p
    where p.restaurant_id = rid and p.storage_path = new.storage_path);

  return new;
end;
$$;

drop trigger if exists promote_rec_photo on wanderbites.recommendation_photos;
create trigger promote_rec_photo
  after insert on wanderbites.recommendation_photos
  for each row execute function wanderbites.tg_promote_rec_photo();
