import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../core/errors/app_exception.dart';
import '../../../core/networking/supabase_provider.dart';
import '../domain/restaurant.dart';

/// Restaurant reads/writes. Map queries always go through the bounded RPCs,
/// never a full-table select. The last bounds result is cached locally as the
/// offline fallback for the map.
class RestaurantRepository {
  RestaurantRepository(this._schema);

  final SupabaseQuerySchema _schema;

  static const _markerCacheKey = 'wb_last_markers_v1';

  Future<List<RestaurantMarker>> inBounds({
    required double minLng,
    required double minLat,
    required double maxLng,
    required double maxLat,
    int maxRows = 200,
  }) async {
    try {
      final rows = await _schema.rpc<List<dynamic>>('restaurants_in_bounds', params: {
        'min_lng': minLng,
        'min_lat': minLat,
        'max_lng': maxLng,
        'max_lat': maxLat,
        'max_rows': maxRows,
      });
      final markers = rows
          .cast<Map<String, dynamic>>()
          .map(RestaurantMarker.fromJson)
          .toList();
      await _cacheMarkers(markers);
      return markers;
    } on PostgrestException catch (e) {
      throw ServerException(cause: e);
    } catch (e) {
      // Network down: serve the offline cache when we have one.
      final cached = await cachedMarkers();
      if (cached != null) return cached;
      throw NetworkException(cause: e);
    }
  }

  Future<List<RestaurantMarker>> nearby({
    required double lng,
    required double lat,
    double radiusM = 3000,
    int maxRows = 50,
  }) async {
    try {
      final rows = await _schema.rpc<List<dynamic>>('nearby_restaurants', params: {
        'in_lng': lng,
        'in_lat': lat,
        'radius_m': radiusM,
        'max_rows': maxRows,
      });
      return rows
          .cast<Map<String, dynamic>>()
          .map(RestaurantMarker.fromJson)
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(cause: e);
    }
  }

  /// Simple name search for pickers (create flows). Universal search uses
  /// the grouped search_all RPC instead.
  Future<List<RestaurantMarker>> searchByName(String query,
      {int limit = 20}) async {
    try {
      final rows = await _schema
          .from('restaurants')
          .select(
              'id, name, price_level, rec_count, save_count, score, cover_photo_url, city_id')
          .ilike('name', '%$query%')
          .isFilter('deleted_at', null)
          .order('rec_count', ascending: false)
          .limit(limit);
      return rows
          .map((r) => RestaurantMarker.fromJson({...r, 'lat': 0.0, 'lng': 0.0}))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(cause: e);
    }
  }

  Future<Restaurant> fetchRestaurant(String id) async {
    try {
      final row =
          await _schema.from('restaurants').select().eq('id', id).maybeSingle();
      if (row == null) throw const NotFoundException('Restaurant not found');
      return Restaurant.fromJson(row);
    } on PostgrestException catch (e) {
      throw ServerException(cause: e);
    }
  }

  Future<RestaurantSummary> fetchSummary(String id) async {
    try {
      final json = await _schema
          .rpc<Map<String, dynamic>>('restaurant_summary', params: {'rid': id});
      return RestaurantSummary.fromJson(json);
    } on PostgrestException catch (e) {
      throw ServerException(cause: e);
    }
  }

  Future<List<String>> fetchCuisineNames(String restaurantId) async {
    final rows = await _schema
        .from('restaurant_cuisines')
        .select('cuisines(name)')
        .eq('restaurant_id', restaurantId);
    return rows
        .map((r) =>
            (r['cuisines']
                as Map<String, dynamic>?)?['name'] as String?)
        .whereType<String>()
        .toList();
  }

  // --- saves / visits ------------------------------------------------------

  Future<Set<String>> fetchMySavedIds(String userId) async {
    final rows = await _schema
        .from('restaurant_saves')
        .select('restaurant_id')
        .eq('user_id', userId);
    return rows
        .map((r) => r['restaurant_id'] as String)
        .toSet();
  }

  Future<Set<String>> fetchMyVisitedIds(String userId) async {
    final rows = await _schema
        .from('restaurant_visits')
        .select('restaurant_id')
        .eq('user_id', userId);
    return rows
        .map((r) => r['restaurant_id'] as String)
        .toSet();
  }

  Future<void> save(String userId, String restaurantId) async {
    try {
      await _schema.from('restaurant_saves').insert({
        'user_id': userId,
        'restaurant_id': restaurantId,
      });
    } on PostgrestException catch (e) {
      if (e.code != '23505') throw ServerException(cause: e); // already saved
    }
  }

  Future<void> unsave(String userId, String restaurantId) async {
    await _schema
        .from('restaurant_saves')
        .delete()
        .eq('user_id', userId)
        .eq('restaurant_id', restaurantId);
  }

  Future<void> markVisited(String userId, String restaurantId,
      {DateTime? visitedOn}) async {
    try {
      await _schema.from('restaurant_visits').upsert({
        'user_id': userId,
        'restaurant_id': restaurantId,
        if (visitedOn != null)
          'visited_on': visitedOn.toIso8601String().substring(0, 10),
      });
    } on PostgrestException catch (e) {
      throw ServerException(cause: e);
    }
  }

  Future<void> unmarkVisited(String userId, String restaurantId) async {
    await _schema
        .from('restaurant_visits')
        .delete()
        .eq('user_id', userId)
        .eq('restaurant_id', restaurantId);
  }

  Future<void> reportRestaurant({
    required String reporterId,
    required String restaurantId,
    String reason = 'incorrect_info',
    String? details,
  }) async {
    try {
      await _schema.from('content_reports').insert({
        'reporter_id': reporterId,
        'target_type': 'restaurant',
        'target_id': restaurantId,
        'reason': reason,
        if (details != null && details.isNotEmpty) 'details': details,
      });
    } on PostgrestException catch (e) {
      throw ServerException(cause: e);
    }
  }

  // --- offline cache -------------------------------------------------------

  Future<void> _cacheMarkers(List<RestaurantMarker> markers) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _markerCacheKey, jsonEncode(markers.map((m) => m.toJson()).toList()));
  }

  Future<List<RestaurantMarker>?> cachedMarkers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_markerCacheKey);
    if (raw == null) return null;
    try {
      return (jsonDecode(raw) as List)
          .cast<Map<String, dynamic>>()
          .map(RestaurantMarker.fromJson)
          .toList();
    } catch (_) {
      return null;
    }
  }
}

final restaurantRepositoryProvider = Provider<RestaurantRepository>((ref) {
  return RestaurantRepository(ref.watch(wbSchemaProvider));
});
