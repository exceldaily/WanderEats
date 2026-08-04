import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../core/errors/app_exception.dart';
import '../../../core/networking/supabase_provider.dart';
import '../../authentication/presentation/auth_providers.dart';
import '../domain/messaging_models.dart';

/// Raised when the server refuses a messaging action. Carries the parsed
/// availability so UI can react (route to paywall, prompt age confirmation)
/// instead of string-matching an error message. Not an AppException (that
/// hierarchy is sealed); callers catch it explicitly before the generic case.
class DmException implements Exception {
  DmException(this.availability, this.message);

  final DmAvailability availability;

  /// Human-readable, safe for a snackbar.
  final String message;

  @override
  String toString() => 'DmException: $message';
}

/// All messaging I/O. Every write is a SECURITY DEFINER RPC; the client never
/// touches the tables directly, so nothing here can outrun the server rules.
class MessagingRepository {
  MessagingRepository(this._schema);

  final SupabaseQuerySchema _schema;

  Future<DmAvailability> availabilityWith(String peerId) async {
    try {
      final code = await _schema.rpc<dynamic>(
        'dm_denial',
        params: {'p_peer': peerId},
      );
      return DmAvailability.fromCode(code as String?);
    } on PostgrestException catch (e) {
      throw ServerException(cause: e);
    }
  }

  Future<String> startConversation(String peerId) async {
    try {
      final id = await _schema.rpc<dynamic>(
        'start_conversation',
        params: {'p_peer': peerId},
      );
      return id as String;
    } on PostgrestException catch (e) {
      throw _asDmException(e);
    }
  }

  Future<void> sendMessage(String conversationId, String body) async {
    try {
      await _schema.rpc<dynamic>(
        'send_message',
        params: {'p_conversation': conversationId, 'p_body': body},
      );
    } on PostgrestException catch (e) {
      throw _asDmException(e);
    }
  }

  Future<List<Conversation>> conversations() async {
    try {
      final rows = await _schema.rpc<List<dynamic>>('my_conversations');
      return [
        for (final row in rows) Conversation.fromRow(row as Map<String, dynamic>),
      ];
    } on PostgrestException catch (e) {
      throw ServerException(cause: e);
    }
  }

  Future<List<ChatMessage>> messages(
    String conversationId, {
    DateTime? before,
    int limit = 50,
  }) async {
    try {
      final rows = await _schema.rpc<List<dynamic>>(
        'conversation_messages',
        params: {
          'p_conversation': conversationId,
          'p_before': before?.toUtc().toIso8601String(),
          'p_limit': limit,
        },
      );
      return [
        for (final row in rows) ChatMessage.fromRow(row as Map<String, dynamic>),
      ];
    } on PostgrestException catch (e) {
      throw ServerException(cause: e);
    }
  }

  Future<void> markRead(String conversationId) async {
    try {
      await _schema.rpc<dynamic>(
        'mark_conversation_read',
        params: {'p_conversation': conversationId},
      );
    } on PostgrestException {
      // Read markers are cosmetic; never surface a failure over one.
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await _schema.rpc<dynamic>(
        'delete_message',
        params: {'p_message': messageId},
      );
    } on PostgrestException catch (e) {
      throw ServerException(cause: e);
    }
  }

  /// The RPCs raise `dm_denied:<code>`; anything else is an ordinary server
  /// error.
  Exception _asDmException(PostgrestException e) {
    final match = RegExp('dm_denied:([a-z_]+)').firstMatch(e.message);
    if (match == null) return ServerException(cause: e);
    final availability = DmAvailability.fromCode(match.group(1));
    return DmException(availability, switch (availability) {
      DmDenied(denial: final d) => switch (d) {
        _ when d.canBeSolvedByUpgrading =>
          'Messaging is a WanderBites Premium feature.',
        _ => 'Messaging is not available on your account.',
      },
      _ => 'This person cannot be messaged.',
    });
  }
}

final messagingRepositoryProvider = Provider<MessagingRepository>(
  (ref) => MessagingRepository(ref.watch(wbSchemaProvider)),
);

/// Inbox rows. Watches the session so signing out clears another user's
/// conversations from memory immediately.
final conversationsProvider = FutureProvider.autoDispose<List<Conversation>>((
  ref,
) async {
  final session = ref.watch(sessionProvider);
  if (session == null) return const [];
  return ref.watch(messagingRepositoryProvider).conversations();
});

/// Can I message this person? Fails closed to "peer unavailable", which UI
/// renders as no messaging affordance at all - the safe default for minors
/// and the honest one for network trouble.
final dmAvailabilityProvider = FutureProvider.autoDispose
    .family<DmAvailability, String>((ref, peerId) async {
      if (ref.watch(sessionProvider) == null) return const DmPeerUnavailable();
      try {
        return await ref
            .watch(messagingRepositoryProvider)
            .availabilityWith(peerId);
      } on AppException {
        return const DmPeerUnavailable();
      }
    });
