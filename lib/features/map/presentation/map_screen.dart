import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../app/configuration/env.dart';
import '../../../app/router/routes.dart';
import '../../../app/theme/wb_tokens.dart';
import '../../../core/location/location_service.dart';
import '../../../core/services/analytics/analytics_service.dart';
import '../../../core/utils/plural.dart';
import '../../../core/widgets/wb_states.dart';
import '../../restaurants/domain/restaurant.dart';
import '../../restaurants/presentation/restaurant_actions.dart';
import '../data/map_style_service.dart';
import '../domain/map_clustering.dart';
import '../domain/map_marker_style.dart';
import 'map_controller.dart';
import 'map_marker_layer.dart';
import 'restaurant_preview_card.dart';

/// The product centerpiece: full-screen map, bounded marker queries,
/// draggable restaurant preview, filters, list toggle, offline fallback.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _map;
  bool _listView = false;

  /// Branded pins and cluster bubbles. Created lazily because it needs the
  /// device pixel ratio, which is not available until the first build.
  MapMarkerLayer? _markerLayer;

  /// The marker set currently on the map. Rasterising pins is async, so the
  /// build cannot produce them inline: it renders what is ready and schedules
  /// a rebuild when the next set finishes.
  Set<Marker> _markers = const {};

  /// Guards against an older, slower marker build overwriting a newer one
  /// after a fast pan.
  int _markerGeneration = 0;

  /// Last inputs the marker set was built from, so an unrelated rebuild does
  /// not kick off redundant rasterisation.
  String? _markerSignature;

  /// Camera zoom, kept in sync so clustering can react to it.
  double _zoom = 12;

  static const _clusterer = WbClusterer();

  // Default camera: over the seeded world; recenters on the user when
  // permission is granted.
  static const _initialCamera = CameraPosition(
    target: LatLng(40.7128, -74.0060),
    zoom: 12,
  );

  @override
  void dispose() {
    _markerLayer?.dispose();
    _map?.dispose();
    super.dispose();
  }

  /// Clusters the visible restaurants, rasterises their pins, and swaps the
  /// result in. Cheap on repeat: both the clusterer and the bitmap cache are
  /// keyed so an unchanged view does no work.
  Future<void> _rebuildMarkers({
    required List<RestaurantMarker> visible,
    required Set<String> savedIds,
    required Set<String> visitedIds,
    required String? selectedId,
  }) async {
    final layer = _markerLayer ??= MapMarkerLayer(
      pixelRatio: MediaQuery.devicePixelRatioOf(context),
    );

    WbMarkerKind kindOf(RestaurantMarker m) {
      if (m.id == selectedId) return WbMarkerKind.selected;
      if (savedIds.contains(m.id)) return WbMarkerKind.saved;
      if (visitedIds.contains(m.id)) return WbMarkerKind.visited;
      return WbMarkerKind.standard;
    }

    final items = _clusterer.cluster(
      markers: visible,
      zoom: _zoom,
      kindOf: kindOf,
    );

    final generation = ++_markerGeneration;
    final built = await layer.build(
      items: items,
      onRestaurantTap: (m) {
        ref.read(mapControllerProvider.notifier).select(m.id);
        unawaited(ref.read(analyticsProvider).markerSelected(restaurantId: m.id));
      },
      onClusterTap: (item) => unawaited(_zoomToCluster(item)),
    );

    // A newer build finished first; discard this one rather than regressing
    // the map to an older state.
    if (!mounted || generation != _markerGeneration) return;
    setState(() => _markers = built);
  }

  /// Tapping a cluster flies into it rather than dumping a list: the map is
  /// the interface, so the answer to "what is in here" is a closer look.
  Future<void> _zoomToCluster(WbMapItem item) async {
    final map = _map;
    if (map == null || item.members.isEmpty) return;

    var minLat = item.members.first.lat;
    var maxLat = minLat;
    var minLng = item.members.first.lng;
    var maxLng = minLng;
    for (final m in item.members) {
      minLat = math.min(minLat, m.lat);
      maxLat = math.max(maxLat, m.lat);
      minLng = math.min(minLng, m.lng);
      maxLng = math.max(maxLng, m.lng);
    }

    // Members can sit on the same coordinate (a food hall, a mall). A zero-area
    // bounds throws on Android, so nudge the box open.
    const epsilon = 0.0008;
    if ((maxLat - minLat).abs() < epsilon) {
      minLat -= epsilon;
      maxLat += epsilon;
    }
    if ((maxLng - minLng).abs() < epsilon) {
      minLng -= epsilon;
      maxLng += epsilon;
    }

    unawaited(ref.read(analyticsProvider).mapClusterOpened(count: item.count));
    await map.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        64,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(analyticsProvider).mapOpened());
      unawaited(_goToMyLocation(silent: true));
    });
  }

  Future<void> _goToMyLocation({bool silent = false}) async {
    final pos = await ref.read(locationServiceProvider).currentPosition();
    if (pos == null) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location is off or not allowed. You can still explore the map.',
            ),
          ),
        );
      }
      return;
    }
    await _map?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 13),
    );
  }

  /// Fly to a place chosen in search. Consumes the request so re-entering the
  /// tab later does not yank the camera back.
  Future<void> _goToDestination(MapDestination d) async {
    final map = _map;
    if (map == null) return;
    ref.read(mapDestinationProvider.notifier).clear();

    if (d.hasViewport) {
      await map.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(d.swLat!, d.swLng!),
            northeast: LatLng(d.neLat!, d.neLng!),
          ),
          48,
        ),
      );
    } else {
      await map.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(d.lat, d.lng), 14),
      );
    }
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Exploring ${d.label}')));
    }
  }

  Future<void> _onCameraIdle() async {
    final bounds = await _map?.getVisibleRegion();
    if (bounds != null) {
      ref.read(mapControllerProvider.notifier).onCameraIdle(bounds);
    }
  }

  /// Zoom drives clustering, so track it as the camera moves. Only a change
  /// that crosses a whole zoom step can alter the grouping, which keeps this
  /// from rebuilding markers during every frame of a pinch.
  void _onCameraMove(CameraPosition position) {
    if (position.zoom.floor() == _zoom.floor()) {
      _zoom = position.zoom;
      return;
    }
    setState(() => _zoom = position.zoom);
  }

  @override
  Widget build(BuildContext context) {
    // Search hands the map a place to fly to; act on it once it arrives.
    ref.listen<MapDestination?>(mapDestinationProvider, (_, next) {
      if (next != null) unawaited(_goToDestination(next));
    });

    if (!Env.hasMapsKey) {
      return const Scaffold(
        body: SafeArea(
          child: WbEmptyState(
            icon: Icons.map_outlined,
            title: 'Map needs a Google Maps API key',
            message:
                'Add GOOGLE_MAPS_API_KEY to dart_defines/dev.json and MAPS_API_KEY to android/local.properties, then rebuild. See SETUP.md. Everything else works without it.',
          ),
        ),
      );
    }

    final mapState = ref.watch(mapControllerProvider);
    final savedIds = ref.watch(savedIdsProvider).value ?? {};
    final visitedIds = ref.watch(visitedIdsProvider).value ?? {};
    final visible = ref
        .read(mapControllerProvider.notifier)
        .visibleMarkers(savedIds);

    // Rasterising pins is async, so it cannot happen inline in build(). Kick it
    // off only when something that changes the pins actually changed.
    final signature = [
      visible.map((m) => m.id).join(','),
      savedIds.length,
      visitedIds.length,
      mapState.selectedId,
      _zoom.floor(),
    ].join('|');
    if (signature != _markerSignature) {
      _markerSignature = signature;
      unawaited(
        _rebuildMarkers(
          visible: visible,
          savedIds: savedIds,
          visitedIds: visitedIds,
          selectedId: mapState.selectedId,
        ),
      );
    }

    final style = ref
        .watch(mapStyleProvider(Theme.of(context).brightness))
        .value;

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialCamera,
            // The WanderBites basemap: warm, decluttered, and dark-aware, so
            // the app's own content is the brightest thing on screen.
            style: style,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (c) => _map = c,
            onCameraIdle: _onCameraIdle,
            onCameraMove: _onCameraMove,
            onTap: (_) => ref.read(mapControllerProvider.notifier).select(null),
            markers: _markers,
          ),

          // Top controls
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(WbSpacing.sm),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _FilterBar()),
                      const SizedBox(width: WbSpacing.sm),
                      _RoundButton(
                        icon: Icons.style_outlined,
                        tooltip: 'BiteSwipe',
                        onTap: () {
                          unawaited(
                            ref.read(analyticsProvider).deckOpened(from: 'map'),
                          );
                          context.pushNamed(Routes.biteswipe);
                        },
                      ),
                      const SizedBox(width: WbSpacing.sm),
                      _RoundButton(
                        icon: _listView ? Icons.map_outlined : Icons.list,
                        tooltip: _listView ? 'Map view' : 'List view',
                        onTap: () => setState(() => _listView = !_listView),
                      ),
                    ],
                  ),
                  if (mapState.offline)
                    Padding(
                      padding: const EdgeInsets.only(top: WbSpacing.sm),
                      child: Material(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(WbRadius.chip),
                        child: const Padding(
                          padding: EdgeInsets.all(WbSpacing.sm),
                          child: Text(
                            'Offline: showing your last loaded places',
                          ),
                        ),
                      ),
                    ),
                  if (mapState.boundsDirty && !mapState.loading)
                    Padding(
                      padding: const EdgeInsets.only(top: WbSpacing.sm),
                      child: FilledButton.tonalIcon(
                        onPressed: () => ref
                            .read(mapControllerProvider.notifier)
                            .searchThisArea(),
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Search this area'),
                      ),
                    ),
                  if (mapState.loading)
                    const Padding(
                      padding: EdgeInsets.only(top: WbSpacing.sm),
                      child: LinearProgressIndicator(minHeight: 3),
                    ),
                  // Importing means a live provider lookup for an area nobody
                  // has opened before, which takes a second or two. Without
                  // saying so, the pause reads as the app being broken rather
                  // than busy. Any places we already had are on screen by now.
                  if (mapState.importing)
                    Padding(
                      padding: const EdgeInsets.only(top: WbSpacing.sm),
                      child: Material(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(WbRadius.chip),
                        child: const Padding(
                          padding: EdgeInsets.all(WbSpacing.sm),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: WbSpacing.sm),
                              Text('Exploring this area for the first time...'),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Bottom-right: locate me
          Positioned(
            right: WbSpacing.md,
            bottom: mapState.selected != null ? 240 : WbSpacing.xl,
            child: _RoundButton(
              icon: Icons.my_location,
              tooltip: 'My location',
              onTap: _goToMyLocation,
            ),
          ),

          // List view overlay
          if (_listView)
            Positioned.fill(
              child: SafeArea(
                child: Container(
                  margin: const EdgeInsets.only(top: 64),
                  color: Theme.of(context).colorScheme.surface,
                  child: visible.isEmpty
                      ? const WbEmptyState(
                          icon: Icons.restaurant_outlined,
                          title: 'No places here yet',
                          message: 'Pan the map or loosen the filters.',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(WbSpacing.md),
                          itemCount: visible.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: WbSpacing.sm),
                          itemBuilder: (context, i) => _ListRow(
                            marker: visible[i],
                            saved: savedIds.contains(visible[i].id),
                            onTap: () => context.pushNamed(
                              Routes.restaurant,
                              pathParameters: {'id': visible[i].id},
                            ),
                          ),
                        ),
                ),
              ),
            ),

          // Draggable preview card
          if (mapState.selected != null && !_listView)
            RestaurantPreviewCard(
              marker: mapState.selected!,
              onClose: () =>
                  ref.read(mapControllerProvider.notifier).select(null),
            ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: const CircleBorder(),
      elevation: WbElevation.raisedCard,
      child: IconButton(tooltip: tooltip, icon: Icon(icon), onPressed: onTap),
    );
  }
}

