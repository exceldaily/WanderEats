import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../core/errors/app_exception.dart';
import '../../../core/networking/supabase_provider.dart';
import '../../restaurants/domain/restaurant.dart';

/// Follows + taster stats + personal food maps.
class TasterRepository {
  TasterRepository(this._schema);

  final SupabaseQuerySchema _schema;

  Future<Map<String, dynamic>> stats(String userId) async {
    try {
      return await _schema.rpc<Map<String, dynamic>>(
        'taster_stats',
        params: {'uid': userId},
      );
    } on PostgrestException catch (e) {
      throw ServerException(cause: e);
    }
  }

  Future<Set<String>> myFollowingIds(String myId) async {
    final rows = await _schema
        .from('follows')
        .select('followee_id')
        .eq('follower_id', myId);
    return rows.map((r) => r['followee_id'] as String).toSet();
  }

  Future<void> follow(String myId, String tasterId) async {
    try {
      await _schema.from('follows').insert({
        'follower_id': myId,
        'followee_id': tasterId,
      });
    } on PostgrestException catch (e) {
      if (e.code != '23505') throw ServerException(cause: e);
    }
  }

  Future<void> unfollow(String myId, String tasterId) async {
    await _schema
        .from('follows')
        .delete()
        .eq('follower_id', myId)
        .eq('followee_id', tasterId);
  }

  /// A Taster's personal food map (recommended / visited / saved places).
  Future<List<TasterPlace>> places(String userId) async {
    try {
      final rows = await _schema.rpc<List<dynamic>>(
        'taster_places',
        params: {'uid': userId},
      );
      return rows
          .cast<Map<String, dynamic>>()
          .map(TasterPlace.fromJson)
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(cause: e);
    }
  }
}

/// Marker + relation flags for the personal map.
class TasterPlace {
  const TasterPlace({
    required this.marker,
    required this.recommended,
    required this.visited,
    required this.saved,
  });

  final RestaurantMarker marker;
  final bool recommended;
  final bool visited;
  final bool saved;

  factory TasterPlace.fromJson(Map<String, dynamic> json) => TasterPlace(
    marker: RestaurantMarker.fromJson(json),
    recommended: json['recommended'] as bool? ?? false,
    visited: json['visited'] as bool? ?? false,
    saved: json['saved'] as bool? ?? false,
  );
}

final tasterRepositoryProvider = Provider<TasterRepository>((ref) {
  return TasterRepository(ref.watch(wbSchemaProvider));
});
