import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../restaurants/domain/restaurant.dart';
import '../domain/map_clustering.dart';
import '../domain/map_marker_style.dart';
import 'marker_painter.dart';

/// Turns restaurant rows into the SDK's marker set.
///
/// This is the only place where WanderBites map models meet
/// google_maps_flutter types. Everything upstream - clustering, priority,
/// pin appearance - is provider-agnostic, so swapping the renderer means
/// rewriting this file and nothing else.
class MapMarkerLayer {
  MapMarkerLayer({required double pixelRatio})
    : _painter = WbMarkerPainter(pixelRatio: pixelRatio);

  final WbMarkerPainter _painter;
  final Map<String, BitmapDescriptor> _descriptors = {};

  void dispose() {
    _painter.dispose();
    _descriptors.clear();
  }

  /// Builds markers for [items].
  ///
  /// Bitmaps are cached by spec, so a pan that changes positions but not
  /// states costs no rasterisation at all.
  Future<Set<Marker>> build({
    required List<WbMapItem> items,
    required void Function(RestaurantMarker) onRestaurantTap,
    required void Function(WbMapItem) onClusterTap,
  }) async {
    final markers = <Marker>{};
    for (final item in items) {
      final icon = await _descriptorFor(item.spec);
      markers.add(
        Marker(
          markerId: MarkerId(item.id),
          position: LatLng(item.latitude, item.longitude),
          icon: icon,
          // Anchor at the stem tip for pins so they point at the place;
          // clusters are centred on their own centroid.
          anchor: item.isCluster ? const Offset(0.5, 0.5) : const Offset(0.5, 0.92),
          zIndexInt: item.isCluster ? 0 : (10 - item.spec.kind.priority),
          consumeTapEvents: true,
          onTap: () {
            if (item.isCluster) {
              onClusterTap(item);
            } else {
              onRestaurantTap(item.marker!);
            }
          },
          // Screen readers get the same information the pin conveys visually.
          infoWindow: InfoWindow(title: _semanticLabel(item)),
        ),
      );
    }
    return markers;
  }

  Future<BitmapDescriptor> _descriptorFor(WbMarkerSpec spec) async {
    final cached = _descriptors[spec.cacheKey];
    if (cached != null) return cached;

    final image = await _painter.image(spec);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final descriptor = data == null
        ? BitmapDescriptor.defaultMarker
        : BitmapDescriptor.bytes(
            data.buffer.asUint8List(),
            imagePixelRatio: _painter.pixelRatio,
          );
    _descriptors[spec.cacheKey] = descriptor;
    return descriptor;
  }

  String _semanticLabel(WbMapItem item) {
    if (item.isCluster) return '${item.count} restaurants in this area';
    final marker = item.marker!;
    final state = switch (item.kind) {
      WbMarkerKind.followedTaster => 'Recommended by someone you follow',
      WbMarkerKind.saved => 'Saved',
      WbMarkerKind.visited => 'Visited',
      WbMarkerKind.trending => 'Trending',
      WbMarkerKind.hiddenGem => 'Hidden gem',
      WbMarkerKind.selected || WbMarkerKind.standard => null,
    };
    return state == null ? marker.name : '${marker.name} · $state';
  }
}
