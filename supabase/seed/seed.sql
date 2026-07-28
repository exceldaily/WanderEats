-- WanderBites development seed data.
-- Everything here is FICTIONAL and clearly separable from production:
--   - restaurants carry is_seed = true
--   - seeded profiles use the wb_ username prefix and @wanderbites.dev emails
--   - seeded auth users share the fixed UUID prefix a0000000-...
--
-- SHARED-PROJECT NOTE: the auth.users insert runs with
-- session_replication_role = replica so sibling apps' auth triggers
-- (e.g. orbitstack's on_auth_user_created) do NOT fire for these fake users.
-- It is reset immediately after so WanderBites' own counter/notification
-- triggers work for the rest of the seed.

begin;

-- ---------------------------------------------------------------------------
-- 1. Fake auth users (20 tasters), triggers suppressed
-- ---------------------------------------------------------------------------
set local session_replication_role = replica;

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
  created_at, updated_at
)
select
  '00000000-0000-0000-0000-000000000000',
  ('a0000000-0000-4000-8000-0000000000' || lpad(i::text, 2, '0'))::uuid,
  'authenticated', 'authenticated',
  'wb_taster' || lpad(i::text, 2, '0') || '@wanderbites.dev',
  extensions.crypt('wanderbites-seed-no-login', extensions.gen_salt('bf')),
  now(), '{"provider":"email","providers":["email"]}', '{}',
  now() - (i || ' days')::interval, now()
from generate_series(1, 20) i
on conflict (id) do nothing;

set local session_replication_role = origin;

-- ---------------------------------------------------------------------------
-- 2. Countries, cities, cuisines
-- ---------------------------------------------------------------------------
insert into wanderbites.countries (id, name, iso_code, flag_emoji) values
  ('b0000000-0000-4000-8000-000000000001', 'United States', 'US', E'\U0001F1FA\U0001F1F8'),
  ('b0000000-0000-4000-8000-000000000002', 'Japan', 'JP', E'\U0001F1EF\U0001F1F5'),
  ('b0000000-0000-4000-8000-000000000003', 'Thailand', 'TH', E'\U0001F1F9\U0001F1ED'),
  ('b0000000-0000-4000-8000-000000000004', 'Italy', 'IT', E'\U0001F1EE\U0001F1F9'),
  ('b0000000-0000-4000-8000-000000000005', 'Mexico', 'MX', E'\U0001F1F2\U0001F1FD'),
  ('b0000000-0000-4000-8000-000000000006', 'France', 'FR', E'\U0001F1EB\U0001F1F7')
on conflict (id) do nothing;

insert into wanderbites.cities (id, country_id, name, slug, center) values
  ('c0000000-0000-4000-8000-000000000001', 'b0000000-0000-4000-8000-000000000001', 'New York', 'new-york', extensions.st_setsrid(extensions.st_makepoint(-74.0060, 40.7128), 4326)::extensions.geography),
  ('c0000000-0000-4000-8000-000000000002', 'b0000000-0000-4000-8000-000000000001', 'Austin', 'austin', extensions.st_setsrid(extensions.st_makepoint(-97.7431, 30.2672), 4326)::extensions.geography),
  ('c0000000-0000-4000-8000-000000000003', 'b0000000-0000-4000-8000-000000000001', 'Los Angeles', 'los-angeles', extensions.st_setsrid(extensions.st_makepoint(-118.2437, 34.0522), 4326)::extensions.geography),
  ('c0000000-0000-4000-8000-000000000004', 'b0000000-0000-4000-8000-000000000002', 'Tokyo', 'tokyo', extensions.st_setsrid(extensions.st_makepoint(139.6503, 35.6762), 4326)::extensions.geography),
  ('c0000000-0000-4000-8000-000000000005', 'b0000000-0000-4000-8000-000000000002', 'Osaka', 'osaka', extensions.st_setsrid(extensions.st_makepoint(135.5023, 34.6937), 4326)::extensions.geography),
  ('c0000000-0000-4000-8000-000000000006', 'b0000000-0000-4000-8000-000000000003', 'Bangkok', 'bangkok', extensions.st_setsrid(extensions.st_makepoint(100.5018, 13.7563), 4326)::extensions.geography),
  ('c0000000-0000-4000-8000-000000000007', 'b0000000-0000-4000-8000-000000000003', 'Chiang Mai', 'chiang-mai', extensions.st_setsrid(extensions.st_makepoint(98.9853, 18.7883), 4326)::extensions.geography),
  ('c0000000-0000-4000-8000-000000000008', 'b0000000-0000-4000-8000-000000000004', 'Rome', 'rome', extensions.st_setsrid(extensions.st_makepoint(12.4964, 41.9028), 4326)::extensions.geography),
  ('c0000000-0000-4000-8000-000000000009', 'b0000000-0000-4000-8000-000000000005', 'Mexico City', 'mexico-city', extensions.st_setsrid(extensions.st_makepoint(-99.1332, 19.4326), 4326)::extensions.geography),
  ('c0000000-0000-4000-8000-000000000010', 'b0000000-0000-4000-8000-000000000006', 'Paris', 'paris', extensions.st_setsrid(extensions.st_makepoint(2.3522, 48.8566), 4326)::extensions.geography)
