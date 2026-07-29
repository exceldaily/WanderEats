import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../core/errors/app_exception.dart';
import '../../../core/networking/supabase_provider.dart';
import '../../restaurants/domain/restaurant.dart';
import '../domain/swipe_card.dart';

/// Data access for BiteSwipe. Ranking lives in the `taste_deck` function, so
/// this class only fetches and records — it never decides ordering.
class BiteSwipeRepository {
  BiteSwipeRepository(this._schema);

  final SupabaseQuerySchema _schema;

  String? get _uid => Supabase.instance.client.auth.currentUser?.id;

  Future<List<SwipeCard>> deck({
    required double lat,
    required double lng,
    int radiusM = 3000,
    int limit = 30,
    int? maxPrice,
    String? cuisineId,
  }) async {
    try {
      final rows = await _schema.rpc<List<dynamic>>(
        'taste_deck',
        params: {
          'p_lat': lat,
          'p_lng': lng,
          'p_radius_m': radiusM,
          'p_limit': limit,
          'p_max_price': maxPrice,
          'p_cuisine_id': cuisineId,
        },
      );
      return rows.cast<Map<String, dynamic>>().map(SwipeCard.fromJson).toList();
    } on PostgrestException catch (e) {
      throw ServerException(cause: e);
    }
  }

  Future<String?> startSession({
    required double lat,
    required double lng,
    required int radiusM,
    Map<String, dynamic> filters = const {},
  }) async {
    final uid = _uid;
    if (uid == null) return null;
    try {
      final row = await _schema
          .from('taste_deck_sessions')
          .insert({
            'user_id': uid,
            'center_lat': lat,
            'center_lng': lng,
            'radius_m': radiusM,
            'filters': filters,
          })
          .select('id')
          .single();
      return row['id'] as String?;
    } on PostgrestException {
      // A missing session must not block swiping; it only costs us analytics.
      return null;
    }
  }

  Future<void> endSession(
    String sessionId, {
    required int saved,
    required int skipped,
    required int tasters,
  }) async {
    try {
      await _schema
          .from('taste_deck_sessions')
          .update({
            'saved_count': saved,
            'skipped_count': skipped,
            'tasters_discovered': tasters,
            'ended_at': DateTime.now().toIso8601String(),
          })
          .eq('id', sessionId);
    } on PostgrestException {
      // Best effort.
    }
  }

  Future<void> recordImpression({
    required String sessionId,
    required SwipeCard card,
    required int position,
    required String action,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _schema.from('taste_deck_impressions').insert({
        'session_id': sessionId,
        'user_id': uid,
        'restaurant_id': card.id,
        'position': position,
        'reason': card.reason,
        'via_taster_id': card.viaTasterId,
        'action': action,
        'acted_at': DateTime.now().toIso8601String(),
      });
    } on PostgrestException {
      // Best effort: losing an impression must never break a swipe.
    }
  }

  /// Records a soft skip. Repeat skips damp ranking further, and the
  /// ranking function decays that penalty over two weeks.
  Future<void> skip(String restaurantId) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final existing = await _schema
          .from('restaurant_skips')
          .select('skip_count')
          .eq('user_id', uid)
          .eq('restaurant_id', restaurantId)
          .maybeSingle();
      await _schema.from('restaurant_skips').upsert({
        'user_id': uid,
        'restaurant_id': restaurantId,
        'skip_count': ((existing?['skip_count'] as int?) ?? 0) + 1,
        'last_skipped_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,restaurant_id');
    } on PostgrestException {
      // Best effort.
    }
  }

  /// Undo removes the skip entirely so the card is not quietly penalised for
  /// a swipe the user took back.
  Future<void> unskip(String restaurantId) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _schema
          .from('restaurant_skips')
          .delete()
          .eq('user_id', uid)
          .eq('restaurant_id', restaurantId);
    } on PostgrestException {
      // Best effort.
    }
  }

  /// Attributes a save to the deck so its value is measurable later.
  Future<void> recordSaveSource({
    required String restaurantId,
    required String sessionId,
    String? viaTasterId,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _schema.from('restaurant_save_sources').upsert({
        'user_id': uid,
        'restaurant_id': restaurantId,
        'source': 'deck',
        'session_id': sessionId,
        'via_taster_id': viaTasterId,
      }, onConflict: 'user_id,restaurant_id');
    } on PostgrestException {
      // Best effort.
    }
  }

  Future<void> recordSkipReason({
    required String restaurantId,
    required SkipReason reason,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _schema.from('taste_preference_feedback').insert({
        'user_id': uid,
        'restaurant_id': restaurantId,
        'reason': reason.wire,
      });
    } on PostgrestException {
      // Best effort.
    }
  }

  /// Tasters who recommended this restaurant, for the preview sheet.
  /// Reuses the same summary the map card and details screen already read,
  /// so the deck cannot drift from what the rest of the app shows.
  Future<RestaurantSummary> summary(String restaurantId) async {
    final json = await _schema.rpc<Map<String, dynamic>>(
      'restaurant_summary',
      params: {'rid': restaurantId},
    );
    return RestaurantSummary.fromJson(json);
  }
}

final biteSwipeRepositoryProvider = Provider<BiteSwipeRepository>(
  (ref) => BiteSwipeRepository(ref.watch(wbSchemaProvider)),
);
