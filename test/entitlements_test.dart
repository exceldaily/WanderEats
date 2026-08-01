import 'package:flutter_test/flutter_test.dart';
import 'package:wanderbites/features/premium/domain/entitlements.dart';

void main() {
  group('PremiumEntitlement', () {
    test('codes match the database contract', () {
      // These strings appear in subscription_products.entitlements and in every
      // server-side has_entitlement() call. A mismatch does not fail loudly; it
      // silently denies a paid feature to someone who paid, or grants one to
      // someone who did not.
      expect(PremiumEntitlement.directMessaging.code, 'direct_messaging');
      expect(PremiumEntitlement.createTasteGroups.code, 'create_taste_groups');
      expect(
        PremiumEntitlement.premiumProfileLayouts.code,
        'premium_profile_layouts',
      );
      expect(
        PremiumEntitlement.advancedTripPlanning.code,
        'advanced_trip_planning',
      );
    });

    test('codes are unique', () {
      final codes = PremiumEntitlement.values.map((e) => e.code).toList();
      expect(codes.toSet().length, codes.length);
    });

    test('fromCode round-trips and rejects unknowns', () {
      for (final e in PremiumEntitlement.values) {
        expect(PremiumEntitlement.fromCode(e.code), e);
      }
      expect(PremiumEntitlement.fromCode('free_lunch'), isNull);
    });
  });

  group('Entitlements', () {
    test('an empty grant set gives nothing away', () {
      const none = Entitlements.none();
      expect(none.isPremium, isFalse);
      for (final e in PremiumEntitlement.values) {
        expect(none.has(e), isFalse);
      }
    });

    test('parses server codes', () {
      final e = Entitlements.fromCodes(['direct_messaging', 'create_taste_groups']);
      expect(e.has(PremiumEntitlement.directMessaging), isTrue);
      expect(e.has(PremiumEntitlement.createTasteGroups), isTrue);
      expect(e.has(PremiumEntitlement.advancedTripPlanning), isFalse);
      expect(e.isPremium, isTrue);
    });

    test('ignores unknown codes instead of throwing', () {
      // The server may know about an entitlement a shipped build predates.
      // Crashing a launch path over that would be worse than ignoring it.
      final e = Entitlements.fromCodes([
        'direct_messaging',
        'something_from_the_future',
      ]);
      expect(e.has(PremiumEntitlement.directMessaging), isTrue);
      expect(e.granted.length, 1);
    });

    test('an unknown code alone does not count as premium', () {
      final e = Entitlements.fromCodes(['not_a_real_entitlement']);
      expect(e.isPremium, isFalse);
    });

    test('equality ignores ordering', () {
      final a = Entitlements.fromCodes(['direct_messaging', 'create_taste_groups']);
      final b = Entitlements.fromCodes(['create_taste_groups', 'direct_messaging']);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('granted set cannot be mutated by callers', () {
      final e = Entitlements.fromCodes(['direct_messaging']);
      expect(
        () => e.granted.add(PremiumEntitlement.advancedTripPlanning),
        throwsUnsupportedError,
      );
    });
  });

  group('EntitlementDenial', () {
    test('only a premium gap can be solved by upgrading', () {
      // The brief forbids showing a purchase screen to an under-18 account as a
      // way to unlock messaging. Encoding that here keeps the rule out of
      // individual widgets, where it would eventually be forgotten.
      expect(EntitlementDenial.premiumRequired.canBeSolvedByUpgrading, isTrue);
      for (final d in EntitlementDenial.values.where(
        (d) => d != EntitlementDenial.premiumRequired,
      )) {
        expect(d.canBeSolvedByUpgrading, isFalse, reason: d.name);
      }
    });

    test('age restrictions never offer an upgrade path', () {
      expect(EntitlementDenial.ageRestricted.canBeSolvedByUpgrading, isFalse);
      expect(EntitlementDenial.ageUnconfirmed.canBeSolvedByUpgrading, isFalse);
    });
  });
}
