import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../core/errors/app_exception.dart';
import '../../../core/networking/supabase_provider.dart';
import '../domain/recommendation.dart';

class RecommendationRepository {
  RecommendationRepository(this._schema);

  final SupabaseQuerySchema _schema;

  static const _select =
      '*, profiles(username, display_name, avatar_url, is_verified, is_demo), '
      'recommendation_photos(storage_path, position), '
      'restaurants(name, cover_photo_url, price_level, '
      'cities(name, countries(name)))';

  Future<List<Recommendation>> forRestaurant(
    String restaurantId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final rows = await _schema
          .from('recommendations')
          .select(_select)
          .eq('restaurant_id', restaurantId)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return rows.map(Recommendation.fromJson).toList();
    } on PostgrestException catch (e) {
      throw ServerException(cause: e);
    }
  }

  Future<List<Recommendation>> byUser(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final rows = await _schema
          .from('recommendations')
          .select(_select)
          .eq('user_id', userId)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return rows.map(Recommendation.fromJson).toList();
    } on PostgrestException catch (e) {
      throw ServerException(cause: e);
    }
  }

  Future<Recommendation> create({
    required String userId,
    required String restaurantId,
    required String body,
    String? whatToOrder,
    int? priceImpression,
    DateTime? visitedOn,
    String visibility = 'public',
    List<String> photoUrls = const [],
  }) async {
    try {
      final row = await _schema
          .from('recommendations')
          .insert({
            'user_id': userId,
            'restaurant_id': restaurantId,
            'body': body,
            if (whatToOrder != null && whatToOrder.isNotEmpty)
              'what_to_order': whatToOrder,
            'price_impression': ?priceImpression,
            if (visitedOn != null)
              'visited_on': visitedOn.toIso8601String().substring(0, 10),
            'visibility': visibility,
          })
          .select()
          .single();
      final recId = row['id'] as String;
      if (photoUrls.isNotEmpty) {
        await _schema.from('recommendation_photos').insert([
          for (var i = 0; i < photoUrls.length; i++)
            {
              'recommendation_id': recId,
              'storage_path': photoUrls[i],
              'position': i,
            },
        ]);
      }
      return Recommendation.fromJson(row);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw const ValidationException(
          'You already recommended this place. Edit your existing recommendation instead.',
        );
      }
      throw ServerException(cause: e);
    }
  }

  /// Server-side badge evaluation for the current user. Returns names of any
  /// newly awarded badges.
  Future<List<String>> awardBadges() async {
    try {
      final rows = await _schema.rpc<List<dynamic>>('check_and_award_badges');
      return rows
          .cast<Map<String, dynamic>>()
          .map((b) => b['name'] as String)
          .toList();
    } on PostgrestException {
      return const []; // badge failures never block publishing
    }
  }

  // --- feedback ------------------------------------------------------------

  /// Returns rating counts for a recommendation, plus the caller's own rating.
  Future<Map<String, dynamic>> feedbackFor(
    String recommendationId,
    String? myUserId,
  ) async {
    final rows = await _schema
        .from('recommendation_feedback')
        .select('rating, user_id')
        .eq('recommendation_id', recommendationId);
    final counts = <String, int>{};
    String? mine;
    for (final r in rows) {
      final row = r;
      final rating = row['rating'] as String;
      counts[rating] = (counts[rating] ?? 0) + 1;
      if (myUserId != null && row['user_id'] == myUserId) mine = rating;
    }
    return {'counts': counts, 'mine': mine};
  }

  Future<void> submitFeedback({
    required String userId,
    required String recommendationId,
    required RecFeedbackRating rating,
    String? note,
  }) async {
    try {
      await _schema.from('recommendation_feedback').upsert({
        'user_id': userId,
        'recommendation_id': recommendationId,
        'rating': rating.value,
        if (note != null && note.isNotEmpty) 'note': note,
      }, onConflict: 'recommendation_id, user_id');
    } on PostgrestException catch (e) {
      // 42501: RLS rejection, e.g. trying to rate your own recommendation.
      if (e.code == '42501') {
        throw const PermissionDeniedException(
          'You cannot rate your own recommendation.',
        );
      }
      throw ServerException(cause: e);
    }
  }
}

final recommendationRepositoryProvider = Provider<RecommendationRepository>((
  ref,
) {
  return RecommendationRepository(ref.watch(wbSchemaProvider));
});
