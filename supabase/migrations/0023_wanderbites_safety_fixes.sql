-- Two defects in 0022, both found by running it against real data rather than
-- by reading it. Kept as a separate migration because 0022 was already applied.
--
-- 1. content_reports carried a CHECK allowing only five legacy reasons
--    (spam, inappropriate, incorrect_info, harassment, other). report_content
--    validated against the fourteen-reason safety vocabulary and then failed at
--    insert time, so every safety-specific report would have been rejected.
--    The legacy values are kept rather than migrated away: restaurant_repository
--    already writes 'incorrect_info' and existing rows use them, so removing
--    them would break a working path and rewrite history for nothing.
--
-- 2. target_owner did not understand 'profile', so reporting an account left
--    reported_user_id null. That is the column moderation triage depends on,
--    since it is how repeat offenders get spotted.

alter table wanderbites.content_reports
  drop constraint if exists content_reports_reason_check;
alter table wanderbites.content_reports
  add constraint content_reports_reason_check
  check (reason in (
    -- safety vocabulary
    'spam','harassment','hate_or_abuse','threatening_behavior','impersonation',
    'scam_or_fraud','sexual_content','underage_safety_concern','dangerous_content',
    'false_information','privacy_violation','copyright','inappropriate_content','other',
    -- legacy values still written by existing code and present in existing rows
    'inappropriate','incorrect_info'
  ));

create or replace function wanderbites.target_owner(ttype text, tid uuid)
returns uuid
language sql stable security definer set search_path = wanderbites as $$
  select case ttype
    when 'list' then (select owner_id from lists where id = tid)
    when 'recommendation' then (select user_id from recommendations where id = tid)
    when 'comment' then (select user_id from comments where id = tid)
    -- A reported profile is its own owner. Without this, reporting an account
    -- produced a report with no subject.
    when 'profile' then (select id from profiles where id = tid and deleted_at is null)
    -- Restaurants are places, not people: deliberately no owner.
    else null
  end;
$$;
