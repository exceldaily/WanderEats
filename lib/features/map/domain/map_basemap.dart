/// The basemap the user has chosen.
///
/// Brightness is a real comfort issue on a phone at full backlight, so this is
/// a user setting rather than a fixed brand decision: the same map that looks
/// crisp in daylight is glaring at night. Two of these options are not styled
/// JSON at all but Google's own raster layers, which is the cheapest way to
/// offer genuinely different terrain.
enum MapBasemap {
  /// Follows the app theme: warm in light mode, charcoal in dark.
  auto,

  /// The WanderBites signature look. Warm cream land, brightest option.
  warm,

  /// Cooler and a few shades darker than [warm]. Easier on the eyes for long
  /// sessions without going full dark.
  slate,

  /// Muted green-grey. The most subdued of the light options.
  sage,

  /// Charcoal, regardless of app theme.
  night,

  /// Google's terrain raster: real relief shading, contours and landcover.
  terrain,

  /// Google's satellite imagery with road and place labels on top.
  satellite;

  String get label => switch (this) {
    MapBasemap.auto => 'Automatic',
    MapBasemap.warm => 'Warm',
    MapBasemap.slate => 'Slate',
    MapBasemap.sage => 'Sage',
    MapBasemap.night => 'Night',
    MapBasemap.terrain => 'Terrain',
    MapBasemap.satellite => 'Satellite',
  };

  String get description => switch (this) {
    MapBasemap.auto => 'Matches your light or dark theme',
    MapBasemap.warm => 'The WanderBites look, brightest',
    MapBasemap.slate => 'Cooler and dimmer',
    MapBasemap.sage => 'Muted green, easiest on the eyes',
    MapBasemap.night => 'Dark, whatever your theme',
    MapBasemap.terrain => 'Relief and landcover',
    MapBasemap.satellite => 'Aerial imagery with labels',
  };

  /// The style asset for this basemap, or null when the provider draws its own
  /// imagery (terrain and satellite ignore styling).
  ///
  /// [dark] only matters for [auto]; every other option is an explicit choice
  /// and must not flip with the theme.
  String? styleAsset({required bool dark}) => switch (this) {
    MapBasemap.auto => dark
        ? 'assets/map/wanderbites_dark.json'
        : 'assets/map/wanderbites_light.json',
    MapBasemap.warm => 'assets/map/wanderbites_light.json',
    MapBasemap.slate => 'assets/map/wanderbites_slate.json',
    MapBasemap.sage => 'assets/map/wanderbites_sage.json',
    MapBasemap.night => 'assets/map/wanderbites_dark.json',
    MapBasemap.terrain || MapBasemap.satellite => null,
  };

  /// Whether pins sit on imagery rather than a flat style. Imagery is busy and
  /// dark, so pins need a brighter treatment over it.
  bool get isImagery => this == MapBasemap.terrain || this == MapBasemap.satellite;

  static MapBasemap fromName(String? name) =>
      MapBasemap.values.firstWhere((b) => b.name == name, orElse: () => MapBasemap.auto);
}
