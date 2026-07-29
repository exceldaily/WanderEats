import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../core/errors/app_exception.dart';
import '../../../core/networking/supabase_provider.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
    this.actorId,
    this.actorName,
    this.actorUsername,
    this.actorAvatarUrl,
    this.readAt,
  });

  final String id;
  final String type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final String? actorId;
  final String? actorName;
  final String? actorUsername;
  final String? actorAvatarUrl;
  final DateTime? readAt;

  bool get unread => readAt == null;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final actor = json['profiles'] as Map<String, dynamic>?;
    return AppNotification(
      id: json['id'] as String,
      type: json['type'] as String,
      payload: (json['payload'] as Map?)?.cast<String, dynamic>() ?? {},
      createdAt: DateTime.parse(json['created_at'] as String),
      actorId: json['actor_id'] as String?,
      actorName: actor?['display_name'] as String?,
      actorUsername: actor?['username'] as String?,
      actorAvatarUrl: actor?['avatar_url'] as String?,
      readAt: json['read_at'] == null
          ? null
          : DateTime.parse(json['read_at'] as String),
    );
  }
}

class NotificationRepository {
  NotificationRepository(this._schema);

  final SupabaseQuerySchema _schema;

  Future<List<AppNotification>> list(String userId, {int limit = 50}) async {
    try {
      final rows = await _schema
          .from('notifications')
          .select(
            '*, profiles!notifications_actor_id_fkey(username, display_name, avatar_url)',
          )
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);
      return rows.map(AppNotification.fromJson).toList();
    } on PostgrestException catch (e) {
      throw ServerException(cause: e);
    }
  }

  Future<void> markRead(String id) async {
    await _schema
        .from('notifications')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }

  Future<void> markAllRead(String userId) async {
    await _schema
        .from('notifications')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('user_id', userId)
        .isFilter('read_at', null);
  }

  /// Resolve where a notification should deep-link to.
  /// Returns (routeName, pathParams) or null.
  Future<(String, Map<String, String>)?> resolveTarget(
    AppNotification n,
  ) async {
    switch (n.type) {
      case 'follow':
        return n.actorId == null ? null : ('taster', {'id': n.actorId!});
      case 'list_invite':
      case 'list_update':
      case 'saved_list_update':
        final listId = n.payload['list_id'] as String?;
        return listId == null ? null : ('list', {'id': listId});
      case 'rec_feedback':
        final recId = n.payload['recommendation_id'] as String?;
        if (recId == null) return null;
        final rec = await _schema
            .from('recommendations')
            .select('restaurant_id')
            .eq('id', recId)
            .maybeSingle();
        final rid = rec?['restaurant_id'] as String?;
        return rid == null ? null : ('restaurant', {'id': rid});
      case 'comment':
      case 'like':
        final targetType = n.payload['target_type'] as String?;
        final targetId = n.payload['target_id'] as String?;
        if (targetType == 'list' && targetId != null) {
          return ('list', {'id': targetId});
        }
        if (targetType == 'recommendation' && targetId != null) {
          final rec = await _schema
              .from('recommendations')
              .select('restaurant_id')
              .eq('id', targetId)
              .maybeSingle();
          final rid = rec?['restaurant_id'] as String?;
          return rid == null ? null : ('restaurant', {'id': rid});
        }
        return null;
      default:
        return null;
    }
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(wbSchemaProvider));
});
