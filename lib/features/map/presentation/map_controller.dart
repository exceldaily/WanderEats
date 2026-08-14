import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../restaurants/data/places_repository.dart';
import '../../restaurants/data/restaurant_repository.dart';
import '../../restaurants/domain/restaurant.dart';
import '../domain/map_lens.dart';

/// Map filters kept deliberately small for Phase 1.
class MapFilters {
  const MapFilters({this.maxPrice, this.savedOnly = false, this.minRecs = 0});

  final int? maxPrice;
  final bool savedOnly;
  final int minRecs;

  static const _unset = Object();

  // Sentinel keeps the nullable maxPrice both preservable (omitted) and
  // clearable (explicit null); the old signature silently wiped it whenever
  // any other filter changed.
  MapFilters copyWith({
    Object? maxPrice = _unset,
    bool? savedOnly,
    int? minRecs,
  }) => MapFilters(
    maxPrice: identical(maxPrice, _unset) ? this.maxPrice : maxPrice as int?,
    savedOnly: savedOnly ?? this.savedOnly,
    minRecs: minRecs ?? this.minRecs,
  );

  bool get isActive => maxPrice != null || savedOnly || minRecs > 0;
}

class MapViewState {
  const MapViewState({
    this.markers = const [],
    this.loading = false,
    this.offline = false,
    this.filters = const MapFilters(),
    this.selectedId,
    this.boundsDirty = false,
    this.importing = false,
    this.lens = MapLens.everything,
  });

  final List<RestaurantMarker> markers;
  final bool loading;

  /// Which map the user is looking at. Changes what is queried, not just what
  /// is drawn.
  final MapLens lens;

  /// True when the markers came from the offline cache.
  final bool offline;
  final MapFilters filters;
  final String? selectedId;

  /// The camera moved since the last query: show "search this area".
  final bool boundsDirty;

  /// Pulling a not-yet-covered area from the external provider.
  final bool importing;

  RestaurantMarker? get selected => selectedId == null
      ? null
      : markers.where((m) => m.id == selectedId).firstOrNull;

  MapViewState copyWith({
    List<RestaurantMarker>? markers,
    bool? loading,
    bool? offline,
    MapFilters? filters,
    String? Function()? selectedId,
    bool? boundsDirty,
    bool? importing,
    MapLens? lens,
  }) => MapViewState(
    markers: markers ?? this.markers,
    loading: loading ?? this.loading,
    offline: offline ?? this.offline,
    filters: filters ?? this.filters,
    selectedId: selectedId != null ? selectedId() : this.selectedId,
    boundsDirty: boundsDirty ?? this.boundsDirty,
    importing: importing ?? this.importing,
    lens: lens ?? this.lens,
  );
}

/// Somewhere the map has been asked to fly to, typically from search.
///
/// Carries an optional provider viewport so a country frames as a country and
/// a neighbourhood frames as a neighbourhood, instead of one guessed zoom.
class MapDestination {
  const MapDestination({
    required this.lat,
    required this.lng,
    required this.label,
    this.neLat,
    this.neLng,
    this.swLat,
    this.swLng,
  });

  final double lat;
  final double lng;
  final String label;
  final double? neLat;
  final double? neLng;
  final double? swLat;
  final double? swLng;

  bool get hasViewport =>
      neLat != null && neLng != null && swLat != null && swLng != null;
}

/// Set by search, consumed once by the map screen then cleared.
class MapDestinationController extends Notifier<MapDestination?> {
  @override
  MapDestination? build() => null;

  void go(MapDestination destination) => state = destination;

  void clear() => state = null;
}

final mapDestinationProvider =
    NotifierProvider<MapDestinationController, MapDestination?>(
      MapDestinationController.new,
    );

final mapControllerProvider = NotifierProvider<MapViewController, MapViewState>(
  MapViewController.new,
);

class MapViewController extends Notifier<MapViewState> {
  Timer? _debounce;
  LatLngBounds? _lastBounds;

  @override
  MapViewState build() {
    ref.onDispose(() => _debounce?.cancel());
    return const MapViewState();
  }

