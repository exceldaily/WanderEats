import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../core/errors/app_exception.dart';
import '../../../core/networking/supabase_provider.dart';
import '../../authentication/presentation/auth_providers.dart';
import '../domain/taste_group_models.dart';

/// The server refused a group action; `code` is the `group_denied:` suffix
/// ('premium_required', 'limit_reached', ...). Kept separate from the sealed
/// AppException hierarchy, like DmException.
class GroupException implements Exception {
  GroupException(this.code, this.message);

  final String code;
  final String message;

  bool get premiumRequired => code == 'premium_required';

  @override
  String toString() => 'GroupException: $message';
}

class TasteGroupRepository {
  TasteGroupRepository(this._schema);

  final SupabaseQuerySchema _schema;

  Future<List<TasteGroup>> list() async {
    try {
      final rows = await _schema.rpc<List<dynamic>>('taste_groups_list');
      return [
        for (final row in rows) TasteGroup.fromRow(row as Map<String, dynamic>),
      ];
    } on PostgrestException catch (e) {
      throw ServerException(cause: e);
    }
  }

  Future<String> create({
    required String name,
    String? description,
    String? emoji,
  }) async {
    try {
      final id = await _schema.rpc<dynamic>(
        'create_taste_group',
        params: {
          'p_name': name,
          'p_description': description,
          'p_emoji': emoji,
        },
      );
      return id as String;
    } on PostgrestException catch (e) {
      throw _asGroupException(e);
    }
  }

  Future<void> join(String groupId) async {
    try {
      await _schema.rpc<dynamic>(
        'join_taste_group',
        params: {'p_group': groupId},
      );
    } on PostgrestException catch (e) {
      throw _asGroupException(e);
    }
  }

  Future<void> leave(String groupId) async {
    try {
      await _schema.rpc<dynamic>(
        'leave_taste_group',
        params: {'p_group': groupId},
      );
    } on PostgrestException catch (e) {
      throw ServerException(cause: e);
    }
  }

  Future<List<GroupMember>> members(String groupId) async {
    try {
      final rows = await _schema
          .from('taste_group_members')
          .select('role, profiles(id, username, display_name, avatar_url)')
          .eq('group_id', groupId)
          .order('joined_at', ascending: true);
      return [
        for (final row in rows) GroupMember.fromRow(row),
      ];
    } on PostgrestException catch (e) {
      throw ServerException(cause: e);
    }
  }

  Future<List<GroupPick>> picks(String groupId) async {
    try {
      final rows = await _schema
          .from('taste_group_picks')
          .select('id, note, added_by, restaurants(id, name, cover_photo_url)')
          .eq('group_id', groupId)
          .order('created_at', ascending: false);
      return [
        for (final row in rows) GroupPick.fromRow(row),
      ];
    } on PostgrestException catch (e) {
      throw ServerException(cause: e);
    }
  }

  /// Returns false when the restaurant was already picked by someone else.
  Future<bool> addPick(String groupId, String restaurantId, {String? note}) async {
    try {
      final id = await _schema.rpc<dynamic>(
        'add_group_pick',
        params: {
          'p_group': groupId,
          'p_restaurant': restaurantId,
          'p_note': note,
        },
      );
      return id != null;
    } on PostgrestException catch (e) {
      throw _asGroupException(e);
    }
  }

  Future<void> removePick(String pickId) async {
    try {
      await _schema.rpc<dynamic>(
        'remove_group_pick',
        params: {'p_pick': pickId},
      );
    } on PostgrestException catch (e) {
      throw ServerException(cause: e);
    }
  }

  /// Simple name search over already-known restaurants for the pick sheet.
  Future<List<Map<String, dynamic>>> searchRestaurants(String query) async {
    if (query.trim().length < 2) return const [];
    try {
      final rows = await _schema
          .from('restaurants')
          .select('id, name, cover_photo_url')
          .ilike('name', '%${query.trim()}%')
          .isFilter('deleted_at', null)
          .limit(20);
      return rows;
    } on PostgrestException catch (e) {
      throw ServerException(cause: e);
    }
  }

  Exception _asGroupException(PostgrestException e) {
    final match = RegExp('group_denied:([a-z_]+)').firstMatch(e.message);
    if (match == null) return ServerException(cause: e);
    final code = match.group(1)!;
    return GroupException(code, switch (code) {
      'premium_required' =>
        'Creating Taste Groups is a WanderBites Premium feature.',
      'limit_reached' => 'You have reached the limit of 10 groups.',
      'members_only' => 'Only members can add picks.',
      'not_signed_in' => 'Sign in to use Taste Groups.',
      _ => 'This group is not available.',
    });
  }
}

final tasteGroupRepositoryProvider = Provider<TasteGroupRepository>(
  (ref) => TasteGroupRepository(ref.watch(wbSchemaProvider)),
);

final tasteGroupsProvider = FutureProvider.autoDispose<List<TasteGroup>>((
  ref,
) async {
  if (ref.watch(sessionProvider) == null) return const [];
  return ref.watch(tasteGroupRepositoryProvider).list();
});

final groupMembersProvider = FutureProvider.autoDispose
    .family<List<GroupMember>, String>(
      (ref, groupId) => ref.watch(tasteGroupRepositoryProvider).members(groupId),
    );

final groupPicksProvider = FutureProvider.autoDispose
    .family<List<GroupPick>, String>(
      (ref, groupId) => ref.watch(tasteGroupRepositoryProvider).picks(groupId),
    );
