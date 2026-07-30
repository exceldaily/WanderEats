import 'package:flutter_test/flutter_test.dart';
import 'package:wanderbites/features/monetization/data/conversion_repository.dart';
import 'package:wanderbites/features/monetization/domain/action_context.dart';

void main() {
  group('buildConversionRow', () {
    test('always carries what the dashboard groups by', () {
      final row = buildConversionRow(
        restaurantId: 'r1',
        action: RestaurantAction.directions,
        context: const ActionContext(source: ActionSource.map),
      );
      expect(row['restaurant_id'], 'r1');
      expect(row['action_type'], 'directions');
      expect(row['source_screen'], 'map');
    });

    test('threads the attribution chain when it is known', () {
      final row = buildConversionRow(
        restaurantId: 'r1',
        action: RestaurantAction.reservation,
        context: const ActionContext(
          source: ActionSource.list,
          sourceFeature: 'list_map_view',
          tasterId: 't1',
          recommendationId: 'rec1',
          listId: 'l1',
          cityId: 'c1',
        ),
        provider: 'opentable',
        destination: 'https://example.com/book',
      );
      expect(row['taster_id'], 't1');
      expect(row['recommendation_id'], 'rec1');
      expect(row['list_id'], 'l1');
      expect(row['city_id'], 'c1');
      expect(row['source_feature'], 'list_map_view');
      expect(row['provider'], 'opentable');
      expect(row['destination'], 'https://example.com/book');
    });

    test('omits unknown attribution instead of writing nulls', () {
      final row = buildConversionRow(
        restaurantId: 'r1',
        action: RestaurantAction.website,
        context: const ActionContext(source: ActionSource.search),
      );
      for (final absent in [
        'taster_id',
        'recommendation_id',
        'list_id',
        'city_id',
        'user_id',
        'provider',
        'metadata',
      ]) {
        expect(row.containsKey(absent), isFalse, reason: absent);
      }
    });

    test('records signed-out actions without a user id', () {
      final row = buildConversionRow(
        restaurantId: 'r1',
        action: RestaurantAction.directions,
        context: const ActionContext(source: ActionSource.map),
        anonymousSessionId: 'anon-123',
      );
      expect(row.containsKey('user_id'), isFalse);
      expect(row['anonymous_session_id'], 'anon-123');
    });

    test('BiteSwipe is distinguishable from the map', () {
      expect(ActionSource.biteSwipe.wire, 'taste_deck');
      expect(ActionSource.map.wire, 'map');
    });
  });

  group('wire values are stable', () {
    // Historical rows must stay comparable, so these strings are part of the
    // data contract rather than an implementation detail.
    test('actions', () {
      expect(RestaurantAction.orderDelivery.wire, 'order_delivery');
      expect(RestaurantAction.markedVisited.wire, 'restaurant_marked_visited');
      expect(RestaurantAction.bookExperience.wire, 'book_experience');
    });

    test('sources', () {
      expect(ActionSource.restaurantPage.wire, 'restaurant_page');
      expect(ActionSource.tasterProfile.wire, 'taster_profile');
    });
  });
}
