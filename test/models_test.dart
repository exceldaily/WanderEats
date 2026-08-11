import 'package:flutter_test/flutter_test.dart';
import 'package:wanderbites/app/configuration/env.dart';
import 'package:wanderbites/features/lists/domain/food_list.dart';
import 'package:wanderbites/features/map/presentation/map_controller.dart';
import 'package:wanderbites/features/notifications/data/notification_repository.dart';
import 'package:wanderbites/features/profile/domain/profile.dart';
import 'package:wanderbites/features/recommendations/domain/recommendation.dart';
import 'package:wanderbites/features/restaurants/domain/restaurant.dart';

void main() {
  group('Env', () {
    test('defaults are safe without dart-defines', () {
      expect(Env.isConfigured, isFalse);
      expect(Env.supabaseSchema, 'wanderbites');
      expect(Env.hasMapsKey, isFalse);
      expect(Env.isProduction, isFalse);
    });
  });

  group('RestaurantMarker', () {
    test('parses RPC row', () {
      final m = RestaurantMarker.fromJson({
        'id': 'r1',
        'name': 'Kagero Ramen',
        'lat': 35.67,
        'lng': 139.65,
        'price_level': 2,
        'rec_count': 4,
        'save_count': 9,
        'score': 8.5,
        'cover_photo_url': null,
        'city_id': 'c1',
      });
      expect(m.name, 'Kagero Ramen');
      expect(m.recCount, 4);
      expect(m.score, 8.5);
      expect(m.distanceM, isNull);
    });

    test('round-trips through json for the offline cache', () {
      const m = RestaurantMarker(
          id: 'r1', name: 'Test', lat: 1.0, lng: 2.0, recCount: 3);
      final restored = RestaurantMarker.fromJson(m.toJson());
      expect(restored, m);
    });
  });

  group('Profile', () {
    test('parses a row with nulls', () {
      final p = Profile.fromJson({
        'id': 'u1',
        'username': 'wb_mia_eats',
        'display_name': 'Mia Torres',
        'bio': null,
        'avatar_url': null,
        'header_url': null,
        'home_city_id': null,
        'is_verified': true,
        'is_admin': false,
        'onboarding_completed': true,
        'favorite_cuisines': ['cu1'],
        'created_at': '2026-07-01T00:00:00Z',
      });
      expect(p.username, 'wb_mia_eats');
      expect(p.isVerified, isTrue);
      expect(p.favoriteCuisines, ['cu1']);
    });
  });

  group('Recommendation', () {
    test('parses with embedded author and photos', () {
      final r = Recommendation.fromJson({
        'id': 'rec1',
        'user_id': 'u1',
        'restaurant_id': 'r1',
        'body': 'Worth the trip, order the special.',
        'what_to_order': 'The special',
        'price_impression': 2,
        'visited_on': '2026-07-01',
        'visibility': 'public',
        'created_at': '2026-07-02T10:00:00Z',
        'profiles': {'username': 'wb_mia_eats', 'display_name': 'Mia'},
        'recommendation_photos': [
          {'storage_path': 'https://x/y.jpg', 'position': 0}
        ],
      });
      expect(r.author?['username'], 'wb_mia_eats');
      expect(r.photos, hasLength(1));
    });

    test('feedback ratings map to product language', () {
      expect(RecFeedbackRating.exact.label, 'Exactly as described');
      expect(RecFeedbackRating.mismatch.value, 'mismatch');
      expect(RecFeedbackRating.values, hasLength(4));
    });
  });

  group('FoodList', () {
    test('ListPlace parses the list_places RPC row', () {
      final p = ListPlace.fromJson({
        'entry_id': 'e1',
        'sort_position': 3,
        'note': 'get the tasting menu',
        'id': 'r1',
        'name': 'Nonna Lucia Trattoria',
        'lat': 41.9,
        'lng': 12.5,
        'rec_count': 2,
      });
      expect(p.position, 3);
      expect(p.marker.name, 'Nonna Lucia Trattoria');
    });
  });

  group('MapFilters', () {
    test('isActive reflects any active constraint', () {
      expect(const MapFilters().isActive, isFalse);
      expect(const MapFilters(savedOnly: true).isActive, isTrue);
      expect(const MapFilters(maxPrice: 2).isActive, isTrue);
      expect(const MapFilters(minRecs: 1).isActive, isTrue);
    });

    test('copyWith preserves maxPrice when omitted, clears on explicit null',
        () {
      const f = MapFilters(maxPrice: 2, savedOnly: true);
      final g = f.copyWith(savedOnly: false);
      // Toggling another filter must not wipe the price filter.
      expect(g.maxPrice, 2);
      expect(g.savedOnly, isFalse);
      expect(g.copyWith(maxPrice: null).maxPrice, isNull);
      expect(g.copyWith(maxPrice: 3).maxPrice, 3);
    });
  });

  group('AppNotification', () {
    test('parses and computes unread', () {
      final n = AppNotification.fromJson({
        'id': 'n1',
        'type': 'follow',
        'payload': <String, dynamic>{},
        'created_at': '2026-07-28T00:00:00Z',
        'actor_id': 'u2',
        'read_at': null,
        'profiles': {'username': 'wb_kenji_bites', 'display_name': 'Kenji'},
      });
      expect(n.unread, isTrue);
      expect(n.actorName, 'Kenji');
    });
  });
}
