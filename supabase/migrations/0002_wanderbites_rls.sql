-- WanderBites 0002: Row-Level Security for every table. Deny by default.

-- ---------------------------------------------------------------------------
-- Helper functions (security definer to avoid policy recursion; owner
-- bypasses RLS inside, callers do not). All stable, search_path pinned.
-- ---------------------------------------------------------------------------

create or replace function wanderbites.is_admin()
returns boolean language sql stable security definer set search_path = wanderbites as $$
  select exists (
    select 1 from profiles
    where id = auth.uid() and is_admin and deleted_at is null
  );
$$;

create or replace function wanderbites.is_blocked_between(a uuid, b uuid)
returns boolean language sql stable security definer set search_path = wanderbites as $$
  select exists (
    select 1 from blocked_users
    where (blocker_id = a and blocked_id = b) or (blocker_id = b and blocked_id = a)
  );
$$;

-- Recommendation visibility for the current viewer.
create or replace function wanderbites.rec_visible(rec wanderbites.recommendations)
returns boolean language sql stable security definer set search_path = wanderbites as $$
  select rec.deleted_at is null
    and not is_blocked_between(auth.uid(), rec.user_id)
    and (
      rec.user_id = auth.uid()
      or rec.visibility = 'public'
      or (rec.visibility = 'followers' and exists (
            select 1 from follows
            where follower_id = auth.uid() and followee_id = rec.user_id))
      or is_admin()
    );
$$;

create or replace function wanderbites.list_visible(l wanderbites.lists)
returns boolean language sql stable security definer set search_path = wanderbites as $$
  select l.deleted_at is null
    and (
      l.owner_id = auth.uid()
      or l.visibility = 'public'
      or exists (
           select 1 from list_collaborators
           where list_id = l.id and user_id = auth.uid() and status = 'accepted')
      or is_admin()
    );
$$;

create or replace function wanderbites.list_visible_by_id(lid uuid)
returns boolean language sql stable security definer set search_path = wanderbites as $$
  select coalesce((select list_visible(l) from lists l where l.id = lid), false);
$$;

create or replace function wanderbites.rec_visible_by_id(rid uuid)
returns boolean language sql stable security definer set search_path = wanderbites as $$
  select coalesce((select rec_visible(r) from recommendations r where r.id = rid), false);
$$;

create or replace function wanderbites.can_edit_list(lid uuid)
returns boolean language sql stable security definer set search_path = wanderbites as $$
  select exists (
    select 1 from lists l
    where l.id = lid and l.deleted_at is null
      and (l.owner_id = auth.uid()
           or (l.is_collaborative and exists (
                 select 1 from list_collaborators c
                 where c.list_id = lid and c.user_id = auth.uid() and c.status = 'accepted')))
  );
$$;

create or replace function wanderbites.target_visible(ttype text, tid uuid)
returns boolean language plpgsql stable security definer set search_path = wanderbites as $$
begin
  -- plpgsql so the 'comment' branch can recurse into the comment's own target
  return case ttype
    when 'list' then list_visible_by_id(tid)
    when 'recommendation' then rec_visible_by_id(tid)
    when 'comment' then exists (select 1 from comments c
                                where c.id = tid and c.deleted_at is null
                                  and target_visible(c.target_type, c.target_id))
    else false
  end;
end $$;

-- Owner of an interaction target, for block checks + notifications.
create or replace function wanderbites.target_owner(ttype text, tid uuid)
returns uuid language sql stable security definer set search_path = wanderbites as $$
  select case ttype
    when 'list' then (select owner_id from lists where id = tid)
    when 'recommendation' then (select user_id from recommendations where id = tid)
    when 'comment' then (select user_id from comments where id = tid)
    else null
  end;
$$;

-- ---------------------------------------------------------------------------
-- Privilege-escalation guard: only admins may change moderation flags.
-- ---------------------------------------------------------------------------

