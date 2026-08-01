import 'package:flutter_test/flutter_test.dart';
import 'package:wanderbites/features/safety/domain/safety.dart';

void main() {
  group('report reasons', () {
    test('every wire value matches what report_content accepts', () {
      // Mirrors the CHECK in migration 0023. If someone adds a reason here
      // without widening the constraint, reporting fails at insert time with a
      // 23514 rather than anything the user can act on - which is exactly the
      // bug that testing 0022 against real data caught.
      const acceptedByDatabase = {
        'spam',
        'harassment',
        'hate_or_abuse',
        'threatening_behavior',
        'impersonation',
        'scam_or_fraud',
        'sexual_content',
        'underage_safety_concern',
        'dangerous_content',
        'false_information',
        'privacy_violation',
        'copyright',
        'inappropriate_content',
        'other',
      };
      for (final r in ReportReason.values) {
        expect(
          acceptedByDatabase,
          contains(r.wire),
          reason: '${r.name} would be rejected by content_reports_reason_check',
        );
      }
    });

    test('wire values are unique', () {
      final wires = ReportReason.values.map((r) => r.wire).toList();
      expect(wires.toSet().length, wires.length);
    });

    test('restaurant reasons exclude interpersonal categories', () {
      // Reporting a place is about the listing being wrong. Offering
      // "harassment" against a restaurant is noise that makes real reports
      // harder to triage.
      const interpersonal = {
        'harassment',
        'hate_or_abuse',
        'threatening_behavior',
        'underage_safety_concern',
        'impersonation',
      };
      for (final r in ReportReason.forRestaurant) {
        expect(interpersonal, isNot(contains(r.wire)));
      }
    });

    test('person reasons cover every urgent safety category', () {
      // These are the categories report_content escalates to urgent. If one is
      // not offered anywhere in the UI, the escalation path is unreachable.
      const urgent = {
        'underage_safety_concern',
        'threatening_behavior',
        'dangerous_content',
      };
      final offered = ReportReason.forPerson.map((r) => r.wire).toSet();
      expect(offered.containsAll(urgent), isTrue);
    });

    test('every reason has a human label', () {
      for (final r in ReportReason.values) {
        expect(r.label.trim(), isNotEmpty);
        expect(r.label, isNot(equals(r.wire)));
      }
    });
  });

  group('report targets', () {
    test('restaurants are not treated as authored by a person', () {
      // Drives whether the sheet offers "block this user" alongside reporting.
      expect(ReportTarget.restaurant.isAuthoredByPerson, isFalse);
      for (final t in ReportTarget.values.where(
        (t) => t != ReportTarget.restaurant,
      )) {
        expect(t.isAuthoredByPerson, isTrue, reason: t.name);
      }
    });

    test('wire values match target_owner and content_reports', () {
      const known = {
        'profile',
        'recommendation',
        'comment',
        'list',
        'restaurant',
        'photo',
      };
      for (final t in ReportTarget.values) {
        expect(known, contains(t.wire));
      }
    });
  });

  group('block reasons', () {
    test('wire values match blocked_users_reason_category_check', () {
      const acceptedByDatabase = {
        'harassment',
        'spam',
        'impersonation',
        'inappropriate_content',
        'unwanted_contact',
        'other',
      };
      for (final r in BlockReason.values) {
        expect(acceptedByDatabase, contains(r.wire), reason: r.name);
      }
    });
  });

  group('BlockedAccount', () {
    test('parses a row from blocked_accounts()', () {
      final a = BlockedAccount.fromRow({
        'id': 'a0000000-0000-4000-8000-000000000009',
        'username': 'wb_bkk_somchai',
        'display_name': 'Somchai',
        'avatar_url': null,
        'reason_category': 'harassment',
        'created_at': '2026-07-31T12:00:00Z',
      });
      expect(a.username, 'wb_bkk_somchai');
      expect(a.displayName, 'Somchai');
      expect(a.reasonCategory, 'harassment');
      expect(a.avatarUrl, isNull);
    });

    test('survives missing optional fields rather than throwing', () {
      // A malformed row should not be able to take down the blocked-accounts
      // screen; a user needs to be able to manage blocks even if one row is odd.
      final a = BlockedAccount.fromRow({
        'id': 'x',
        'created_at': 'not-a-date',
      });
      expect(a.id, 'x');
      expect(a.username, isEmpty);
      expect(a.blockedAt, isA<DateTime>());
    });
  });
}
