import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../core/errors/app_exception.dart';
import '../../../core/networking/supabase_provider.dart';
import '../../recommendations/domain/recommendation.dart';
import '../../restaurants/domain/restaurant.dart';

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
