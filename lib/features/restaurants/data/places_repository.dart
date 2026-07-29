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