on conflict (id) do nothing;

insert into wanderbites.cuisines (name, slug, emoji) values
  ('Pizza', 'pizza', E'\U0001F355'), ('Sushi', 'sushi', E'\U0001F363'),
  ('Ramen', 'ramen', E'\U0001F35C'), ('Street Food', 'street-food', E'\U0001F35B'),
  ('Tacos', 'tacos', E'\U0001F32E'), ('BBQ', 'bbq', E'\U0001F356'),
  ('Coffee', 'coffee', E'☕'), ('Brunch', 'brunch', E'\U0001F95E'),
  ('Thai', 'thai', E'\U0001F336'), ('Italian', 'italian', E'\U0001F35D'),
  ('French', 'french', E'\U0001F956'), ('Vegan', 'vegan', E'\U0001F957'),
  ('Seafood', 'seafood', E'\U0001F99E'), ('Dessert', 'dessert', E'\U0001F370')
on conflict (slug) do nothing;

-- ---------------------------------------------------------------------------
-- 3. Taster profiles + settings
-- ---------------------------------------------------------------------------
with t(i, username, display_name, bio, city) as (values
  (1,  'wb_mia_eats', 'Mia Torres', 'Chasing the perfect taco since 2019. If I recommend it, I have been there twice.', 9),
  (2,  'wb_kenji_bites', 'Kenji Watanabe', 'Tokyo salaryman by day, ramen cartographer by night.', 4),
  (3,  'wb_saras_table', 'Sara Lindqvist', 'Slow mornings, long brunches. Stockholm heart, New York stomach.', 1),
  (4,  'wb_pit_master_max', 'Max Delaney', 'Austin BBQ evangelist. Brisket is a love language.', 2),
  (5,  'wb_noodle_nadia', 'Nadia Rahman', 'Slurping my way across Asia one bowl at a time.', 6),
  (6,  'wb_roman_holiday', 'Giulia Ferri', 'Rome native. I will fight you about carbonara.', 8),
  (7,  'wb_leo_la_eats', 'Leo Kim', 'LA strip malls hide the best kitchens in America.', 3),
  (8,  'wb_petit_paris', 'Camille Robert', 'Paris pastry patrol. Croissant standards: unreasonable.', 10),
  (9,  'wb_bkk_somchai', 'Somchai Prasert', 'Bangkok street food is a religion and I am devout.', 6),
  (10, 'wb_osaka_aya', 'Aya Nishimura', 'Kuidaore: eat until you drop. Osaka does it best.', 5),
  (11, 'wb_veggie_vera', 'Vera Okafor', 'Proving plant-based never means flavor-free.', 1),
  (12, 'wb_espresso_eli', 'Eli Navarro', 'Third-wave coffee hunter. Single origin or nothing.', 3),
  (13, 'wb_cdmx_diego', 'Diego Fuentes', 'Mexico City is the best food city on earth. Debate me.', 9),
  (14, 'wb_chiangmai_kate', 'Kate Boonmee', 'Northern Thai kitchens and mountain coffee farms.', 7),
  (15, 'wb_slice_sam', 'Sam Rizzo', 'On a lifelong quest to rank every slice in the five boroughs.', 1),
  (16, 'wb_tokyo_tessa', 'Tessa Vaughn', 'Expat in Tokyo documenting tiny counters and big flavors.', 4),
  (17, 'wb_atx_amara', 'Amara Johnson', 'Austin tacos, trailers and everything topped with queso.', 2),
  (18, 'wb_pastaia_paola', 'Paola Bianchi', 'Fresh pasta apprentice, gelato professional.', 8),
  (19, 'wb_seine_sofia', 'Sofia Marchand', 'Bistro benches along the Seine. Old rooms, honest plates.', 10),
  (20, 'wb_dockside_dan', 'Dan Whitmore', 'Seafood shacks, fish markets and anything grilled over fire.', 3)
)
insert into wanderbites.profiles (id, username, display_name, bio, home_city_id, is_verified, onboarding_completed, created_at)
select ('a0000000-0000-4000-8000-0000000000' || lpad(t.i::text, 2, '0'))::uuid,
       t.username, t.display_name, t.bio,
       ('c0000000-0000-4000-8000-0000000000' || lpad(t.city::text, 2, '0'))::uuid,
       t.i <= 8, true, now() - (t.i || ' days')::interval
