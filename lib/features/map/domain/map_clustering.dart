import 'dart:math' as math;

import '../../restaurants/domain/restaurant.dart';
import 'map_marker_style.dart';

/// One thing drawn on the map: either a single restaurant or a group of them.
class WbMapItem {
  const WbMapItem.single(RestaurantMarker this.marker, {required this.kind})
    : members = const [],
      lat = 0,
      lng = 0;

  WbMapItem.cluster(this.members, this.lat, this.lng)
    : marker = null,
      kind = WbMarkerKind.standard;

  final RestaurantMarker? marker;
  final List<RestaurantMarker> members;
  final WbMarkerKind kind;
  final double lat;
  final double lng;

  bool get isCluster => marker == null;
  int get count => isCluster ? members.length : 1;
  double get latitude => isCluster ? lat : marker!.lat;
  double get longitude => isCluster ? lng : marker!.lng;

  /// Stable id so the map can diff item sets between frames instead of
  /// tearing every marker down and rebuilding it.
  String get id => isCluster
      ? 'cl_${lat.toStringAsFixed(4)}_${lng.toStringAsFixed(4)}_${members.length}'
      : marker!.id;

  WbMarkerSpec get spec => isCluster
      ? WbMarkerSpec(kind: WbMarkerKind.standard, clusterCount: members.length)
      : WbMarkerSpec(kind: kind, recCount: marker!.recCount);
}

/// Grid clustering over screen space.
///
/// Clustering in pixels rather than degrees is what keeps cell size constant
/// as you zoom, and stops longitude cells from collapsing near the poles. The
/// projection here is Web Mercator, matching what the map itself draws.
///
/// Deliberately not a quadtree: at the query cap of a few hundred markers a
/// single pass over a hash map is faster than building a tree, and it is far
/// easier to reason about.
class WbClusterer {
  const WbClusterer({this.cellPixels = 88, this.disableAtZoom = 16});

  /// Cluster cell size in screen pixels. Roughly two pin widths, so pins stop
  /// merging once they would no longer overlap.
  final double cellPixels;

  /// Above this zoom every restaurant stands alone: at street level the user
  /// is choosing between specific places, and a bubble would hide the answer.
  final double disableAtZoom;

  List<WbMapItem> cluster({
    required List<RestaurantMarker> markers,
    required double zoom,
    required WbMarkerKind Function(RestaurantMarker) kindOf,
  }) {
    if (markers.isEmpty) return const [];
    if (zoom >= disableAtZoom) {
      return [
        for (final m in markers) WbMapItem.single(m, kind: kindOf(m)),
      ];
    }

    final scale = math.pow(2, zoom).toDouble() * 256 / cellPixels;
    final buckets = <int, List<RestaurantMarker>>{};

    for (final m in markers) {
      final x = ((m.lng + 180) / 360 * scale).floor();
      final y = (_mercatorY(m.lat) * scale).floor();
      // Pack the cell coordinates into one int key; y is bounded by the
      // projection so 20 bits of shift never collides in practice.
      buckets.putIfAbsent((x << 20) ^ y, () => []).add(m);
    }

    final items = <WbMapItem>[];
    for (final group in buckets.values) {
      if (group.length == 1) {
        items.add(WbMapItem.single(group.first, kind: kindOf(group.first)));
        continue;
      }
      // A cluster that contains something the user cares about should not
      // hide it - promote the single highest-priority member and cluster the
      // rest, so a saved place never vanishes into a grey bubble.
      group.sort((a, b) => kindOf(a).priority.compareTo(kindOf(b).priority));
      final lead = group.first;
      if (kindOf(lead).priority < WbMarkerKind.trending.priority) {
        items.add(WbMapItem.single(lead, kind: kindOf(lead)));
        final rest = group.sublist(1);
        if (rest.length == 1) {
          items.add(WbMapItem.single(rest.first, kind: kindOf(rest.first)));
        } else {
          items.add(_centroid(rest));
        }
      } else {
        items.add(_centroid(group));
      }
    }
    return items;
  }

  WbMapItem _centroid(List<RestaurantMarker> group) {
    var lat = 0.0;
    var lng = 0.0;
    for (final m in group) {
      lat += m.lat;
      lng += m.lng;
    }
    return WbMapItem.cluster(group, lat / group.length, lng / group.length);
  }

  /// Normalised Web Mercator Y in 0..1. Clamped short of the poles, where the
  /// projection runs to infinity.
  static double _mercatorY(double lat) {
    final clamped = lat.clamp(-85.05112878, 85.05112878);
    final s = math.sin(clamped * math.pi / 180);
    return 0.5 - math.log((1 + s) / (1 - s)) / (4 * math.pi);
  }
}