create or replace function wanderbites.tg_profiles_guard()
returns trigger language plpgsql security definer set search_path = wanderbites as $$
begin
  if (new.is_admin is distinct from old.is_admin
      or new.is_verified is distinct from old.is_verified
      or new.is_suspended is distinct from old.is_suspended)
     and not is_admin() then
    raise exception 'not allowed to change moderation flags';
  end if;
  return new;
end $$;

create trigger profiles_guard before update on wanderbites.profiles
  for each row execute function wanderbites.tg_profiles_guard();

-- ---------------------------------------------------------------------------
-- Enable RLS everywhere
-- ---------------------------------------------------------------------------

alter table wanderbites.countries enable row level security;
alter table wanderbites.cities enable row level security;
alter table wanderbites.cuisines enable row level security;
alter table wanderbites.profiles enable row level security;
alter table wanderbites.user_settings enable row level security;
alter table wanderbites.restaurants enable row level security;
alter table wanderbites.restaurant_cuisines enable row level security;
alter table wanderbites.restaurant_photos enable row level security;
alter table wanderbites.recommendations enable row level security;
alter table wanderbites.recommendation_photos enable row level security;
alter table wanderbites.recommendation_feedback enable row level security;
alter table wanderbites.follows enable row level security;
alter table wanderbites.city_follows enable row level security;
alter table wanderbites.blocked_users enable row level security;
alter table wanderbites.restaurant_saves enable row level security;
alter table wanderbites.restaurant_visits enable row level security;
alter table wanderbites.lists enable row level security;
alter table wanderbites.list_restaurants enable row level security;
alter table wanderbites.list_collaborators enable row level security;
alter table wanderbites.list_follows enable row level security;
alter table wanderbites.comments enable row level security;
alter table wanderbites.likes enable row level security;
alter table wanderbites.badges enable row level security;
alter table wanderbites.user_badges enable row level security;
alter table wanderbites.notifications enable row level security;
alter table wanderbites.content_reports enable row level security;
alter table wanderbites.device_tokens enable row level security;

-- ---------------------------------------------------------------------------
-- Reference data: world-readable, admin-writable
-- ---------------------------------------------------------------------------

create policy countries_read on wanderbites.countries for select using (true);
create policy countries_admin_write on wanderbites.countries for all
  using (wanderbites.is_admin()) with check (wanderbites.is_admin());

create policy cities_read on wanderbites.cities for select using (true);
create policy cities_admin_write on wanderbites.cities for all
  using (wanderbites.is_admin()) with check (wanderbites.is_admin());

create policy cuisines_read on wanderbites.cuisines for select using (true);
create policy cuisines_admin_write on wanderbites.cuisines for all
  using (wanderbites.is_admin()) with check (wanderbites.is_admin());

-- ---------------------------------------------------------------------------
-- Profiles + settings
-- ---------------------------------------------------------------------------

create policy profiles_read on wanderbites.profiles for select
  using (deleted_at is null and (not is_suspended or id = auth.uid() or wanderbites.is_admin()));

create policy profiles_insert_own on wanderbites.profiles for insert
  with check (id = auth.uid());

create policy profiles_update_own on wanderbites.profiles for update
  using (id = auth.uid() or wanderbites.is_admin())
  with check (id = auth.uid() or wanderbites.is_admin());

create policy settings_own on wanderbites.user_settings for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- Restaurants
-- ---------------------------------------------------------------------------

create policy restaurants_read on wanderbites.restaurants for select
  using (deleted_at is null and (status = 'active' or wanderbites.is_admin()));

create policy restaurants_insert_auth on wanderbites.restaurants for insert
  with check (auth.uid() is not null and created_by = auth.uid()
              and is_seed = false and status = 'active');

create policy restaurants_admin_update on wanderbites.restaurants for update
  using (wanderbites.is_admin()) with check (wanderbites.is_admin());

create policy restaurant_cuisines_read on wanderbites.restaurant_cuisines for select using (true);
create policy restaurant_cuisines_insert on wanderbites.restaurant_cuisines for insert
  with check (auth.uid() is not null and exists (
    select 1 from wanderbites.restaurants r
    where r.id = restaurant_id and (r.created_by = auth.uid() or wanderbites.is_admin())));