from t
on conflict (id) do nothing;

insert into wanderbites.user_settings (user_id)
select id from wanderbites.profiles where username like 'wb\_%' escape '\'
on conflict (user_id) do nothing;

-- ---------------------------------------------------------------------------
-- 4. 100 restaurants: 10 per city, deterministic offsets around the center
-- ---------------------------------------------------------------------------
do $seed$
declare
  city_ids uuid[] := array[
    'c0000000-0000-4000-8000-000000000001','c0000000-0000-4000-8000-000000000002',
    'c0000000-0000-4000-8000-000000000003','c0000000-0000-4000-8000-000000000004',
    'c0000000-0000-4000-8000-000000000005','c0000000-0000-4000-8000-000000000006',
    'c0000000-0000-4000-8000-000000000007','c0000000-0000-4000-8000-000000000008',
    'c0000000-0000-4000-8000-000000000009','c0000000-0000-4000-8000-000000000010'];
  names text[][] := array[
    -- New York
    array['Brass Radiator Pizza','Hidden Fern Cafe','Marrow & Rye','Two Bridges Noodle Bar','Cornerstone Bagels','The Velvet Oyster','Uptown Ember BBQ','Cloud Nine Brunch Club','Mott Street Dumpling Co','Midnight Slice'],
    -- Austin
    array['Smoke Signal BBQ','Yard Bird Tacos','Hill Country Biscuit Co','Neon Cactus Cantina','Barton Creek Coffee','The Brisket Chapel','Lady Bird Diner','Pecan Grove Pit','Rio Verde Ceviche','Moontower Pie Garden'],
    -- Los Angeles
    array['Golden Hour Sushi','Mariachi Plaza Birria','Canyon Greens Kitchen','Pacific Smoke Shack','Silver Lake Beans','Koreatown Ember Grill','The Mulholland Melt','Venice Tide Poke','Echo Park Pupuseria','Sunset Citrus Bar'],
    -- Tokyo
    array['Kagero Ramen','Sakura Alley Sushi','Golden Gai Yakitori','Shinjuku Depachika Deli','Mori Coffee Roasters','Tsukemen Tetsu','Nakameguro River Cafe','Ebisu Tempura House','Aoyama Melonpan','Backstreet Curry Ando'],
    -- Osaka
    array['Dotonbori Blaze Takoyaki','Kushi Palace','Namba Standing Sushi','Umeda Whisper Coffee','Okonomiyaki Hanabi','Shinsekai Skewer Den','Kansai Comfort Kitchen','Riverside Melon Cream','Torafugu Alley','Midnight Udon Ichiba'],
    -- Bangkok
    array['Boat Noodle Sanctuary','Yaowarat Fire Wok','Green Papaya House','Khao San Morning Market','Silom Sticky Rice','Mango Cloud Cafe','Floating Lantern Curry','Charcoal Chicken Soi 9','Tom Yum Temple','Iron Wok Alley'],
    -- Chiang Mai
    array['Mountain Mist Khao Soi','Old City Larb Lab','Night Bazaar Grill','Doi Coffee Collective','Riverside Sticky Mango','Lanna Herb Kitchen','Sunday Walking Wok','Jade Orchid Noodles','Banyan Shade Cafe','Ping River Smokehouse'],
    -- Rome
    array['Trastevere Ember Pizza','Carbonara Correnti','Nonna Lucia Trattoria','Testaccio Supplì Stand','Gelateria Luna Bianca','Campo Fiori Forno','Cacio Vicolo','Aventine Garden Osteria','Pantheon Espresso Bar','Tiber Dusk Enoteca'],
    -- Mexico City
    array['Al Pastor Pendulum','Condesa Corn Club','Roma Norte Mole House','Tacos La Madrugada','Churros El Faro','Mercado Verde Tostadas','Cantina Los Suspiros','Barbacoa del Domingo','Pulqueria La Nube','Chilaquiles Corner'],
    -- Paris
    array['Boulangerie du Canal','Le Hibou Bistro','Marais Falafel Royale','Crêperie Onze Heures','Café des Toits','La Petite Marée','Butte aux Fromages','Saint-Michel Ramen','Jardin d''Épices','Chocolat de Minuit']
  ];
  cuisine_map text[][] := array[
    array['pizza','coffee','brunch','ramen','brunch','seafood','bbq','brunch','street-food','pizza'],
    array['bbq','tacos','brunch','tacos','coffee','bbq','brunch','bbq','seafood','dessert'],
    array['sushi','tacos','vegan','bbq','coffee','bbq','brunch','seafood','street-food','brunch'],
    array['ramen','sushi','street-food','street-food','coffee','ramen','coffee','seafood','dessert','street-food'],
    array['street-food','street-food','sushi','coffee','street-food','street-food','brunch','dessert','seafood','ramen'],
    array['street-food','thai','thai','street-food','thai','dessert','thai','street-food','thai','street-food'],
    array['thai','thai','bbq','coffee','dessert','thai','street-food','thai','coffee','bbq'],
    array['pizza','italian','italian','street-food','dessert','italian','italian','italian','coffee','italian'],
    array['tacos','street-food','street-food','tacos','dessert','vegan','street-food','bbq','street-food','brunch'],
    array['dessert','french','street-food','french','coffee','seafood','french','ramen','french','dessert']
  ];
  ci int; ri int; idx int;
  clat double precision; clng double precision;
  rid uuid;