  /// Called on every camera idle. Debounced so panning does not spam the
  /// backend; first load fires immediately.
  void onCameraIdle(LatLngBounds bounds) {
    _lastBounds = bounds;
    if (state.markers.isEmpty && !state.loading) {
      unawaited(_query(bounds));
      return;
    }
    state = state.copyWith(boundsDirty: true);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () {
      final b = _lastBounds;
      if (b != null) unawaited(_query(b));
    });
  }

  Future<void> searchThisArea() async {
    final b = _lastBounds;
    if (b != null) await _query(b);
  }

  Future<void> _query(LatLngBounds bounds) async {
    _debounce?.cancel();
    state = state.copyWith(loading: true);
    try {
      final repo = ref.read(restaurantRepositoryProvider);
      final lens = state.lens;

      // A lens narrows the query itself. The everything-lens keeps the
      // original path because it is the only one that feeds the offline cache
      // and the external-provider import below.
      if (lens != MapLens.everything) {
        final markers = await repo.inBoundsForLens(
          rpc: _rpcForLens(lens),
          minLng: bounds.southwest.longitude,
          minLat: bounds.southwest.latitude,
          maxLng: bounds.northeast.longitude,
          maxLat: bounds.northeast.latitude,
        );
        state = state.copyWith(
          markers: markers,
          loading: false,
          offline: false,
          boundsDirty: false,
        );
        return;
      }

      var markers = await repo.inBounds(
        minLng: bounds.southwest.longitude,
        minLat: bounds.southwest.latitude,
        maxLng: bounds.northeast.longitude,
        maxLat: bounds.northeast.latitude,
      );

      // Paint whatever the database already knows about before deciding
      // whether to import. Previously these markers were held back until the
      // provider call below had finished, so an area that already had places
      // in it still looked empty for the couple of seconds that call takes.
      // Partial results now, more in a moment, beats nothing now.
      state = state.copyWith(
        markers: markers,
        loading: false,
        offline: false,
        boundsDirty: false,
      );

      // Anywhere we have little or no data, pull the area from the external
      // provider once and re-read. This is what makes the map work outside the
      // curated cities; the backend no-ops on tiles it already fetched, so
      // panning over covered ground costs nothing.
      final places = ref.read(placesRepositoryProvider);
      final spanLat = (bounds.northeast.latitude - bounds.southwest.latitude)
          .abs();
      final spanLng = (bounds.northeast.longitude - bounds.southwest.longitude)
          .abs();
      if (places.shouldImport(
        spanLat: spanLat,
        spanLng: spanLng,
        localCount: markers.length,
      )) {
        state = state.copyWith(importing: true);
        // Cover the whole viewport, not just its centre. The provider returns
        // at most 20 places per call, so one call at one point can only ever
        // fill a small patch of what is on screen.
        final imported = await places.ensureCoverageArea(
          minLat: bounds.southwest.latitude,
          maxLat: bounds.northeast.latitude,
          minLng: bounds.southwest.longitude,
          maxLng: bounds.northeast.longitude,
        );
        if (imported > 0) {
          markers = await repo.inBounds(
            minLng: bounds.southwest.longitude,
            minLat: bounds.southwest.latitude,
            maxLng: bounds.northeast.longitude,
            maxLat: bounds.northeast.latitude,
          );
          state = state.copyWith(markers: markers);
        }
        state = state.copyWith(importing: false);
      }
    } catch (_) {
      final cached = await ref
          .read(restaurantRepositoryProvider)
          .cachedMarkers();
      state = state.copyWith(
        markers: cached ?? state.markers,
        loading: false,
        importing: false,
        offline: true,
        boundsDirty: false,
      );
    }
  }

  void select(String? id) {
    state = state.copyWith(selectedId: () => id);
  }

  void setFilters(MapFilters filters) {
    state = state.copyWith(filters: filters);
  }

  /// Switches lens and re-queries the current viewport immediately. A lens
  /// change with a stale marker set on screen would read as a broken control.
  void setLens(MapLens lens) {
    if (lens == state.lens) return;
    state = state.copyWith(lens: lens, selectedId: () => null);
    final bounds = _lastBounds;
    if (bounds != null) unawaited(_query(bounds));
  }

  static String _rpcForLens(MapLens lens) => switch (lens) {
    MapLens.following => 'following_map_markers',
    MapLens.saved => 'saved_map_markers',
    MapLens.visited => 'visited_map_markers',
    MapLens.hiddenGems => 'hidden_gems_in_bounds',
    MapLens.everything => 'restaurants_in_bounds',
  };

  /// Filters applied client-side over the current bounded result set.
  List<RestaurantMarker> visibleMarkers(Set<String> savedIds) {
    final f = state.filters;
    return state.markers.where((m) {
      if (f.maxPrice != null && (m.priceLevel ?? 1) > f.maxPrice!) return false;
      if (f.savedOnly && !savedIds.contains(m.id)) return false;
      if (m.recCount < f.minRecs) return false;
      return true;
    }).toList();
  }
}
