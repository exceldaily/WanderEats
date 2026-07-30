-- Close bucket enumeration on wanderbites-media.
--
-- The bucket is public, so object URLs are served without consulting RLS. The
-- blanket SELECT policy on storage.objects therefore added nothing for normal
-- photo display, but it did let any client call the list API and enumerate
-- every file in the bucket - including photos attached to recommendations
-- whose visibility is "followers" or "private".
--
-- The app only ever calls getPublicUrl(); it never calls list() and never
-- createSignedUrl(), so removing the policy closes enumeration with no
-- behaviour change. Owners keep insert/update/delete on their own folder via
-- wanderbites_media_owner_{insert,update,delete}, which key on
-- (storage.foldername(name))[1] = auth.uid().
--
-- Flagged by the Supabase linter as public_bucket_allows_listing.

drop policy if exists wanderbites_media_public_read on storage.objects;
