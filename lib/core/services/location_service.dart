import 'package:geolocator/geolocator.dart';

/// Device GPS access, mirroring the "never throw, return null on any
/// failure" convention used by [PlacesService]/[DirectionsService] — callers
/// treat a null result the same as "location unavailable" (services off,
/// permission denied, timeout, etc) without needing separate error handling.
class LocationService {
  /// Requests location permission if not already granted, then resolves the
  /// device's current position. Safe to call repeatedly: once permission is
  /// already granted this resolves without prompting again, which is what
  /// lets a caller retry later (e.g. at "Find ride" time) after an earlier
  /// call returned null due to a not-yet-answered/denied prompt.
  Future<Position?> getCurrentLocation() async {
    try {
      // Permission is asked first, independent of the device's location
      // service (GPS) toggle — that way the OS permission prompt always
      // fires on first use, even if GPS happens to be off at the time.
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      if (!await Geolocator.isLocationServiceEnabled()) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      ).timeout(const Duration(seconds: 10));
    } catch (_) {
      return null;
    }
  }

  /// Whether the device's location service (GPS) is currently turned on.
  /// Used by callers that want to prompt the user to enable it before
  /// attempting a fetch, rather than silently getting a null position back.
  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();
}