begin
  for ci in 1..10 loop
    select extensions.st_y(center::extensions.geometry),
           extensions.st_x(center::extensions.geometry)
      into clat, clng
      from wanderbites.cities where id = city_ids[ci];
    for ri in 1..10 loop
      idx := (ci - 1) * 10 + ri;
      rid := ('d0000000-0000-4000-8000-0000000000' || lpad(idx::text, 2, '0'))::uuid;
      -- 100 fits two hex chars only up to 99; index 100 becomes ...0100
      if idx = 100 then rid := 'd0000000-0000-4000-8000-000000000100'; end if;
      insert into wanderbites.restaurants
        (id, name, city_id, address, location, price_level, opening_hours,
         external_provider, external_id, is_seed, created_at)
      values (
        rid,
        names[ci][ri],
        city_ids[ci],
        (100 + idx)::text || ' ' || split_part(names[ci][ri], ' ', 1) || ' Street',
        extensions.st_setsrid(extensions.st_makepoint(
          clng + ((((idx * 53) % 100) / 100.0) - 0.5) * 0.05,
          clat + ((((idx * 37) % 100) / 100.0) - 0.5) * 0.05
        ), 4326)::extensions.geography,
        ((idx % 4) + 1)::smallint,
        jsonb_build_object('mon_fri', '11:00-22:00', 'sat_sun', '10:00-23:00'),
        'seed', 'seed-' || idx,
        true,
        now() - ((idx % 60) || ' days')::interval
      )
      on conflict (id) do nothing;

      insert into wanderbites.restaurant_cuisines (restaurant_id, cuisine_id)
      select rid, cu.id from wanderbites.cuisines cu
      where cu.slug = cuisine_map[ci][ri]
      on conflict do nothing;
    end loop;
  end loop;
