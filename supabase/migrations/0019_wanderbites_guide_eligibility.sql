-- Guide authoring eligibility.
--
-- Rule: a Taster may create guides once 50 of their recommendations are
-- published, or when an admin approves them early.
--
-- "Published" means not soft-deleted. Visibility is deliberately not part of
-- the count - a private recommendation is still work the Taster did, and
-- counting only public ones would push people to make everything public just
-- to qualify.
--
-- Rollback: drop the three functions and the view, then drop the two columns.
-- Nothing existing is altered.

alter table wanderbites.profiles
  add column if not exists guides_approved_at timestamptz,
  add column if not exists guides_approved_by uuid references wanderbites.profiles(id) on delete set null;

comment on column wanderbites.profiles.guides_approved_at is
  'Admin early-approval for guide authoring, bypassing the recommendation threshold.';

-- Threshold lives in app_settings so it can be tuned without a release.
insert into wanderbites.app_settings (key, value)
values ('guide_eligibility_min_recommendations', '50'::jsonb)
on conflict (key) do nothing;

create or replace function wanderbites.guide_threshold()
returns integer language sql stable set search_path = wanderbites as $$
  select coalesce(
    (select (value #>> '{}')::int from wanderbites.app_settings
      where key = 'guide_eligibility_min_recommendations'),
    50);
$$;

create or replace function wanderbites.published_recommendation_count(p uuid)
returns integer language sql stable set search_path = wanderbites as $$
  select count(*)::int from wanderbites.recommendations r
  where r.user_id = p and r.deleted_at is null;
$$;

-- Admin approval short-circuits the threshold.
create or replace function wanderbites.can_create_guides(p uuid default auth.uid())
returns boolean language sql stable set search_path = wanderbites as $$
  select p is not null and (
    exists (select 1 from wanderbites.profiles pr
             where pr.id = p and pr.guides_approved_at is not null)
    or wanderbites.published_recommendation_count(p) >= wanderbites.guide_threshold()
  );
$$;

-- Review queue: who is close, who qualifies, who was approved early.
create or replace view wanderbites.guide_eligibility as
select pr.id,
       pr.username,
       pr.display_name,
       wanderbites.published_recommendation_count(pr.id) as published_recommendations,
       wanderbites.guide_threshold() as threshold,
       pr.guides_approved_at is not null as approved_early,
       wanderbites.can_create_guides(pr.id) as eligible
from wanderbites.profiles pr
where pr.deleted_at is null and pr.is_demo = false;
