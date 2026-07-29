import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../app/configuration/env.dart';
import '../../../app/router/routes.dart';
import '../../../app/theme/wb_tokens.dart';
import '../../../core/location/location_service.dart';
import '../../../core/services/analytics/analytics_service.dart';
import '../../../core/widgets/wb_states.dart';
import '../../restaurants/domain/restaurant.dart';
import '../../restaurants/presentation/restaurant_actions.dart';
import 'map_controller.dart';
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

  // Default camera: over the seeded world; recenters on the user when
  // permission is granted.
  static const _initialCamera = CameraPosition(
    target: LatLng(40.7128, -74.0060),
    zoom: 12,
  );

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

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialCamera,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (c) => _map = c,
            onCameraIdle: _onCameraIdle,
            onTap: (_) => ref.read(mapControllerProvider.notifier).select(null),
            markers: {
              for (final m in visible)
                Marker(
                  markerId: MarkerId(m.id),
                  position: LatLng(m.lat, m.lng),
                  // Color + info window together communicate state so color
                  // is never the only signal.
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    m.id == mapState.selectedId
                        ? BitmapDescriptor.hueYellow
                        : savedIds.contains(m.id)
                        ? BitmapDescriptor.hueRed
                        : visitedIds.contains(m.id)
                        ? BitmapDescriptor.hueViolet
                        : BitmapDescriptor.hueGreen,
                  ),
                  infoWindow: InfoWindow(
                    title: m.name,
                    snippet: [
                      if (savedIds.contains(m.id)) 'Saved',
                      if (visitedIds.contains(m.id)) 'Visited',
                      '${m.recCount} recs',
                    ].join(' · '),
                  ),
                  onTap: () {
                    ref.read(mapControllerProvider.notifier).select(m.id);
                    unawaited(
                      ref
                          .read(analyticsProvider)
                          .markerSelected(restaurantId: m.id),
                    );
                  },
                ),
            },
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
                  MapFilters(
                    maxPrice: v ? price : null,
                    savedOnly: filters.savedOnly,
                    minRecs: filters.minRecs,
                  ),
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
            '${marker.recCount} recommendations',
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
