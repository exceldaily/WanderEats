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

  group('AgeStatus', () {
    test('unknown fails closed', () {
      const s = AgeStatus.unknown();
      expect(s.confirmed, isFalse);
      expect(s.adult, isFalse);
    });

    test('parses my_age_status payloads and treats junk as false', () {
      final adult = AgeStatus.fromJson({'confirmed': true, 'adult': true});
      expect(adult.confirmed, isTrue);
      expect(adult.adult, isTrue);

      final minor = AgeStatus.fromJson({'confirmed': true, 'adult': false});
      expect(minor.confirmed, isTrue);
      expect(minor.adult, isFalse);

      // A malformed payload must never read as adult.
      final junk = AgeStatus.fromJson({'confirmed': 'yes', 'adult': 1});
      expect(junk.confirmed, isFalse);
      expect(junk.adult, isFalse);
    });
  });

  group('computeDenial', () {
    const adult = AgeStatus(confirmed: true, adult: true);
    const minor = AgeStatus(confirmed: true, adult: false);
    const unconfirmed = AgeStatus.unknown();
    final paid = Entitlements.fromCodes([
      'direct_messaging',
      'create_taste_groups',
      'premium_profile_layouts',
      'advanced_trip_planning',
    ]);
    const unpaid = Entitlements.none();

    EntitlementDenial? denial({
      bool signedIn = true,
      AgeStatus age = adult,
      Entitlements? entitlements,
      PremiumEntitlement entitlement = PremiumEntitlement.directMessaging,
    }) => computeDenial(
      signedIn: signedIn,
      age: age,
      entitlements: entitlements ?? unpaid,
      entitlement: entitlement,
    );

    test('signed out always reads as notSignedIn', () {
      expect(denial(signedIn: false), EntitlementDenial.notSignedIn);
      expect(
        denial(signedIn: false, entitlements: paid),
        EntitlementDenial.notSignedIn,
      );
    });

    test('a minor is age-restricted from messaging even when unpaid', () {
      // THE rule of M3: a minor without premium must get the age refusal, not
      // premiumRequired - premiumRequired is what routes to the paywall.
      expect(denial(age: minor), EntitlementDenial.ageRestricted);
      expect(
        denial(age: minor, entitlements: paid),
        EntitlementDenial.ageRestricted,
      );
    });

    test('unconfirmed age asks for confirmation before anything else', () {
      expect(denial(age: unconfirmed), EntitlementDenial.ageUnconfirmed);
      expect(
        denial(age: unconfirmed, entitlements: paid),
        EntitlementDenial.ageUnconfirmed,
      );
    });

    test('an unpaid adult is offered the upgrade', () {
      final d = denial(age: adult);
      expect(d, EntitlementDenial.premiumRequired);
      expect(d!.canBeSolvedByUpgrading, isTrue);
    });

    test('a paid adult passes', () {
      expect(denial(age: adult, entitlements: paid), isNull);
    });

    test('non-restricted entitlements ignore age entirely', () {
      for (final e in PremiumEntitlement.values.where((e) => !e.adultsOnly)) {
        expect(
          denial(age: minor, entitlement: e),
          EntitlementDenial.premiumRequired,
          reason: e.name,
        );
        expect(
          denial(age: minor, entitlements: paid, entitlement: e),
          isNull,
          reason: e.name,
        );
      }
    });

    test('only messaging is adults-only', () {
      // Mirrors the server's adults_only_entitlements() seed. If this fails,
      // update BOTH sides deliberately, not just this test.
      expect(
        PremiumEntitlement.values.where((e) => e.adultsOnly),
        [PremiumEntitlement.directMessaging],
      );
    });
  });
}