class _FilterBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(mapControllerProvider).filters;
    final notifier = ref.read(mapControllerProvider.notifier);
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          FilterChip(
            label: const Text('Saved'),
            avatar: const Icon(Icons.bookmark, size: 16),
            selected: filters.savedOnly,
            onSelected: (v) =>
                notifier.setFilters(filters.copyWith(savedOnly: v)),
          ),
          const SizedBox(width: WbSpacing.sm),
          FilterChip(
            label: const Text('Recommended'),
            // Not a thumbs-up: this filters to places Tasters vouched for.
            // A thumb reads as "like this", which is an action, not a filter.
            avatar: const Icon(Icons.people_outline, size: 16),
            selected: filters.minRecs > 0,
            onSelected: (v) =>
                notifier.setFilters(filters.copyWith(minRecs: v ? 1 : 0)),
          ),
          const SizedBox(width: WbSpacing.sm),
          for (final price in [1, 2, 3])
            Padding(
              padding: const EdgeInsets.only(right: WbSpacing.sm),
              child: FilterChip(
                label: Text('${'\$' * price} max'),
                selected: filters.maxPrice == price,
                onSelected: (v) => notifier.setFilters(
                  filters.copyWith(maxPrice: v ? price : null),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ListRow extends StatelessWidget {
  const _ListRow({
    required this.marker,
    required this.saved,
    required this.onTap,
  });

  final RestaurantMarker marker;
  final bool saved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          child: const Icon(Icons.restaurant),
        ),
        title: Text(
          marker.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          [
            if (marker.priceLevel != null) '\$' * marker.priceLevel!,
            countOf(marker.recCount, 'recommendation'),
            if (marker.score != null) '${marker.score!.toStringAsFixed(1)}/10',
          ].join(' · '),
        ),
        trailing: saved
            ? const Icon(Icons.bookmark, color: WbColors.ember)
            : const Icon(Icons.chevron_right),
      ),
    );
  }
}
