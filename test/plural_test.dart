import 'package:flutter_test/flutter_test.dart';
import 'package:wanderbites/core/utils/plural.dart';

void main() {
  group('countOf', () {
    test('keeps the noun singular at exactly one', () {
      expect(countOf(1, 'rec'), '1 rec');
      expect(countOf(1, 'recommendation'), '1 recommendation');
      expect(countOf(1, 'save'), '1 save');
    });

    test('pluralises everything else, including zero', () {
      expect(countOf(0, 'rec'), '0 recs');
      expect(countOf(2, 'rec'), '2 recs');
      expect(countOf(17, 'place'), '17 places');
    });

    test('takes an explicit plural for irregular nouns', () {
      expect(countOf(1, 'city', 'cities'), '1 city');
      expect(countOf(4, 'city', 'cities'), '4 cities');
    });
  });

  group('countOfDynamic', () {
    test('accepts the num Postgres hands back', () {
      expect(countOfDynamic(1, 'follower'), '1 follower');
      expect(countOfDynamic(3.0, 'follower'), '3 followers');
    });

    test('treats a missing count as zero rather than throwing', () {
      expect(countOfDynamic(null, 'follower'), '0 followers');
    });
  });
}
