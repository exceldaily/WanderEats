import '../../premium/domain/entitlements.dart';

/// One row of `my_conversations()`: a conversation seen from my side.
class Conversation {
  const Conversation({
    required this.id,
    required this.peerId,
    required this.peerUsername,
    required this.peerDisplayName,
    this.peerAvatarUrl,
    this.lastMessageAt,
    this.lastMessageBody,
    this.lastMessageSenderId,
    this.unreadCount = 0,
  });

  factory Conversation.fromRow(Map<String, dynamic> row) => Conversation(
    id: row['id'] as String,
    peerId: row['peer_id'] as String,
    peerUsername: row['peer_username'] as String? ?? '',
    peerDisplayName: row['peer_display_name'] as String? ?? '',
    peerAvatarUrl: row['peer_avatar_url'] as String?,
    lastMessageAt: row['last_message_at'] == null
        ? null
        : DateTime.parse(row['last_message_at'] as String).toLocal(),
    lastMessageBody: row['last_message_body'] as String?,
    lastMessageSenderId: row['last_message_sender_id'] as String?,
    unreadCount: (row['unread_count'] as num?)?.toInt() ?? 0,
  );

  final String id;
  final String peerId;
  final String peerUsername;
  final String peerDisplayName;
  final String? peerAvatarUrl;
  final DateTime? lastMessageAt;
  final String? lastMessageBody;
  final String? lastMessageSenderId;
  final int unreadCount;
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.body,
    required this.createdAt,
  });

  factory ChatMessage.fromRow(Map<String, dynamic> row) => ChatMessage(
    id: row['id'] as String,
    senderId: row['sender_id'] as String,
    body: row['body'] as String,
    createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
  );

  final String id;
  final String senderId;
  final String body;
  final DateTime createdAt;
}

/// Whether the current user may message a given peer, as decided by the
/// server's dm_denial(). Three shapes on purpose: "you can", "you can't and
/// here is what would fix it", and "this person can't be messaged" - the last
/// one deliberately carries no reason, mirroring the server's refusal to say
/// whether it is a block, an age issue, or a gone account.
sealed class DmAvailability {
  const DmAvailability();

  /// Parses a dm_denial() code (null means allowed).
  factory DmAvailability.fromCode(String? code) => switch (code) {
    null => const DmAllowed(),
    'not_signed_in' => const DmDenied(EntitlementDenial.notSignedIn),
    'age_unconfirmed' => const DmDenied(EntitlementDenial.ageUnconfirmed),
    'age_restricted' => const DmDenied(EntitlementDenial.ageRestricted),
    'premium_required' => const DmDenied(EntitlementDenial.premiumRequired),
    'account_restricted' => const DmDenied(EntitlementDenial.accountRestricted),
    // 'unavailable', 'self', 'empty', and anything a future server knows
    // that this build does not: fail closed, blame nobody.
    _ => const DmPeerUnavailable(),
  };
}

class DmAllowed extends DmAvailability {
  const DmAllowed();
}

class DmPeerUnavailable extends DmAvailability {
  const DmPeerUnavailable();
}

class DmDenied extends DmAvailability {
  const DmDenied(this.denial);

  final EntitlementDenial denial;
}
