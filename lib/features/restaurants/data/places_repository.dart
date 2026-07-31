import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/configuration/env.dart';

/// Fills sparse map areas with restaurants from the external provider.
///
/// The provider key lives only in the `places-nearby` edge function, so the app
/// never holds it. That function is also the thing that decides whether a tile
/// is stale enough to justify a paid provider call, so the client is free to
/// ask optimistically — a warm tile costs nothing.
class PlacesRepository {
  PlacesRepository(this._client);

  final SupabaseClient _client;

  /// Widest viewport (in degrees) still worth importing for. Panning around a
  /// whole continent should not trigger imports: the results would be a
  /// meaningless 20 restaurants dropped in the middle of nowhere.
  static const double maxSpanDegrees = 0.35;

  /// Below this many local results an area counts as "not covered yet".
  static const int sparseThreshold = 8;

  bool shouldImport({
    required double spanLat,
    required double spanLng,
    required int localCount,
  }) =>
      localCount < sparseThreshold &&
      spanLat <= maxSpanDegrees &&
      spanLng <= maxSpanDegrees;

  /// Asks the backend to make sure this point has provider coverage.
  /// Returns how many restaurants were newly imported (0 when already cached).
  Future<int> ensureCoverage({
    required double lat,
    required double lng,
    double radiusMeters = 1500,
  }) async {
    final res = await _client.functions.invoke(
      'places-nearby',
      body: {'lat': lat, 'lng': lng, 'radius': radiusMeters},
    );
    final data = res.data;
    if (data is Map && data['imported'] is int) return data['imported'] as int;
    return 0;
  }

  /// How many sample points to spread across the viewport, per axis.
  ///
  /// The provider caps a nearby search at 20 results per call, so a single
  /// call can only ever describe a small patch however large a radius it is
  /// given. Covering what someone is actually looking at therefore means
  /// several calls at different centres, and this is the cap on that: a 3x3
  /// grid, so at most nine, and usually far fewer because the backend skips
  /// any tile it has already fetched.
  static const int gridPerAxis = 3;

  /// Covers a whole viewport rather than a single point at its centre.
  ///
  /// Previously only the centre was requested, with a fixed 1.5km radius. Any
  /// viewport wider than about 3km therefore had most of its area left
  /// untouched, which is why places appeared in one tight cluster and why
  /// pressing "search this area" repeatedly slowly filled things in: each
  /// press happened to land on a slightly different centre.
  ///
  /// Calls run concurrently, so nine of them cost about the same wall-clock
  /// time as one. Cost stays bounded because the backend consults its tile
  /// cache per point and does no provider work for ground it already covered.
  Future<int> ensureCoverageArea({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
  }) async {
    final spanLat = (maxLat - minLat).abs();
    final spanLng = (maxLng - minLng).abs();

    // Radius is sized so neighbouring circles in the grid overlap slightly
    // rather than leaving unsearched gaps between them.
    final stepLat = spanLat / gridPerAxis;
    final stepLng = spanLng / gridPerAxis;
    final midLat = (minLat + maxLat) / 2;
    final metresPerDegLng = 111320 * math.cos(midLat * math.pi / 180).abs();
    final stepMetres = math.max(
      stepLat * 111320,
      stepLng * math.max(metresPerDegLng, 1),
    );
    final radius = (stepMetres * 0.75).clamp(500.0, 50000.0);

    final points = <({double lat, double lng})>[];
    for (var i = 0; i < gridPerAxis; i++) {
      for (var j = 0; j < gridPerAxis; j++) {
        points.add((
          lat: minLat + stepLat * (i + 0.5),
          lng: minLng + stepLng * (j + 0.5),
        ));
      }
    }

    final results = await Future.wait(
      points.map(
        (p) => ensureCoverage(
          lat: p.lat,
          lng: p.lng,
          radiusMeters: radius,
        ).catchError((_) => 0),
      ),
    );
    return results.fold<int>(0, (a, b) => a + b);
  }
}

final placesRepositoryProvider = Provider<PlacesRepository>(
  (ref) => PlacesRepository(Supabase.instance.client),
);

/// Resolves a stored cover photo value to something [Image.network] can load.
///
/// Provider imports store a photo *resource name* ("places/X/photos/Y") rather
/// than a URL, because the real media URL has to carry the provider key. Those
/// are served through the `place-photo` edge function; seeded rows already hold
/// ordinary URLs and pass through untouched.
String? resolvePhotoUrl(String? stored) {
  if (stored == null || stored.isEmpty) return null;
  if (stored.startsWith('http')) return stored;
  if (!stored.startsWith('places/')) return null;
  return '${Env.supabaseUrl}/functions/v1/place-photo'
      '?ref=${Uri.encodeComponent(stored)}&w=800';
}
