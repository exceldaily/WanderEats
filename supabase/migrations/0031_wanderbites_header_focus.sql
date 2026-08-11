-- Banner photo vertical position (0 = show top of image, 1 = bottom,
-- 0.5 = center). Stored on the profile so the crop the owner chose is the
-- crop every viewer sees. Not premium-gated on its own: it only has an
-- effect when a custom banner photo (already premium) exists.
--
-- Rollback: drop the column.

alter table wanderbites.profiles
  add column if not exists header_focus_y double precision not null default 0.5
    check (header_focus_y >= 0 and header_focus_y <= 1);

comment on column wanderbites.profiles.header_focus_y is
  'Vertical alignment of the custom banner photo: 0 top, 0.5 center, 1 bottom.';
