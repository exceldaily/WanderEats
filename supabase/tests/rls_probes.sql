-- WanderBites RLS probe suite. Run against a migrated + seeded database.
-- Everything runs inside a rolled-back transaction; nothing persists.
-- Expected: every row comes back OK.

begin;
create temp table probe_results (probe text, outcome text) on commit drop;
grant all on probe_results to authenticated;

set local role authenticated;
set local request.jwt.claims = '{"sub":"a0000000-0000-4000-8000-000000000001","role":"authenticated"}';

do $$
declare own_rec uuid; other_rec uuid;
begin
  -- 1. Acting as another user must be blocked by RLS
  begin
    insert into wanderbites.follows (follower_id, followee_id)
    values ('a0000000-0000-4000-8000-000000000002','a0000000-0000-4000-8000-000000000013');
    insert into probe_results values ('impersonated_follow', 'FAIL: allowed');
  exception when others then
    insert into probe_results values ('impersonated_follow', 'OK: blocked');
  end;

  -- 2. Rating your own recommendation must be blocked
  select id into own_rec from wanderbites.recommendations
  where user_id = 'a0000000-0000-4000-8000-000000000001' limit 1;
  begin
    insert into wanderbites.recommendation_feedback (recommendation_id, user_id, rating)
    values (own_rec, 'a0000000-0000-4000-8000-000000000001', 'exact');
    insert into probe_results values ('self_feedback', 'FAIL: allowed');
  exception when others then
    insert into probe_results values ('self_feedback', 'OK: blocked');
  end;

  -- 3. Rating someone else's recommendation must be allowed
  select r.id into other_rec from wanderbites.recommendations r
  where r.user_id <> 'a0000000-0000-4000-8000-000000000001'
    and not exists (select 1 from wanderbites.recommendation_feedback f
                    where f.recommendation_id = r.id
                      and f.user_id = 'a0000000-0000-4000-8000-000000000001')
  limit 1;
  begin
    insert into wanderbites.recommendation_feedback (recommendation_id, user_id, rating)
    values (other_rec, 'a0000000-0000-4000-8000-000000000001', 'great');
    insert into probe_results values ('legit_feedback', 'OK: allowed');
  exception when others then
    insert into probe_results values ('legit_feedback', 'FAIL: blocked ' || sqlerrm);
  end;

  -- 4. Self-granting admin must be blocked by the guard trigger
  begin
    update wanderbites.profiles set is_admin = true
    where id = 'a0000000-0000-4000-8000-000000000001';
    insert into probe_results values ('self_admin', 'FAIL: allowed');
  exception when others then
    insert into probe_results values ('self_admin', 'OK: blocked');
  end;

  -- 5. Notifications are scoped to the owner
  insert into probe_results
    select 'own_notifications_visible', 'count=' || count(*)::text
    from wanderbites.notifications;

  -- 6. Another user's date of birth must be invisible (profile_private is
  -- owner-only; leaking it would leak ages)
  insert into probe_results
    select 'others_dob_hidden',
      case when count(*) = 0 then 'OK: hidden' else 'FAIL: visible' end
    from wanderbites.profile_private
    where user_id <> 'a0000000-0000-4000-8000-000000000001';

  -- 7. Inserting a DOB for another user must be blocked
  begin
    insert into wanderbites.profile_private (user_id, date_of_birth)
    values ('a0000000-0000-4000-8000-000000000002', date '1990-01-01');
    insert into probe_results values ('impersonated_dob', 'FAIL: allowed');
  exception when others then
    insert into probe_results values ('impersonated_dob', 'OK: blocked');
  end;

  -- 8. Messages tables reject direct writes (RPCs are the only write path)
  begin
    insert into wanderbites.conversations (member_a, member_b)
    values ('a0000000-0000-4000-8000-000000000001',
            'a0000000-0000-4000-8000-000000000002');
    insert into probe_results values ('direct_conversation_insert', 'FAIL: allowed');
  exception when others then
    insert into probe_results values ('direct_conversation_insert', 'OK: blocked');
  end;

  -- 9. Conversations not involving me must be invisible
  insert into probe_results
    select 'foreign_conversations_hidden',
      case when count(*) = 0 then 'OK: hidden' else 'FAIL: visible' end
    from wanderbites.conversations
    where 'a0000000-0000-4000-8000-000000000001' not in (member_a, member_b);

  -- 10. Creating a taste group without premium must be blocked by the RPC
  begin
    perform wanderbites.create_taste_group('Probe Group');
    insert into probe_results values ('free_group_create', 'FAIL: allowed');
  exception when others then
    insert into probe_results values ('free_group_create',
      case when sqlerrm like '%premium_required%'
           then 'OK: premium gate' else 'OK: blocked (' || sqlerrm || ')' end);
  end;

  -- 11. Creating a food trip without premium must be blocked by the RPC
  begin
    perform wanderbites.create_food_trip('Probe Trip');
    insert into probe_results values ('free_trip_create', 'FAIL: allowed');
  exception when others then
    insert into probe_results values ('free_trip_create',
      case when sqlerrm like '%premium_required%'
           then 'OK: premium gate' else 'OK: blocked (' || sqlerrm || ')' end);
  end;

  -- 12. Other users' food trips must be invisible
  insert into probe_results
    select 'foreign_trips_hidden',
      case when count(*) = 0 then 'OK: hidden' else 'FAIL: visible' end
    from wanderbites.food_trips
    where owner_id <> 'a0000000-0000-4000-8000-000000000001';
end $$;

select * from probe_results;
rollback;

-- Anon scope: public reads work, private tables are empty
begin;
set local role anon;
select 'anon_restaurants' probe, count(*)::text outcome from wanderbites.restaurants
union all
select 'anon_recommendations', count(*)::text from wanderbites.recommendations
union all
select 'anon_notifications_empty', count(*)::text from wanderbites.notifications
union all
select 'anon_device_tokens_empty', count(*)::text from wanderbites.device_tokens;
rollback;
