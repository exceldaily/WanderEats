import 'package:flutter_test/flutter_test.dart';
import 'package:wanderbites/features/messaging/domain/messaging_models.dart';
import 'package:wanderbites/features/premium/domain/entitlements.dart';

void main() {
  group('DmAvailability.fromCode', () {
    test('null means allowed', () {
      expect(DmAvailability.fromCode(null), isA<DmAllowed>());
    });

    test('caller-side denials map onto EntitlementDenial', () {
      expect(
        (DmAvailability.fromCode('not_signed_in') as DmDenied).denial,
        EntitlementDenial.notSignedIn,
      );
      expect(
        (DmAvailability.fromCode('age_unconfirmed') as DmDenied).denial,
        EntitlementDenial.ageUnconfirmed,
      );
      expect(
        (DmAvailability.fromCode('age_restricted') as DmDenied).denial,
        EntitlementDenial.ageRestricted,
      );
      expect(
        (DmAvailability.fromCode('premium_required') as DmDenied).denial,
        EntitlementDenial.premiumRequired,
      );
      expect(
        (DmAvailability.fromCode('account_restricted') as DmDenied).denial,
        EntitlementDenial.accountRestricted,
      );
    });

    test('peer-side and unknown codes collapse to unavailable', () {
      // 'unavailable' is deliberately reason-free (blocks, minors, deleted
      // accounts all look identical) and unknown future codes must fail
      // closed rather than granting a button.
      expect(DmAvailability.fromCode('unavailable'), isA<DmPeerUnavailable>());
      expect(
        DmAvailability.fromCode('something_new'),
        isA<DmPeerUnavailable>(),
      );
    });

    test('only the premium denial may route to the paywall', () {
      for (final code in [
        'not_signed_in',
        'age_unconfirmed',
        'age_restricted',
        'account_restricted',
      ]) {
        final d = DmAvailability.fromCode(code) as DmDenied;
        expect(d.denial.canBeSolvedByUpgrading, isFalse, reason: code);
      }
      final premium = DmAvailability.fromCode('premium_required') as DmDenied;
      expect(premium.denial.canBeSolvedByUpgrading, isTrue);
    });
  });

  group('Conversation.fromRow', () {
    test('parses a my_conversations row', () {
      final c = Conversation.fromRow({
        'id': 'c1',
        'peer_id': 'u2',
        'peer_username': 'somchai',
        'peer_display_name': 'Somchai',
        'peer_avatar_url': null,
        'last_message_at': '2026-08-04T10:00:00Z',
        'last_message_body': 'Best khao soi in town?',
        'last_message_sender_id': 'u2',
        'unread_count': 3,
      });
      expect(c.id, 'c1');
      expect(c.peerDisplayName, 'Somchai');
      expect(c.unreadCount, 3);
      expect(c.lastMessageAt, isNotNull);
    });

    test('survives nulls without throwing', () {
      final c = Conversation.fromRow({
        'id': 'c1',
        'peer_id': 'u2',
        'peer_username': null,
        'peer_display_name': null,
        'last_message_at': null,
        'unread_count': null,
      });
      expect(c.unreadCount, 0);
      expect(c.lastMessageAt, isNull);
    });
  });

  group('ChatMessage.fromRow', () {
    test('parses a conversation_messages row', () {
      final m = ChatMessage.fromRow({
        'id': 'm1',
        'sender_id': 'u1',
        'body': 'hello',
        'created_at': '2026-08-04T10:00:00Z',
      });
      expect(m.body, 'hello');
      expect(m.createdAt.isUtc, isFalse); // converted to local for display
    });
  });
}
