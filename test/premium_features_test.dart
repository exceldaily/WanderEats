import 'package:flutter_test/flutter_test.dart';
import 'package:wanderbites/features/profile/presentation/widgets/profile_header.dart';
import 'package:wanderbites/features/taste_groups/domain/taste_group_models.dart';
import 'package:wanderbites/features/trips/domain/trip_models.dart';

void main() {
  group('TasteGroup.fromRow', () {
    test('parses a taste_groups_list row', () {
      final g = TasteGroup.fromRow({
        'id': 'g1',
        'name': 'Spice Hunters',
        'description': 'Only the hottest.',
        'emoji': '🌶️',
        'creator_id': 'u1',
        'creator_username': 'somchai',
        'member_count': 4,
        'pick_count': 7,
        'is_member': true,
        'my_role': 'owner',
        'created_at': '2026-08-04T10:00:00Z',
      });
      expect(g.name, 'Spice Hunters');
      expect(g.memberCount, 4);
      expect(g.isMember, isTrue);
      expect(g.isOwner, isTrue);
    });

    test('a non-member row is neither member nor owner', () {
      final g = TasteGroup.fromRow({
        'id': 'g1',
        'name': 'Spice Hunters',
        'creator_id': 'u1',
        'is_member': false,
        'my_role': null,
      });
      expect(g.isMember, isFalse);
      expect(g.isOwner, isFalse);
    });
  });

  group('FoodTrip.fromRow', () {
    test('counts embedded stops', () {
      final t = FoodTrip.fromRow({
        'id': 't1',
        'name': 'Bangkok blowout',
        'destination': 'Bangkok',
        'starts_on': '2026-09-01',
        'food_trip_stops': [
          {'id': 's1'},
          {'id': 's2'},
        ],
      });
      expect(t.stopCount, 2);
      expect(t.startsOn, isNotNull);
    });

    test('survives missing optionals', () {
      final t = FoodTrip.fromRow({'id': 't1', 'name': 'Trip'});
      expect(t.stopCount, 0);
      expect(t.destination, isNull);
      expect(t.startsOn, isNull);
    });
  });

  group('TripStop.fromRow', () {
    test('parses an embedded restaurant', () {
      final s = TripStop.fromRow({
        'id': 's1',
        'note': 'order the khao soi',
        'position': 2,
        'restaurants': {'id': 'r1', 'name': 'Khao Soi Lam Duan'},
      });
      expect(s.restaurantName, 'Khao Soi Lam Duan');
      expect(s.position, 2);
    });
  });

  group('premium banner tokens', () {
    test('premium and standard sets do not overlap', () {
      expect(
        kBannerColors.toSet().intersection(kPremiumBannerColors.toSet()),
        isEmpty,
      );
      expect(
        kBannerDesigns.toSet().intersection(kPremiumBannerDesigns.toSet()),
        isEmpty,
      );
    });

    test('bannerChoiceIsPremium flags either half', () {
      // Mirrors the server''s banner_style_is_premium(); if these sets change,
      // migration 0028''s arrays must change with them.
      expect(bannerChoiceIsPremium('wander', 'voyage'), isTrue);
      expect(bannerChoiceIsPremium('classic', 'aurora'), isTrue);
      expect(bannerChoiceIsPremium('classic', 'voyage'), isFalse);
      for (final c in kPremiumBannerColors) {
        expect(bannerChoiceIsPremium('classic', c), isTrue, reason: c);
      }
      for (final d in kPremiumBannerDesigns) {
        expect(bannerChoiceIsPremium(d, 'voyage'), isTrue, reason: d);
      }
    });

    test('every premium color has a real palette, not the fallback', () {
      final fallback = bannerPalette('definitely_not_a_color');
      for (final c in kPremiumBannerColors) {
        final p = bannerPalette(c);
        expect(
          p.a != fallback.a || p.b != fallback.b,
          isTrue,
          reason: '$c fell through to the default palette',
        );
      }
    });
  });
}