create policy restaurant_cuisines_admin_delete on wanderbites.restaurant_cuisines for delete
  using (wanderbites.is_admin());

create policy restaurant_photos_read on wanderbites.restaurant_photos for select
  using (deleted_at is null);
create policy restaurant_photos_insert_own on wanderbites.restaurant_photos for insert
  with check (user_id = auth.uid());
create policy restaurant_photos_update_own on wanderbites.restaurant_photos for update
  using (user_id = auth.uid() or wanderbites.is_admin())
  with check (user_id = auth.uid() or wanderbites.is_admin());

-- ---------------------------------------------------------------------------
-- Recommendations + feedback
-- ---------------------------------------------------------------------------

create policy recs_read on wanderbites.recommendations for select
  using (wanderbites.rec_visible(recommendations));

create policy recs_insert_own on wanderbites.recommendations for insert
  with check (user_id = auth.uid());

create policy recs_update_own on wanderbites.recommendations for update
  using (user_id = auth.uid() or wanderbites.is_admin())
  with check (user_id = auth.uid() or wanderbites.is_admin());

create policy recs_delete_own on wanderbites.recommendations for delete
  using (user_id = auth.uid() or wanderbites.is_admin());

create policy rec_photos_read on wanderbites.recommendation_photos for select
  using (wanderbites.rec_visible_by_id(recommendation_id));
create policy rec_photos_write_own on wanderbites.recommendation_photos for all
  using (exists (select 1 from wanderbites.recommendations r
                 where r.id = recommendation_id and r.user_id = auth.uid()))
  with check (exists (select 1 from wanderbites.recommendations r
                      where r.id = recommendation_id and r.user_id = auth.uid()));

-- Feedback: visible with the parent; you can never rate your own rec.
create policy rec_feedback_read on wanderbites.recommendation_feedback for select
  using (wanderbites.rec_visible_by_id(recommendation_id));

create policy rec_feedback_insert on wanderbites.recommendation_feedback for insert
  with check (
    user_id = auth.uid()
    and wanderbites.rec_visible_by_id(recommendation_id)
    and not exists (select 1 from wanderbites.recommendations r
                    where r.id = recommendation_id and r.user_id = auth.uid())
  );

create policy rec_feedback_update_own on wanderbites.recommendation_feedback for update
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy rec_feedback_delete_own on wanderbites.recommendation_feedback for delete
  using (user_id = auth.uid() or wanderbites.is_admin());

-- ---------------------------------------------------------------------------
-- Social graph
-- ---------------------------------------------------------------------------

create policy follows_read on wanderbites.follows for select using (true);
create policy follows_insert_own on wanderbites.follows for insert
  with check (follower_id = auth.uid()
              and not wanderbites.is_blocked_between(follower_id, followee_id));
create policy follows_delete_own on wanderbites.follows for delete
  using (follower_id = auth.uid());

create policy city_follows_read on wanderbites.city_follows for select using (true);
create policy city_follows_write_own on wanderbites.city_follows for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy blocked_own on wanderbites.blocked_users for all
  using (blocker_id = auth.uid()) with check (blocker_id = auth.uid());

-- ---------------------------------------------------------------------------
-- Saves + visits
-- ---------------------------------------------------------------------------

create policy saves_read on wanderbites.restaurant_saves for select using (true);
create policy saves_write_own on wanderbites.restaurant_saves for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Visits are public only if the owner's settings allow it.
create policy visits_read on wanderbites.restaurant_visits for select
  using (user_id = auth.uid()
         or coalesce((select show_visited_publicly from wanderbites.user_settings s
                      where s.user_id = restaurant_visits.user_id), true));
create policy visits_write_own on wanderbites.restaurant_visits for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- Lists
-- ---------------------------------------------------------------------------

create policy lists_read on wanderbites.lists for select
  using (wanderbites.list_visible(lists));
