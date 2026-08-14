-- Server-driven update prompt.
--
-- The app compares its own build number against latest_build on launch and
-- offers an update when it is behind. Living in app_settings means shipping a
-- build and *announcing* it are separate acts: bump the row when the store
-- has finished processing, not when the binary is uploaded.
--
-- min_supported_build is the hard floor. Above it the prompt is dismissible;
-- at or below it the app blocks, which is only for a build that is genuinely
-- broken against the current backend. It stays 0 until that day comes.
insert into wanderbites.app_settings (key, value) values
  ('latest_build', '17'::jsonb),
  ('min_supported_build', '0'::jsonb),
  ('update_message', 'null'::jsonb)
on conflict (key) do update set value = excluded.value;
