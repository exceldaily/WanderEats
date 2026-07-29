import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../core/errors/app_exception.dart';
import '../../../core/networking/supabase_provider.dart';
import '../../recommendations/domain/recommendation.dart';
import '../../restaurants/domain/restaurant.dart';
import '../domain/global_area.dart';

class DiscoveryRepository {
  DiscoveryRepository(this._schema);

  final SupabaseQuerySchema _schema;

  Future<List<Map<String, dynamic>>> trendingTasters({int max = 10}) async {
    try {
      final rows = await _schema.rpc<List<dynamic>>(
        'trending_tasters',
        params: {'max_rows': max},
      );
      return rows.cast<Map<String, dynamic>>();
    } on PostgrestException catch (e) {
      throw ServerException(cause: e);
    }
  }

  Future<List<Restaurant>> trendingRestaurants({
    String? citySlug,
    int max = 10,
  }) async {
    try {
      final rows = await _schema.rpc<List<dynamic>>(
        'trending_restaurants',
        params: {'city_slug': ?citySlug, 'max_rows': max},
      );
      return rows
          .cast<Map<String, dynamic>>()
          .map(Restaurant.fromJson)
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(cause: e);
    }
  }

  Future<Map<String, dynamic>> searchAll(String query) async {
    try {
      return await _schema.rpc<Map<String, dynamic>>(
        'search_all',
        params: {'q': query},
      );
    } on PostgrestException catch (e) {
      throw ServerException(cause: e);
    }
  }

  /// Worldwide search for trip planning: areas to travel to, and restaurants
  /// by name anywhere — including places nobody has imported yet.
  ///
  /// Costs a provider call, so callers should only reach for this on an
  /// explicit submit or when [searchAll] came back thin. Failures return empty
  /// rather than throwing: local results are already on screen, and losing the
  /// global extras should never blank out the page.
  Future<GlobalSearchResults> searchGlobal(
    String query, {
    double? nearLat,
    double? nearLng,
  }) async {
    try {
      final res = await Supabase.instance.client.functions.invoke(
        'places-search',
        body: {'query': query, 'lat': ?nearLat, 'lng': ?nearLng},
      );
      final data = res.data;
      if (data is! Map) return const GlobalSearchResults.empty();
      return GlobalSearchResults(
        areas: ((data['areas'] as List?) ?? const [])
            .whereType<Map>()
            .map((m) => GlobalArea.fromJson(m.cast<String, dynamic>()))
            .toList(),
        restaurants: ((data['restaurants'] as List?) ?? const [])
            .whereType<Map>()
            .map((m) => m.cast<String, dynamic>())
            .toList(),
      );
    } catch (_) {
      return const GlobalSearchResults.empty();
    }
  }

  /// Following feed: recent recommendations from people the user follows.
  Future<List<Recommendation>> followingFeed(
    Set<String> followingIds, {
    int limit = 30,
  }) async {
    if (followingIds.isEmpty) return [];
    try {
      final rows = await _schema
          .from('recommendations')
          .select(
            '*, profiles(username, display_name, avatar_url, is_verified), recommendation_photos(storage_path, position)',
          )
          .inFilter('user_id', followingIds.toList())
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false)
          .limit(limit);
      return rows.map(Recommendation.fromJson).toList();
    } on PostgrestException catch (e) {
      throw ServerException(cause: e);
    }
  }
}

final discoveryRepositoryProvider = Provider<DiscoveryRepository>((ref) {
  return DiscoveryRepository(ref.watch(wbSchemaProvider));
});
