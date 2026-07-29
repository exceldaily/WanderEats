import 'package:flutter_test/flutter_test.dart';
import 'package:wanderbites/features/biteswipe/domain/swipe_card.dart';
import 'package:wanderbites/features/biteswipe/presentation/biteswipe_controller.dart';

void main() {
  group('SwipeCard', () {
    test('parses a ranked row from the taste_deck function', () {
      final card = SwipeCard.fromJson({
        'id': 'r1',
        'name': 'Midnight Slice',
        'lat': 40.7,
        'lng': -74.0,
        'price_level': 2,
        'distance_m': 1395.2,
        'score': '8.40',
        'rec_count': 2,
        'save_count': 4,
        'cover_photo_url': 'places/abc/photos/def',
        'city_name': 'New York',
        'reason': 'Matches cuisines you like',
        'via_taster_id': 't1',
        'rank_score': '52.712',
      });
      expect(card.name, 'Midnight Slice');
      expect(card.priceLabel, r'$$');
      expect(card.distanceLabel, '1.4 km');
      expect(card.reason, 'Matches cuisines you like');
      expect(card.viaTasterId, 't1');
      expect(card.subtitle, contains('New York'));
    });

    test('tolerates missing optionals', () {
      final card = SwipeCard.fromJson({
        'id': 'r2',
        'name': 'Somewhere',
        'lat': 1.0,
        'lng': 2.0,
        'reason': 'New nearby',
      });
      expect(card.priceLabel, '');
      expect(card.distanceLabel, '');
      expect(card.subtitle, '');
      expect(card.recCount, 0);
    });

    test('meters format under a kilometre', () {
      final card = SwipeCard.fromJson({
        'id': 'r3',
        'name': 'Close',
        'lat': 0.0,
        'lng': 0.0,
        'reason': 'Nearby',
        'distance_m': 240.0,
      });
      expect(card.distanceLabel, '240 m');
    });
  });

  group('BiteSwipeState', () {
    SwipeCard card(String id) => SwipeCard(
      id: id,
      name: id,
      lat: 0,
      lng: 0,
      reason: 'Nearby',
    );

    test('walks the deck: current, next, finished, remaining', () {
      var state = BiteSwipeState(
        cards: [card('a'), card('b')],
        loading: false,
      );
      expect(state.current!.id, 'a');
      expect(state.next!.id, 'b');
      expect(state.finished, isFalse);
      expect(state.remaining, 2);

      state = state.copyWith(index: 1);
      expect(state.current!.id, 'b');
      expect(state.next, isNull);
      expect(state.remaining, 1);

      state = state.copyWith(index: 2);
      expect(state.current, isNull);
      expect(state.finished, isTrue);
      expect(state.remaining, 0);
    });

    test('empty deck that finished loading counts as finished', () {
      const state = BiteSwipeState(loading: false);
      expect(state.finished, isTrue);
      expect(state.current, isNull);
    });

    test('is not finished while loading or errored', () {
      const loading = BiteSwipeState();
      expect(loading.finished, isFalse);
      final errored = const BiteSwipeState().copyWith(
        loading: false,
        error: () => 'boom',
      );
      expect(errored.finished, isFalse);
    });
  });

  group('BiteSwipeFilters', () {
    test('defaults are inactive; any change activates', () {
      const def = BiteSwipeFilters();
      expect(def.isActive, isFalse);
      expect(def.copyWith(radiusM: 5000).isActive, isTrue);
      expect(def.copyWith(maxPrice: () => 2).isActive, isTrue);
    });

    test('copyWith can clear nullable fields', () {
      const f = BiteSwipeFilters(maxPrice: 2);
      final cleared = f.copyWith(maxPrice: () => null);
      expect(cleared.maxPrice, isNull);
      expect(cleared.isActive, isFalse);
    });
  });

  group('SkipReason', () {
    test('wire values match the database check constraint', () {
      expect(
        SkipReason.values.map((r) => r.wire),
        containsAll(['too_far', 'too_expensive', 'cuisine', 'visited', 'not_now']),
      );
    });
  });
}
