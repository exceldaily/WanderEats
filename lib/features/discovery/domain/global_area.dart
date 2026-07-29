/// A place on the map you can travel to — a city, region or landmark — as
/// returned by worldwide search. Distinct from a `cities` row: an area may not
/// exist in our database at all until someone actually explores it.
class GlobalArea {
  const GlobalArea({
    required this.name,
    required this.lat,
    required this.lng,
    this.formattedAddress,
    this.country,
    this.neLat,
    this.neLng,
    this.swLat,
    this.swLng,
  });

  final String name;
  final double lat;
  final double lng;
  final String? formattedAddress;
  final String? country;

  /// Provider viewport, when present. Lets the map frame the whole place
  /// instead of guessing a zoom level that suits a city and a country equally.
  final double? neLat;
  final double? neLng;
  final double? swLat;
  final double? swLng;

  bool get hasViewport =>
      neLat != null && neLng != null && swLat != null && swLng != null;

  String get subtitle =>
      country == null || country == name ? (formattedAddress ?? '') : country!;

  static double? _d(Object? v) => v is num ? v.toDouble() : null;

  factory GlobalArea.fromJson(Map<String, dynamic> json) => GlobalArea(
    name: (json['name'] ?? 'Unknown').toString(),
    lat: _d(json['lat']) ?? 0,
    lng: _d(json['lng']) ?? 0,
    formattedAddress: json['formatted_address'] as String?,
    country: json['country'] as String?,
    neLat: _d(json['ne_lat']),
    neLng: _d(json['ne_lng']),
    swLat: _d(json['sw_lat']),
    swLng: _d(json['sw_lng']),
  );
}

/// Worldwide search payload: places to go, and restaurants found by name.
class GlobalSearchResults {
  const GlobalSearchResults({required this.areas, required this.restaurants});

  const GlobalSearchResults.empty() : areas = const [], restaurants = const [];

  final List<GlobalArea> areas;

  /// Already materialized server-side, so these behave like any other
  /// restaurant row the moment they appear.
  final List<Map<String, dynamic>> restaurants;

  bool get isEmpty => areas.isEmpty && restaurants.isEmpty;
}
