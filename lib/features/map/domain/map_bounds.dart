import 'dart:math' as math;

/// A geographic viewport, expressed as plain numbers.
///
/// The map feature deliberately does not speak the map SDK's own bounds type
/// outside the widget layer. Everything below the widget - controller, query
/// pipeline, tests - works on this, so swapping the rendering provider never
/// reaches into business logic, and the controller is testable without a
/// Flutter platform binding.
class WbBounds {
  const WbBounds({
    required this.minLat,
    required this.minLng,
    required this.maxLat,
    required this.maxLng,
  });

  final double minLat;
  final double minLng;
  final double maxLat;
  final double maxLng;

  double get spanLat => (maxLat - minLat).abs();

  /// Longitude span, correct across the antimeridian (where minLng > maxLng).
  double get spanLng =>
      crossesAntimeridian ? (180 - minLng) + (maxLng + 180) : (maxLng - minLng).abs();

  double get centerLat => (minLat + maxLat) / 2;

  double get centerLng {
    if (!crossesAntimeridian) return (minLng + maxLng) / 2;
    final mid = minLng + spanLng / 2;
    return mid > 180 ? mid - 360 : mid;
  }

  /// True when the viewport straddles ±180°, which leaves the west edge east
  /// of the east edge. A single envelope cannot express this, so queries have
  /// to split it - see [split].
  bool get crossesAntimeridian => minLng > maxLng;

  /// The query-safe pieces of this viewport: one rectangle normally, two when
  /// it wraps the antimeridian. Callers query each and concatenate.
  List<WbBounds> split() {
    if (!crossesAntimeridian) return [this];
    return [
      WbBounds(minLat: minLat, minLng: minLng, maxLat: maxLat, maxLng: 180),
      WbBounds(minLat: minLat, minLng: -180, maxLat: maxLat, maxLng: maxLng),
    ];
  }

  /// Grows the viewport by [factor] of its own size on every edge. Fetching a
  /// little beyond the screen means small pans reuse the last result instead
  /// of firing a new query.
  WbBounds padded(double factor) {
    final dLat = spanLat * factor;
    final dLng = spanLng * factor;
    return WbBounds(
      minLat: math.max(-90, minLat - dLat),
      minLng: _wrapLng(minLng - dLng),
      maxLat: math.min(90, maxLat + dLat),
      maxLng: _wrapLng(maxLng + dLng),
    );
  }

  /// Whether [other] lies entirely inside this viewport. Used to decide that a
  /// camera move stayed within already-fetched territory.
  bool contains(WbBounds other) {
    if (crossesAntimeridian || other.crossesAntimeridian) return false;
    return other.minLat >= minLat &&
        other.maxLat <= maxLat &&
        other.minLng >= minLng &&
        other.maxLng <= maxLng;
  }

  static double _wrapLng(double lng) {
    if (lng > 180) return lng - 360;
    if (lng < -180) return lng + 360;
    return lng;
  }

  @override
  bool operator ==(Object other) =>
      other is WbBounds &&
      other.minLat == minLat &&
      other.minLng == minLng &&
      other.maxLat == maxLat &&
      other.maxLng == maxLng;

  @override
  int get hashCode => Object.hash(minLat, minLng, maxLat, maxLng);

  @override
  String toString() => 'WbBounds($minLat,$minLng .. $maxLat,$maxLng)';
}
