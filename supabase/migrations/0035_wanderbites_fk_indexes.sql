-- 0035: hot-path FK indexes. Tables are small today; these keep the common
-- lookups (followers of X, my saves, chat scrollback, feed joins) from
-- degrading into sequential scans as data grows.
create index if not exists idx_follows_followee on wanderbites.follows (followee_id);
create index if not exists idx_notifications_user_created on wanderbites.notifications (user_id, created_at desc);
create index if not exists idx_messages_conversation_created on wanderbites.messages (conversation_id, created_at desc);
create index if not exists idx_likes_target on wanderbites.likes (target_type, target_id);
create index if not exists idx_recommendations_user on wanderbites.recommendations (user_id);
create index if not exists idx_recommendations_restaurant on wanderbites.recommendations (restaurant_id);
create index if not exists idx_recommendation_feedback_rec on wanderbites.recommendation_feedback (recommendation_id);
create index if not exists idx_restaurant_saves_user on wanderbites.restaurant_saves (user_id);
create index if not exists idx_restaurant_visits_user on wanderbites.restaurant_visits (user_id);
create index if not exists idx_restaurant_photos_restaurant on wanderbites.restaurant_photos (restaurant_id);
create index if not exists idx_restaurant_cuisines_restaurant on wanderbites.restaurant_cuisines (restaurant_id);
create index if not exists idx_restaurants_city on wanderbites.restaurants (city_id);
create index if not exists idx_lists_owner on wanderbites.lists (owner_id);
create index if not exists idx_list_follows_list on wanderbites.list_follows (list_id);
create index if not exists idx_list_restaurants_list on wanderbites.list_restaurants (list_id);
create index if not exists idx_device_tokens_user on wanderbites.device_tokens (user_id);
create index if not exists idx_conversations_member_a on wanderbites.conversations (member_a);
create index if not exists idx_conversations_member_b on wanderbites.conversations (member_b);
create index if not exists idx_blocked_users_blocker on wanderbites.blocked_users (blocker_id);
create index if not exists idx_blocked_users_blocked on wanderbites.blocked_users (blocked_id);
create index if not exists idx_food_trips_owner on wanderbites.food_trips (owner_id);
create index if not exists idx_food_trip_stops_trip on wanderbites.food_trip_stops (trip_id);
create index if not exists idx_taste_group_members_user on wanderbites.taste_group_members (user_id);
create index if not exists idx_taste_group_members_group on wanderbites.taste_group_members (group_id);
create index if not exists idx_comments_user on wanderbites.comments (user_id);