end $seed$;

-- ---------------------------------------------------------------------------
-- 5. Follow graph: each taster follows the next five (wrap-around)
-- ---------------------------------------------------------------------------
insert into wanderbites.follows (follower_id, followee_id, created_at)
select ('a0000000-0000-4000-8000-0000000000' || lpad(i::text, 2, '0'))::uuid,
       ('a0000000-0000-4000-8000-0000000000' || lpad((((i - 1 + k) % 20) + 1)::text, 2, '0'))::uuid,
       now() - ((i + k) || ' days')::interval
from generate_series(1, 20) i, generate_series(1, 5) k
where ((i - 1 + k) % 20) + 1 <> i
on conflict do nothing;

-- ---------------------------------------------------------------------------
-- 6. Recommendations: every taster recommends 2 restaurants near home
-- ---------------------------------------------------------------------------
do $seed$
declare
  bodies text[] := array[
    'The kind of place you text people about before you have even left the table. Order at the counter, sit outside if you can.',
    'Looks like nothing from the street, then the first bite rearranges your priorities. Go early, it fills up with regulars fast.',
    'I have taken four friends here and every one of them has gone back without me. That is the highest praise I have.',
    'Perfect after a long walk through the neighborhood. Portions are honest and the staff remember faces.',
    'This is my benchmark for the whole city now. Not fancy, just precise. Cash helps, card works.',
    'Come hungry and split everything. The menu is short because everything on it earns its place.',
    'The smell alone from two doors down is worth the detour. Peak hours get loud, lunch is calmer.',
    'A tiny room, a huge heart. Watch the kitchen work if you get counter seats, it is half the show.',
    'I planned one quick stop and stayed two hours. Prices are fair for what lands on the table.',
    'If you only have one meal in this neighborhood, make it this one. Trust the daily special.',
    'Family-run and it shows in the best way. Ask what is fresh today and just say yes.',
    'Worth crossing the city for, and I say that as someone who hates crossing the city.'
  ];
  orders text[] := array[
    'The house special, plus whatever the person next to you is having.',
    'Get the signature dish and the seasonal side. Skip the soda, get the homemade drink.',
    'One classic, one wildcard from the daily board.',
    'The thing the place is named for. Do not overthink it.',
    'Whatever is coming off the grill when you sit down, and the dessert.'
  ];
  i int; ri int; rec_id uuid; taster uuid; rest uuid; hc uuid;
begin
  for i in 1..20 loop
    taster := ('a0000000-0000-4000-8000-0000000000' || lpad(i::text, 2, '0'))::uuid;
    select home_city_id into hc from wanderbites.profiles where id = taster;
    ri := 0;
    for rest in
      select r.id from wanderbites.restaurants r
      where r.city_id = hc and r.is_seed
      order by r.external_id
      limit 2 offset (i % 5)
    loop
      ri := ri + 1;
      insert into wanderbites.recommendations
        (id, user_id, restaurant_id, body, what_to_order, price_impression,
         visited_on, visibility, created_at)
      values (
        extensions.uuid_generate_v5('6ba7b810-9dad-11d1-80b4-00c04fd430c8'::uuid,
                                    'wb-rec-' || i || '-' || ri),
        taster, rest,
        bodies[((i + ri) % 12) + 1],
        orders[((i + ri) % 5) + 1],
        ((i + ri) % 4 + 1)::smallint,
        current_date - ((i * 3 + ri) % 90),
        'public',
        now() - (((i * 5 + ri) % 100) || ' days')::interval
      )
      on conflict (user_id, restaurant_id) do nothing;
    end loop;
  end loop;
