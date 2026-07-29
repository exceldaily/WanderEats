/// One restaurant in a BiteSwipe deck, already ranked server-side.
///
/// [reason] is the human explanation of why this surfaced ("Recommended by
/// someone you follow"), and [viaTasterId] is the Taster responsible for it —
/// both come from the ranking function so the UI never has to re-derive intent.
class SwipeCard {
  const SwipeCard({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.reason,
    this.priceLevel,
    this.distanceM,
    this.score,
    this.recCount = 0,
    this.saveCount = 0,
    this.coverPhotoUrl,
    this.cityName,
    this.viaTasterId,
  });

  final String id;
  final String name;
  final double lat;
  final double lng;
  final String reason;
  final int? priceLevel;
  final double? distanceM;
  final double? score;
  final int recCount;
  final int saveCount;
  final String? coverPhotoUrl;
  final String? cityName;
  final String? viaTasterId;

  String get priceLabel => priceLevel == null ? '' : '\$' * priceLevel!;

  String get distanceLabel {
    final d = distanceM;
    if (d == null) return '';
    return d < 1000 ? '${d.round()} m' : '${(d / 1000).toStringAsFixed(1)} km';
  }

  /// Short line under the name: price, distance, city — whichever we have.
  String get subtitle => [
    if (priceLabel.isNotEmpty) priceLabel,
    if (distanceLabel.isNotEmpty) distanceLabel,
    if (cityName != null && cityName!.isNotEmpty) cityName!,
  ].join(' · ');

  static double? _d(Object? v) => v is num ? v.toDouble() : null;
  static int _i(Object? v) => v is num ? v.toInt() : 0;

  factory SwipeCard.fromJson(Map<String, dynamic> json) => SwipeCard(
    id: json['id'] as String,
    name: (json['name'] ?? 'Unnamed').toString(),
    lat: _d(json['lat']) ?? 0,
    lng: _d(json['lng']) ?? 0,
    reason: (json['reason'] ?? 'Nearby').toString(),
    priceLevel: json['price_level'] is num
        ? (json['price_level'] as num).toInt()
        : null,
    distanceM: _d(json['distance_m']),
    score: _d(json['score']),
    recCount: _i(json['rec_count']),
    saveCount: _i(json['save_count']),
    coverPhotoUrl: json['cover_photo_url'] as String?,
    cityName: json['city_name'] as String?,
    viaTasterId: json['via_taster_id'] as String?,
  );
}

/// Why a user passed on a place. Feeds ranking; never shown as judgement.
enum SkipReason {
  tooFar('too_far', 'Too far'),
  tooExpensive('too_expensive', 'Too expensive'),
  cuisine('cuisine', 'Not this cuisine'),
  visited('visited', 'Already visited'),
  notNow('not_now', 'Not right now');

  const SkipReason(this.wire, this.label);
  final String wire;
  final String label;
}
