import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// Wraps geolocator with a permission flow the UI can reason about.
enum LocationStatus { granted, denied, deniedForever, serviceOff }

class LocationService {
  Future<LocationStatus> ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationStatus.serviceOff;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return switch (permission) {
      LocationPermission.deniedForever => LocationStatus.deniedForever,
      LocationPermission.denied => LocationStatus.denied,
      _ => LocationStatus.granted,
    };
  }

  Future<Position?> currentPosition() async {
    final status = await ensurePermission();
    if (status != LocationStatus.granted) return null;
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.medium),
      );
    } catch (_) {
      return Geolocator.getLastKnownPosition();
    }
  }
}

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});
