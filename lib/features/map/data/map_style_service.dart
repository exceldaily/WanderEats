import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Loads the WanderBites basemap styles.
///
/// The styles strip generic POI clutter (banks, shops, transit noise) and warm
/// the palette to the brand, so the restaurants the app draws on top are the
/// most important thing on screen. Cached after first read: the JSON is small
/// but the map is rebuilt often.
class MapStyleService {
  MapStyleService(this._bundle);

  final AssetBundle _bundle;
  final Map<Brightness, String> _cache = {};

  static const _paths = {
    Brightness.light: 'assets/map/wanderbites_light.json',
    Brightness.dark: 'assets/map/wanderbites_dark.json',
  };

  /// The style for [brightness], or null if it cannot be loaded. Null means
  /// "use the provider default" - a missing style must never blank the map.
  Future<String?> styleFor(Brightness brightness) async {
    final cached = _cache[brightness];
    if (cached != null) return cached;
    try {
      final json = await _bundle.loadString(_paths[brightness]!);
      _cache[brightness] = json;
      return json;
    } catch (_) {
      return null;
    }
  }
}

final mapStyleServiceProvider = Provider<MapStyleService>(
  (ref) => MapStyleService(rootBundle),
);

/// The style string for the current theme brightness.
final mapStyleProvider = FutureProvider.family<String?, Brightness>(
  (ref, brightness) => ref.watch(mapStyleServiceProvider).styleFor(brightness),
);
