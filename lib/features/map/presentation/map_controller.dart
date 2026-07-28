import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../restaurants/data/restaurant_repository.dart';
import '../../restaurants/domain/restaurant.dart';

/// Map filters kept deliberately small for Phase 1.
class MapFilters {
  const MapFilters({this.maxPrice, this.savedOnly = false, this.minRecs = 0});

  final int? maxPrice;
  final bool savedOnly;
  final int minRecs;

  MapFilters copyWith({int? maxPrice, bool? savedOnly, int? minRecs}) =>
      MapFilters(
        maxPrice: maxPrice,
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
  });

  final List<RestaurantMarker> markers;
  final bool loading;

  /// True when the markers came from the offline cache.
  final bool offline;
  final MapFilters filters;
  final String? selectedId;

  /// The camera moved since the last query: show "search this area".
  final bool boundsDirty;

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
  }) =>
      MapViewState(
        markers: markers ?? this.markers,
        loading: loading ?? this.loading,
        offline: offline ?? this.offline,
        filters: filters ?? this.filters,
        selectedId: selectedId != null ? selectedId() : this.selectedId,
        boundsDirty: boundsDirty ?? this.boundsDirty,
      );
}

final mapControllerProvider =
    NotifierProvider<MapViewController, MapViewState>(MapViewController.new);

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
      final markers = await ref.read(restaurantRepositoryProvider).inBounds(
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
    } catch (_) {
      final cached =
          await ref.read(restaurantRepositoryProvider).cachedMarkers();
      state = state.copyWith(
        markers: cached ?? state.markers,
        loading: false,
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