end $seed$;

-- ---------------------------------------------------------------------------
-- 7. Feedback: followers rate recommendations (never the author)
-- ---------------------------------------------------------------------------
insert into wanderbites.recommendation_feedback (recommendation_id, user_id, rating, created_at)
select rec.id,
       f.follower_id,
       (array['exact','great','great','somewhat','exact','great','mismatch','exact'])
         [ (abs(hashtext(rec.id::text || f.follower_id::text)) % 8) + 1 ],
       rec.created_at + interval '7 days'
from wanderbites.recommendations rec
join wanderbites.follows f on f.followee_id = rec.user_id
where f.follower_id <> rec.user_id
  and (abs(hashtext(f.follower_id::text || rec.id::text)) % 3) = 0
on conflict do nothing;

-- ---------------------------------------------------------------------------
-- 8. Saves and visits
-- ---------------------------------------------------------------------------
insert into wanderbites.restaurant_saves (user_id, restaurant_id, created_at)
select p.id, r.id, now() - ((abs(hashtext(p.id::text || r.id::text)) % 45) || ' days')::interval
from wanderbites.profiles p
cross join lateral (
  select id from wanderbites.restaurants
  where is_seed
  order by abs(hashtext(id::text || p.id::text))
  limit 6
) r
where p.username like 'wb\_%' escape '\'
on conflict do nothing;

insert into wanderbites.restaurant_visits (user_id, restaurant_id, visited_on, created_at)
select p.id, r.id,
       current_date - (abs(hashtext(r.id::text || p.id::text)) % 120),
       now()
from wanderbites.profiles p
cross join lateral (
  select id from wanderbites.restaurants
  where is_seed
  order by abs(hashtext(p.id::text || id::text))
  limit 4
) r
where p.username like 'wb\_%' escape '\'
on conflict do nothing;

-- ---------------------------------------------------------------------------
-- 9. Lists (15 public) + entries + follows
-- ---------------------------------------------------------------------------
do $seed$
declare
  titles text[] := array[
    'Best Pizza in New York','Tokyo Hidden Gems','Bangkok Street Food Crawl',
    'Food Under $20','Date Night Rome','Late-Night Tokyo','Weekend in Austin',
    'Coffee Worth Traveling For','CDMX Taco Pilgrimage','Paris on a Baguette Budget',
    'Osaka Eat-Til-You-Drop','Chiang Mai Slow Days','LA Strip Mall Treasures',
    'Brunch Worth Waking Up For','Seafood by the Water'
  ];
  descs text[] := array[
    'Ranked after too many carb-loaded weekends.','Counters with six seats and zero signage.',
    'Follow the smoke and the queues of locals.','Full meals, small bills, no compromises.',
    'Candlelit rooms and long dinners.','For when the city refuses to sleep.',
    'Two days, zero bad meals.','Beans that justify a layover.',
    'The pastor rotation never stops.','Crusty, buttery, perfect.',
    'Kuidaore is a lifestyle.','Khao soi mornings, river evenings.',
    'Best kitchens hide behind parking lots.','Eggs are just the beginning.',
    'Salt air included.'
  ];
  cities int[] := array[1,4,6,1,8,4,2,3,9,10,5,7,3,2,3];
  i int; owner uuid; lid uuid; pos int; rest uuid;
