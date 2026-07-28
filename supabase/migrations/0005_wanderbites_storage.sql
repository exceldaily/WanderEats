-- WanderBites 0005: media bucket + ownership-scoped policies.
-- Bucket is public-read (food photos, avatars, covers are public content).
-- Uploads must live under the uploader's uid prefix: <uid>/...
-- Policy names are wanderbites-prefixed: storage.objects is shared with
-- sibling apps in this project.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'wanderbites-media', 'wanderbites-media', true,
  5242880, -- 5 MB, client compresses before upload
  array['image/jpeg','image/png','image/webp']
)
on conflict (id) do nothing;

create policy "wanderbites_media_public_read"
  on storage.objects for select
  using (bucket_id = 'wanderbites-media');

create policy "wanderbites_media_owner_insert"
  on storage.objects for insert
  with check (
    bucket_id = 'wanderbites-media'
    and auth.uid() is not null
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "wanderbites_media_owner_update"
  on storage.objects for update
  using (
    bucket_id = 'wanderbites-media'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "wanderbites_media_owner_delete"
  on storage.objects for delete
  using (
    bucket_id = 'wanderbites-media'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
