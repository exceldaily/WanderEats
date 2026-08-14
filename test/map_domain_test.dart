import 'package:flutter_test/flutter_test.dart';
import 'package:wanderbites/features/map/domain/map_bounds.dart';
import 'package:wanderbites/features/map/domain/map_clustering.dart';
import 'package:wanderbites/features/map/domain/map_marker_style.dart';
import 'package:wanderbites/features/restaurants/domain/restaurant.dart';

RestaurantMarker _marker(String id, double lat, double lng, {int recs = 0}) =>
    RestaurantMarker(id: id, name: id, lat: lat, lng: lng, recCount: recs);

void main() {
  group('WbBounds', () {
    test('spans and centre are plain arithmetic away from the antimeridian', () {
      const b = WbBounds(minLat: 10, minLng: 20, maxLat: 20, maxLng: 40);
      expect(b.crossesAntimeridian, isFalse);
      expect(b.spanLat, 10);
      expect(b.spanLng, 20);
      expect(b.centerLng, 30);
      expect(b.split(), [b]);
    });

    test('a viewport wrapping 180 splits into two queryable halves', () {
      // Fiji: west edge east of the east edge.
      const b = WbBounds(minLat: -20, minLng: 170, maxLat: -15, maxLng: -175);
      expect(b.crossesAntimeridian, isTrue);
      expect(b.spanLng, 15);
      expect(b.centerLng, closeTo(177.5, 1e-9));

      final parts = b.split();
      expect(parts, hasLength(2));
      expect(parts[0].maxLng, 180);
      expect(parts[1].minLng, -180);
      // Neither half wraps, so each is a valid envelope for PostGIS.
      expect(parts.every((p) => !p.crossesAntimeridian), isTrue);
    });

    test('padding grows every edge but never escapes the poles', () {
      const b = WbBounds(minLat: -89, minLng: -10, maxLat: 89, maxLng: 10);
      final padded = b.padded(0.5);
      expect(padded.minLat, -90);
      expect(padded.maxLat, 90);
      expect(padded.minLng, -20);
      expect(padded.maxLng, 20);
    });

    test('contains recognises a camera move that stayed inside', () {
      const outer = WbBounds(minLat: 0, minLng: 0, maxLat: 10, maxLng: 10);
      const inner = WbBounds(minLat: 2, minLng: 2, maxLat: 8, maxLng: 8);
      expect(outer.contains(inner), isTrue);
      expect(inner.contains(outer), isFalse);
    });
  });

  group('WbMarkerSpec', () {
    test('identical-looking pins share a cache key', () {
      const a = WbMarkerSpec(kind: WbMarkerKind.saved, recCount: 3);
      const b = WbMarkerSpec(kind: WbMarkerKind.saved, recCount: 3);
      expect(a.cacheKey, b.cacheKey);
    });

    test('different states never collide', () {
      const saved = WbMarkerSpec(kind: WbMarkerKind.saved);
      const visited = WbMarkerSpec(kind: WbMarkerKind.visited);
      expect(saved.cacheKey, isNot(visited.cacheKey));
    });

    test('nearby cluster sizes bucket together, distant ones do not', () {
      const a = WbMarkerSpec(kind: WbMarkerKind.standard, clusterCount: 41);
      const b = WbMarkerSpec(kind: WbMarkerKind.standard, clusterCount: 44);
      const c = WbMarkerSpec(kind: WbMarkerKind.standard, clusterCount: 7);
      expect(a.cacheKey, b.cacheKey);
      expect(a.cacheKey, isNot(c.cacheKey));
      expect(a.isCluster, isTrue);
      expect(const WbMarkerSpec(kind: WbMarkerKind.standard).isCluster, isFalse);
    });

    test('priority runs selection first, generic pins last', () {
      expect(
        WbMarkerKind.selected.priority,
        lessThan(WbMarkerKind.followedTaster.priority),
      );
      expect(
        WbMarkerKind.saved.priority,
        lessThan(WbMarkerKind.standard.priority),
      );
    });
  });

  group('WbClusterer', () {
    const clusterer = WbClusterer();
    WbMarkerKind plain(RestaurantMarker _) => WbMarkerKind.standard;

    test('street zoom shows every restaurant individually', () {
      final markers = [
        _marker('a', 13.7563, 100.5018),
        _marker('b', 13.7564, 100.5019),
        _marker('c', 13.7565, 100.5020),
      ];
      final items = clusterer.cluster(markers: markers, zoom: 17, kindOf: plain);
      expect(items, hasLength(3));
      expect(items.every((i) => !i.isCluster), isTrue);
    });

    test('city zoom groups neighbours and leaves distant places alone', () {
      final markers = [
        // Three within a few metres of each other in Bangkok.
        _marker('a', 13.7563, 100.5018),
        _marker('b', 13.7564, 100.5019),
        _marker('c', 13.7565, 100.5020),
        // One in Tokyo, which must never join them.
        _marker('far', 35.6762, 139.6503),
      ];
      final items = clusterer.cluster(markers: markers, zoom: 11, kindOf: plain);

      final clusters = items.where((i) => i.isCluster).toList();
      expect(clusters, hasLength(1));
      expect(clusters.single.count, 3);
      expect(items.where((i) => !i.isCluster).single.marker!.id, 'far');
    });

    test('a saved place is promoted out of its cluster, never hidden in it', () {
      final markers = [
        _marker('saved', 13.7563, 100.5018),
        _marker('x', 13.7564, 100.5019),
        _marker('y', 13.7565, 100.5020),
        _marker('z', 13.7566, 100.5021),
      ];
      WbMarkerKind kindOf(RestaurantMarker m) =>
          m.id == 'saved' ? WbMarkerKind.saved : WbMarkerKind.standard;

      final items = clusterer.cluster(markers: markers, zoom: 11, kindOf: kindOf);
      final singles = items.where((i) => !i.isCluster).toList();

      expect(singles.map((i) => i.marker!.id), contains('saved'));
      expect(singles.single.kind, WbMarkerKind.saved);
      // The rest still collapse, so promotion does not undo clustering.
      expect(items.where((i) => i.isCluster).single.count, 3);
    });

    test('cluster centroid sits among its members', () {
      final markers = [
        _marker('a', 10, 20),
        _marker('b', 10.0002, 20.0002),
      ];
      final cluster = clusterer
          .cluster(markers: markers, zoom: 8, kindOf: plain)
          .single;
      expect(cluster.isCluster, isTrue);
      expect(cluster.latitude, closeTo(10.0001, 1e-6));
      expect(cluster.longitude, closeTo(20.0001, 1e-6));
    });

    test('empty input produces nothing rather than throwing', () {
      expect(clusterer.cluster(markers: [], zoom: 12, kindOf: plain), isEmpty);
    });
  });
}
