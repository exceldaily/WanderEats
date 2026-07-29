-- Taste identity on profiles: free-form tag pills and a small structured
-- personality object. Deliberately minimal — no join tables for what is
-- purely presentational, owner-edited metadata.
alter table wanderbites.profiles
  add column if not exists taste_tags text[] not null default '{}',
  add column if not exists taste_personality jsonb not null default '{}'::jsonb;

-- Keep them sane: at most 8 short tags, personality stays a flat object.
alter table wanderbites.profiles
  drop constraint if exists profiles_taste_tags_sane,
  add constraint profiles_taste_tags_sane
    check (array_length(taste_tags, 1) is null or
           (array_length(taste_tags, 1) <= 8));