create policy lists_insert_own on wanderbites.lists for insert
  with check (owner_id = auth.uid());
create policy lists_update_own on wanderbites.lists for update
  using (owner_id = auth.uid() or wanderbites.is_admin())
  with check (owner_id = auth.uid() or wanderbites.is_admin());
create policy lists_delete_own on wanderbites.lists for delete
  using (owner_id = auth.uid() or wanderbites.is_admin());

create policy list_restaurants_read on wanderbites.list_restaurants for select
  using (wanderbites.list_visible_by_id(list_id));
create policy list_restaurants_write on wanderbites.list_restaurants for all
  using (wanderbites.can_edit_list(list_id))
  with check (wanderbites.can_edit_list(list_id) and added_by = auth.uid());

create policy list_collabs_read on wanderbites.list_collaborators for select
  using (user_id = auth.uid() or wanderbites.list_visible_by_id(list_id));
create policy list_collabs_owner_invite on wanderbites.list_collaborators for insert
  with check (exists (select 1 from wanderbites.lists l
                      where l.id = list_id and l.owner_id = auth.uid() and l.is_collaborative)
              and not wanderbites.is_blocked_between(auth.uid(), user_id));
create policy list_collabs_accept on wanderbites.list_collaborators for update
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy list_collabs_remove on wanderbites.list_collaborators for delete
  using (user_id = auth.uid()
         or exists (select 1 from wanderbites.lists l
                    where l.id = list_id and l.owner_id = auth.uid()));

create policy list_follows_read on wanderbites.list_follows for select using (true);
create policy list_follows_write_own on wanderbites.list_follows for all
  using (user_id = auth.uid())
  with check (user_id = auth.uid() and wanderbites.list_visible_by_id(list_id));

-- ---------------------------------------------------------------------------
-- Comments + likes
-- ---------------------------------------------------------------------------

create policy comments_read on wanderbites.comments for select
  using (deleted_at is null and wanderbites.target_visible(target_type, target_id));
create policy comments_insert on wanderbites.comments for insert
  with check (user_id = auth.uid()
              and wanderbites.target_visible(target_type, target_id)
              and not wanderbites.is_blocked_between(auth.uid(), wanderbites.target_owner(target_type, target_id)));
create policy comments_update_own on wanderbites.comments for update
  using (user_id = auth.uid() or wanderbites.is_admin())
  with check (user_id = auth.uid() or wanderbites.is_admin());
create policy comments_delete_own on wanderbites.comments for delete
  using (user_id = auth.uid() or wanderbites.is_admin());

create policy likes_read on wanderbites.likes for select
  using (wanderbites.target_visible(target_type, target_id));
create policy likes_insert_own on wanderbites.likes for insert
  with check (user_id = auth.uid()
              and wanderbites.target_visible(target_type, target_id)
              and not wanderbites.is_blocked_between(auth.uid(), wanderbites.target_owner(target_type, target_id)));
create policy likes_delete_own on wanderbites.likes for delete
  using (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- Badges, notifications, reports, devices
-- ---------------------------------------------------------------------------

create policy badges_read on wanderbites.badges for select using (true);
create policy user_badges_read on wanderbites.user_badges for select using (true);
-- user_badges has no client write policies: awards happen in definer functions.

create policy notifications_read_own on wanderbites.notifications for select
  using (user_id = auth.uid());
create policy notifications_update_own on wanderbites.notifications for update
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy notifications_delete_own on wanderbites.notifications for delete
  using (user_id = auth.uid());
-- inserts happen inside definer functions only.

create policy reports_insert_own on wanderbites.content_reports for insert
  with check (reporter_id = auth.uid());
create policy reports_read on wanderbites.content_reports for select
  using (reporter_id = auth.uid() or wanderbites.is_admin());
create policy reports_admin_update on wanderbites.content_reports for update
  using (wanderbites.is_admin()) with check (wanderbites.is_admin());

create policy device_tokens_own on wanderbites.device_tokens for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());
