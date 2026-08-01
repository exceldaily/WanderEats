/// The paid capabilities WanderBites sells.
///
/// Wire values match `subscription_products.entitlements` in the database and
/// the codes `has_entitlement()` checks. Nothing in the app should compare
/// against a raw string; that is how a typo silently becomes "this feature is
/// free for everyone".
enum PremiumEntitlement {
  directMessaging('direct_messaging'),
  createTasteGroups('create_taste_groups'),
  premiumProfileLayouts('premium_profile_layouts'),
  advancedTripPlanning('advanced_trip_planning');

  const PremiumEntitlement(this.code);

  final String code;

  static PremiumEntitlement? fromCode(String code) {
    for (final e in values) {
      if (e.code == code) return e;
    }
    return null;
  }
}

/// Why a premium feature is unavailable.
///
/// Kept distinct from "not premium" on purpose. The brief is explicit that an
/// under-18 account must never be shown a purchase screen as a way to unlock
/// messaging, so the reason has to travel with the refusal rather than being
/// inferred as "must need to pay".
enum EntitlementDenial {
  notSignedIn,
  premiumRequired,
  ageRestricted,
  ageUnconfirmed,
  disabledInSettings,
  accountRestricted;

  /// Whether offering an upgrade is an appropriate response. Buying premium
  /// cannot fix an age restriction, and implying it can would be worse than
  /// unhelpful.
  bool get canBeSolvedByUpgrading => this == EntitlementDenial.premiumRequired;
}

/// The signed-in user's paid access, as computed by the server.
///
/// Deliberately has no constructor that takes "isPremium": there is no such
/// concept, only a set of entitlements the backend derived from store-verified
/// subscriptions.
class Entitlements {
  const Entitlements(this._granted);

  const Entitlements.none() : _granted = const {};

  final Set<PremiumEntitlement> _granted;

  factory Entitlements.fromCodes(Iterable<String> codes) {
    final parsed = <PremiumEntitlement>{};
    for (final c in codes) {
      final e = PremiumEntitlement.fromCode(c);
      // Unknown codes are ignored rather than throwing: the server may know
      // about an entitlement this build predates, and that should not crash a
      // launch path.
      if (e != null) parsed.add(e);
    }
    return Entitlements(parsed);
  }

  bool has(PremiumEntitlement e) => _granted.contains(e);

  /// True when any paid capability is active. For display only ("Premium"
  /// badge, settings row) and never as an access check, since products may
  /// grant different subsets over time.
  bool get isPremium => _granted.isNotEmpty;

  Set<PremiumEntitlement> get granted => Set.unmodifiable(_granted);

  @override
  bool operator ==(Object other) =>
      other is Entitlements &&
      other._granted.length == _granted.length &&
      other._granted.containsAll(_granted);

  @override
  int get hashCode => Object.hashAllUnordered(_granted);
}
