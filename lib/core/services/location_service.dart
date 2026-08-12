import 'package:geolocator/geolocator.dart';

/// Device GPS access, mirroring the "never throw, return null on any
/// failure" convention used by [PlacesService]/[DirectionsService] — callers
/// treat a null result the same as "location unavailable" (services off,
/// permission denied, timeout, etc) without needing separate error handling.
typedef _CheckPermission = Future<LocationPermission> Function();
typedef _RequestPermission = Future<LocationPermission> Function();
typedef _IsLocationServiceEnabled = Future<bool> Function();
typedef _GetCurrentPosition = Future<Position> Function({
  LocationSettings? locationSettings,
});

class LocationService {
  LocationService({
    _CheckPermission? checkPermission,
    _RequestPermission? requestPermission,
    _IsLocationServiceEnabled? isLocationServiceEnabled,
    _GetCurrentPosition? getCurrentPosition,
  })  : _checkPermission = checkPermission ?? Geolocator.checkPermission,
        _requestPermission = requestPermission ?? Geolocator.requestPermission,
        _isLocationServiceEnabled =
            isLocationServiceEnabled ?? Geolocator.isLocationServiceEnabled,
        _getCurrentPosition = getCurrentPosition ?? Geolocator.getCurrentPosition;

  final _CheckPermission _checkPermission;
  final _RequestPermission _requestPermission;
  final _IsLocationServiceEnabled _isLocationServiceEnabled;
  final _GetCurrentPosition _getCurrentPosition;

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
      var permission = await _checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await _requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      if (!await _isLocationServiceEnabled()) return null;

      return await _getCurrentPosition(
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
  Future<bool> isServiceEnabled() => _isLocationServiceEnabled();
}
