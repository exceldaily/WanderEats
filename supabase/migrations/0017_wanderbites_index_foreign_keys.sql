-- Covering indexes for every foreign key the linter flagged as unindexed.
--
-- The one that actually bites is account deletion: delete_account() removes
-- the profile and lets ON DELETE CASCADE walk a dozen child tables. Without an
-- index on the referencing column each cascade is a sequential scan, so
-- deletion gets linearly slower as the table grows - exactly the operation
-- that must not time out, because it is a privacy commitment with a 30-day
-- promise attached.
--
-- CREATE INDEX IF NOT EXISTS so this is safe to re-run.

create index if not exists idx_city_follows_city_id on wanderbites.city_follows (city_id);
create index if not exists idx_comments_user_id on wanderbites.comments (user_id);
create index if not exists idx_content_reports_reporter_id on wanderbites.content_reports (reporter_id);
create index if not exists idx_list_restaurants_added_by on wanderbites.list_restaurants (added_by);
create index if not exists idx_list_restaurants_restaurant_id on wanderbites.list_restaurants (restaurant_id);
create index if not exists idx_notifications_actor_id on wanderbites.notifications (actor_id);
create index if not exists idx_profiles_home_city_id on wanderbites.profiles (home_city_id);
create index if not exists idx_recommendation_feedback_user_id on wanderbites.recommendation_feedback (user_id);
create index if not exists idx_restaurant_cuisines_cuisine_id on wanderbites.restaurant_cuisines (cuisine_id);
create index if not exists idx_restaurant_photos_user_id on wanderbites.restaurant_photos (user_id);
create index if not exists idx_restaurant_save_sources_restaurant_id on wanderbites.restaurant_save_sources (restaurant_id);
create index if not exists idx_restaurant_save_sources_session_id on wanderbites.restaurant_save_sources (session_id);
create index if not exists idx_restaurant_save_sources_via_taster_id on wanderbites.restaurant_save_sources (via_taster_id);
create index if not exists idx_restaurant_skips_restaurant_id on wanderbites.restaurant_skips (restaurant_id);
create index if not exists idx_restaurants_created_by on wanderbites.restaurants (created_by);
create index if not exists idx_taste_deck_impressions_restaurant_id on wanderbites.taste_deck_impressions (restaurant_id);
create index if not exists idx_taste_deck_impressions_via_taster_id on wanderbites.taste_deck_impressions (via_taster_id);
create index if not exists idx_taste_deck_sessions_city_id on wanderbites.taste_deck_sessions (city_id);
create index if not exists idx_taste_preference_feedback_restaurant_id on wanderbites.taste_preference_feedback (restaurant_id);
create index if not exists idx_user_badges_badge_id on wanderbites.user_badges (badge_id);
