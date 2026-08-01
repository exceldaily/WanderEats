/// Reasons a user can give for reporting something.
///
/// The wire values are validated again in `wanderbites.report_content`, and
/// urgency is decided there rather than here: a client should not be able to
/// mark its own report urgent, and a safety category must escalate even if a
/// future client forgets to ask.
enum ReportReason {
  spam('spam', 'Spam'),
  harassment('harassment', 'Harassment or bullying'),
  hateOrAbuse('hate_or_abuse', 'Hate speech or abuse'),
  threateningBehavior('threatening_behavior', 'Threats or violence'),
  impersonation('impersonation', 'Pretending to be someone else'),
  scamOrFraud('scam_or_fraud', 'Scam or fraud'),
  sexualContent('sexual_content', 'Sexual content'),
  underageSafety('underage_safety_concern', 'Concern about a minor'),
  dangerousContent('dangerous_content', 'Dangerous content'),
  falseInformation('false_information', 'False information'),
  privacyViolation('privacy_violation', 'Shares private information'),
  copyright('copyright', 'Copyright'),
  inappropriateContent('inappropriate_content', 'Inappropriate content'),
  other('other', 'Something else');

  const ReportReason(this.wire, this.label);

  final String wire;
  final String label;

  /// Reasons offered when reporting a place rather than a person. Reporting a
  /// restaurant is nearly always about the listing being wrong, so the
  /// interpersonal categories would only be noise.
  static const forRestaurant = [
    ReportReason.falseInformation,
    ReportReason.inappropriateContent,
    ReportReason.spam,
    ReportReason.copyright,
    ReportReason.other,
  ];

  /// Reasons offered for anything authored by a person.
  static const forPerson = [
    ReportReason.harassment,
    ReportReason.hateOrAbuse,
    ReportReason.threateningBehavior,
    ReportReason.sexualContent,
    ReportReason.underageSafety,
    ReportReason.impersonation,
    ReportReason.scamOrFraud,
    ReportReason.spam,
    ReportReason.privacyViolation,
    ReportReason.falseInformation,
    ReportReason.dangerousContent,
    ReportReason.other,
  ];
}

/// What is being reported. Mirrors `target_owner` in the database, which maps
/// a target back to the account responsible for it.
enum ReportTarget {
  profile('profile'),
  recommendation('recommendation'),
  comment('comment'),
  list('list'),
  restaurant('restaurant'),
  photo('photo');

  const ReportTarget(this.wire);
  final String wire;

  /// Restaurants are places rather than people, so they get the listing-focused
  /// reason set and never offer "block this user" alongside.
  bool get isAuthoredByPerson => this != ReportTarget.restaurant;
}

/// Why someone blocked an account. Optional, private to the blocker, and never
/// shown to the blocked account.
enum BlockReason {
  harassment('harassment', 'Harassment'),
  spam('spam', 'Spam'),
  impersonation('impersonation', 'Impersonation'),
  inappropriateContent('inappropriate_content', 'Inappropriate content'),
  unwantedContact('unwanted_contact', 'Unwanted contact'),
  other('other', 'Something else');

  const BlockReason(this.wire, this.label);
  final String wire;
  final String label;
}

/// A row in the blocked-accounts settings screen.
class BlockedAccount {
  const BlockedAccount({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.reasonCategory,
    required this.blockedAt,
  });

  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final String? reasonCategory;
  final DateTime blockedAt;

  factory BlockedAccount.fromRow(Map<String, dynamic> row) => BlockedAccount(
    id: row['id'] as String,
    username: row['username'] as String? ?? '',
    displayName: row['display_name'] as String? ?? '',
    avatarUrl: row['avatar_url'] as String?,
    reasonCategory: row['reason_category'] as String?,
    blockedAt:
        DateTime.tryParse(row['created_at'] as String? ?? '')?.toLocal() ??
        DateTime.now(),
  );
}
