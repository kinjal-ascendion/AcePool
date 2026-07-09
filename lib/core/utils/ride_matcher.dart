import 'dart:math' as math;

class RideMatcher {
  RideMatcher._();

  /// Radius (km) within which a candidate ride's endpoint is considered
  /// a plausible match for "nearest first" results once both sides have
  /// coordinates. 25km is a generous metro-commute radius: wide enough to
  /// catch a suburb/locality geocoded to a slightly different point than
  /// expected, tight enough to exclude a different city entirely.
  static const double maxMatchDistanceKm = 25.0;

  static const double _earthRadiusKm = 6371.0;

  /// Haversine great-circle distance between two lat/lng points, in km.
  static double distanceKm(double lat1, double lng1, double lat2, double lng2) {
    final dLat = _degToRad(lat2 - lat1);
    final dLng = _degToRad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return _earthRadiusKm * c;
  }

  static double _degToRad(double deg) => deg * (math.pi / 180.0);

  /// Lenient fuzzy address matching, used as a fallback when coordinates
  /// are missing on either side (legacy docs, or a malformed geocode).
  static bool fuzzyAddressMatches(String a, String b) {
    if (a.isEmpty || b.isEmpty) return false;
    final an = a.toLowerCase().trim();
    final bn = b.toLowerCase().trim();
    if (an.contains(bn) || bn.contains(an)) return true;
    return an
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 3)
        .any((w) => bn.contains(w));
  }

  /// Human-friendly "away" label, e.g. "650 m away" / "3.2 km away".
  static String formatDistance(double km) {
    if (km < 1) {
      return '${(km * 1000).round()} m away';
    }
    return '${km.toStringAsFixed(1)} km away';
  }

  /// Converts a distance into a 0-100 match score: 0km -> 100%, tapering
  /// linearly to 0% at [maxMatchDistanceKm].
  static int matchPercentFromDistance(double km) {
    final clamped = km.clamp(0, maxMatchDistanceKm);
    return (100 * (1 - clamped / maxMatchDistanceKm)).round();
  }
}