begin
  for i in 1..15 loop
    owner := ('a0000000-0000-4000-8000-0000000000' || lpad((((i * 7) % 20) + 1)::text, 2, '0'))::uuid;
    lid := ('e0000000-0000-4000-8000-0000000000' || lpad(i::text, 2, '0'))::uuid;
    insert into wanderbites.lists (id, owner_id, title, description, visibility, is_collaborative, created_at)
    values (lid, owner, titles[i], descs[i], 'public', i % 5 = 0,
            now() - ((i * 4) || ' days')::interval)
    on conflict (id) do nothing;

    pos := 0;
    for rest in
      select r.id from wanderbites.restaurants r
      where r.city_id = ('c0000000-0000-4000-8000-0000000000' || lpad(cities[i]::text, 2, '0'))::uuid
        and r.is_seed
      order by abs(hashtext(r.id::text || i::text))
      limit 4 + (i % 4)
    loop
      pos := pos + 1;
      insert into wanderbites.list_restaurants (list_id, restaurant_id, added_by, position)
      values (lid, rest, owner, pos)
      on conflict do nothing;
    end loop;
  end loop;
end $seed$;

insert into wanderbites.list_follows (user_id, list_id, created_at)
select p.id, l.id, now() - ((abs(hashtext(p.id::text || l.id::text)) % 30) || ' days')::interval
from wanderbites.profiles p
join wanderbites.lists l on l.owner_id <> p.id
where p.username like 'wb\_%' escape '\'
  and (abs(hashtext(l.id::text || p.id::text)) % 4) = 0
on conflict do nothing;

-- ---------------------------------------------------------------------------
-- 10. Badges (definitions live in DB, requirements as jsonb)
-- ---------------------------------------------------------------------------
insert into wanderbites.badges (slug, name, description, icon, category, requirement, sort) values
  ('early-explorer', 'Early Explorer', 'Marked your first restaurant visited.', 'flag', 'exploration', '{"type":"visits_count","count":1}', 1),
  ('local-guide', 'Local Guide', 'Published 5 recommendations.', 'map', 'trust', '{"type":"recs_count","count":5}', 2),
  ('top-taster', 'Top Taster', 'Published 25 recommendations.', 'workspace_premium', 'trust', '{"type":"recs_count","count":25}', 3),
  ('pizza-expert', 'Pizza Expert', 'Recommended 5 pizza spots.', 'local_pizza', 'cuisine', '{"type":"cuisine_recs","cuisine":"pizza","count":5}', 4),
  ('coffee-hunter', 'Coffee Hunter', 'Recommended 5 coffee spots.', 'coffee', 'cuisine', '{"type":"cuisine_recs","cuisine":"coffee","count":5}', 5),
  ('street-food-explorer', 'Street Food Explorer', 'Recommended 5 street food spots.', 'ramen_dining', 'cuisine', '{"type":"cuisine_recs","cuisine":"street-food","count":5}', 6),
  ('ten-cities', '10 Cities', 'Ate your way through 10 cities.', 'location_city', 'exploration', '{"type":"cities_visited","count":10}', 7),
  ('fifty-cities', '50 Cities', 'Ate your way through 50 cities.', 'public', 'exploration', '{"type":"cities_visited","count":50}', 8),
  ('hundred-restaurants', '100 Restaurants', 'Visited 100 restaurants.', 'restaurant', 'exploration', '{"type":"visits_count","count":100}', 9),
  ('thousand-saves', '1,000 Saves', 'Saved 1,000 restaurants.', 'bookmark', 'activity', '{"type":"saves_count","count":1000}', 10),
  ('globetrotter', 'Globetrotter', 'Visited restaurants in 3 countries.', 'travel_explore', 'exploration', '{"type":"countries_visited","count":3}', 11),
  ('list-curator', 'List Curator', 'Published 3 public lists.', 'playlist_add_check', 'activity', '{"type":"lists_count","count":3}', 12)
on conflict (slug) do nothing;

-- Award starter badges to seeded tasters who qualify (visits exist for all)
insert into wanderbites.user_badges (user_id, badge_id)
select p.id, b.id
from wanderbites.profiles p
join wanderbites.badges b on b.slug = 'early-explorer'
where p.username like 'wb\_%' escape '\'
on conflict do nothing;

commit;
