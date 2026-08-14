import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/map_basemap.dart';

/// Loads the WanderBites basemap styles.
///
/// The styles strip generic POI clutter (banks, shops, transit noise) and warm
/// the palette to the brand, so the restaurants the app draws on top are the
/// most important thing on screen. Cached after first read: the JSON is small
/// but the map is rebuilt often.
class MapStyleService {
  MapStyleService(this._bundle);

  final AssetBundle _bundle;
  final Map<String, String> _cache = {};

  /// The style JSON for [basemap], or null when the map should draw its own
  /// imagery or the asset cannot be read. Null always means "use the provider
  /// default" - a missing style must never blank the map.
  Future<String?> styleFor(MapBasemap basemap, {required bool dark}) async {
    final path = basemap.styleAsset(dark: dark);
    if (path == null) return null;

    final cached = _cache[path];
    if (cached != null) return cached;
    try {
      final json = await _bundle.loadString(path);
      _cache[path] = json;
      return json;
    } catch (_) {
      return null;
    }
  }
}

final mapStyleServiceProvider = Provider<MapStyleService>(
  (ref) => MapStyleService(rootBundle),
);

/// The user's chosen basemap, persisted across launches.
///
/// A display preference belongs on the device, not the account: it is about
/// this screen in this light, and it should apply instantly with no network.
class MapBasemapController extends AsyncNotifier<MapBasemap> {
  static const _key = 'wb_map_basemap_v1';

  @override
  Future<MapBasemap> build() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return MapBasemap.fromName(prefs.getString(_key));
    } catch (_) {
      return MapBasemap.auto;
    }
  }

  Future<void> select(MapBasemap basemap) async {
    state = AsyncData(basemap);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, basemap.name);
    } catch (_) {
      // A failed write only costs the preference on next launch; the map is
      // already showing the choice, so never surface this.
    }
  }
}

final mapBasemapProvider = AsyncNotifierProvider<MapBasemapController, MapBasemap>(
  MapBasemapController.new,
);

/// The style string for the chosen basemap under the current brightness.
final mapStyleProvider = FutureProvider.family<String?, ({MapBasemap basemap, bool dark})>(
  (ref, args) =>
      ref.watch(mapStyleServiceProvider).styleFor(args.basemap, dark: args.dark),
);
