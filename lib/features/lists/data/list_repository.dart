import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../core/errors/app_exception.dart';
import '../../../core/networking/supabase_provider.dart';
import '../domain/food_list.dart';

class ListRepository {
  ListRepository(this._schema);

  final SupabaseQuerySchema _schema;

  static const _select = '*, profiles(username, display_name, avatar_url)';

  Future<List<FoodList>> publicLists({int limit = 20, int offset = 0}) async {
    try {
      final rows = await _schema
          .from('lists')
          .select(_select)
          .eq('visibility', 'public')
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return rows.map(FoodList.fromJson).toList();
    } on PostgrestException catch (e) {
      throw ServerException(cause: e);
    }
  }

  Future<List<FoodList>> byOwner(String ownerId) async {
    try {
      final rows = await _schema
          .from('lists')
          .select(_select)
          .eq('owner_id', ownerId)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);
      return rows.map(FoodList.fromJson).toList();
    } on PostgrestException catch (e) {
      throw ServerException(cause: e);
    }
  }

  Future<FoodList> fetchList(String id) async {
    try {
      final row = await _schema
          .from('lists')
          .select(_select)
          .eq('id', id)
          .maybeSingle();
      if (row == null) throw const NotFoundException('List not found');
      return FoodList.fromJson(row);
    } on PostgrestException catch (e) {
      throw ServerException(cause: e);
    }
  }

  Future<List<ListPlace>> places(String listId) async {
    try {
      final rows = await _schema.rpc<List<dynamic>>(
        'list_places',
        params: {'lid': listId},
      );
      return rows.cast<Map<String, dynamic>>().map(ListPlace.fromJson).toList();
    } on PostgrestException catch (e) {
      throw ServerException(cause: e);
    }
  }

  /// followers / likes / comments counts + whether I follow it.
  Future<Map<String, dynamic>> listMeta(String listId, String? myId) async {
    final followers = await _schema
        .from('list_follows')
        .select('user_id')
        .eq('list_id', listId);
    final likes = await _schema
        .from('likes')
        .select('user_id')
        .eq('target_type', 'list')
        .eq('target_id', listId);
    return {
      'followers': followers.length,
      'likes': likes.length,
      'i_follow': myId != null && followers.any((r) => r['user_id'] == myId),
      'i_like': myId != null && likes.any((r) => r['user_id'] == myId),
    };
  }

  Future<FoodList> create({
    required String ownerId,
    required String title,
    String? description,
    String visibility = 'public',
    bool isCollaborative = false,
    String? coverUrl,
  }) async {
    try {
      final row = await _schema
          .from('lists')
          .insert({
            'owner_id': ownerId,
            'title': title,
            if (description != null && description.isNotEmpty)
              'description': description,
            'visibility': visibility,
            'is_collaborative': isCollaborative,
            'cover_url': ?coverUrl,
          })
          .select(_select)
          .single();
      return FoodList.fromJson(row);
    } on PostgrestException catch (e) {
      throw ServerException(cause: e);
    }
  }

  Future<void> update(String listId, Map<String, dynamic> patch) async {
    try {
      await _schema.from('lists').update(patch).eq('id', listId);
    } on PostgrestException catch (e) {
      throw ServerException(cause: e);
    }
  }

  Future<void> softDelete(String listId) async {
    await update(listId, {'deleted_at': DateTime.now().toIso8601String()});
  }

  Future<void> addRestaurant({
    required String listId,
    required String restaurantId,
    required String addedBy,
    String? note,
  }) async {
    try {
      final existing = await _schema
          .from('list_restaurants')
          .select('position')
          .eq('list_id', listId)
          .order('position', ascending: false)
          .limit(1);
      final nextPos = existing.isEmpty
          ? 1
          : ((existing.first['position'] as num).toInt() + 1);
      await _schema.from('list_restaurants').insert({
        'list_id': listId,
        'restaurant_id': restaurantId,
        'added_by': addedBy,
        'position': nextPos,
        if (note != null && note.isNotEmpty) 'note': note,
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw const ValidationException('That place is already on the list.');
      }
      throw ServerException(cause: e);
    }
  }

  Future<void> removeEntry(String entryId) async {
    await _schema.from('list_restaurants').delete().eq('id', entryId);
  }

  /// Persist a full reorder: positions become 1..n in the given entry order.
  Future<void> reorder(String listId, List<String> entryIdsInOrder) async {
    for (var i = 0; i < entryIdsInOrder.length; i++) {
      await _schema
          .from('list_restaurants')
          .update({'position': i + 1})
          .eq('id', entryIdsInOrder[i]);
    }
  }

  Future<void> followList(String myId, String listId) async {
    try {
      await _schema.from('list_follows').insert({
        'user_id': myId,
        'list_id': listId,
      });
    } on PostgrestException catch (e) {
      if (e.code != '23505') throw ServerException(cause: e);
    }
  }

  Future<void> unfollowList(String myId, String listId) async {
    await _schema
        .from('list_follows')
        .delete()
        .eq('user_id', myId)
        .eq('list_id', listId);
  }

  Future<void> toggleLike(String myId, String listId, bool like) async {
    if (like) {
      try {
        await _schema.from('likes').insert({
          'user_id': myId,
          'target_type': 'list',
          'target_id': listId,
        });
      } on PostgrestException catch (e) {
        if (e.code != '23505') throw ServerException(cause: e);
      }
    } else {
      await _schema
          .from('likes')
          .delete()
          .eq('user_id', myId)
          .eq('target_type', 'list')
          .eq('target_id', listId);
    }
  }

  // --- comments ------------------------------------------------------------

  Future<List<Map<String, dynamic>>> comments(String listId) async {
    final rows = await _schema
        .from('comments')
        .select('*, profiles(username, display_name, avatar_url)')
        .eq('target_type', 'list')
        .eq('target_id', listId)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false)
        .limit(50);
    return rows;
  }

  Future<void> addComment(String myId, String listId, String body) async {
    try {
      await _schema.from('comments').insert({
        'user_id': myId,
        'target_type': 'list',
        'target_id': listId,
        'body': body,
      });
    } on PostgrestException catch (e) {
      throw ServerException(cause: e);
    }
  }
}

final listRepositoryProvider = Provider<ListRepository>((ref) {
  return ListRepository(ref.watch(wbSchemaProvider));
});
