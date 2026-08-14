import 'package:flutter_test/flutter_test.dart';
import 'package:wanderbites/features/map/domain/map_lens.dart';

void main() {
  group('MapLens', () {
    test('only the everything lens works signed out', () {
      expect(MapLens.everything.requiresAccount, isFalse);
      for (final lens in MapLens.values.where((l) => l != MapLens.everything)) {
        expect(
          lens.requiresAccount,
          isTrue,
          reason: '${lens.name} reads from the signed-in user',
        );
      }
    });

    test('every lens carries its own empty-state copy', () {
      // A shared "no results" message would be useless: the reason a Following
      // map is empty is nothing like the reason Hidden Gems is.
      final titles = MapLens.values.map((l) => l.emptyTitle).toSet();
      final messages = MapLens.values.map((l) => l.emptyMessage).toSet();
      expect(titles, hasLength(MapLens.values.length));
      expect(messages, hasLength(MapLens.values.length));
      for (final lens in MapLens.values) {
        expect(lens.emptyMessage, isNotEmpty);
        expect(lens.label, isNotEmpty);
        expect(lens.description, isNotEmpty);
      }
    });

    test('everything is the default and is listed first', () {
      expect(MapLens.values.first, MapLens.everything);
    });
  });
}
