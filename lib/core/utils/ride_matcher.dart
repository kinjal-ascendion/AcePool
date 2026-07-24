import 'dart:math' as math;

class RideMatcher {
  RideMatcher._();

  /// Radius (km) within which a candidate ride's endpoint is considered
  /// a plausible match for "nearest first" results once both sides have
  /// coordinates. 2km is a walking/short-cab distance to a meeting point.
  static const double maxMatchDistanceKm = 2.0;

  /// Max allowed detour (km) for a rider's pickup/drop point to still count
  /// as "on the way" along a driver's route, even when it's nowhere near
  /// either of the driver's own endpoints. Smaller than [maxMatchDistanceKm]
  /// since this represents extra driving distance, not just "nearby".
  static const double maxRouteDeviationKm = 5.0;

  static const double _earthRadiusKm = 6371.0;

  /// Haversine great-circle distance between two lat/lng points, in km.
  static double distanceKm(double lat1, double lng1, double lat2, double lng2) {
    final dLat = _degToRad(lat2 - lat1);
    final dLng = _degToRad(lng2 - lng1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return _earthRadiusKm * c;
  }

  static double _degToRad(double deg) => deg * (math.pi / 180.0);

  /// How far point P deviates from lying on the straight-line route between
  /// A and B, via the triangle-inequality slack: d(A,P) + d(P,B) - d(A,B).
  /// ~0km means P sits right on the route between A and B; large values mean
  /// visiting P would be a big detour off that route. Used to catch riders
  /// whose pickup/drop is somewhere in between a driver's start and end,
  /// not just near one of the driver's own endpoints.
  static double routeDeviationKm(
    double aLat,
    double aLng,
    double pLat,
    double pLng,
    double bLat,
    double bLng,
  ) {
    final viaP =
        distanceKm(aLat, aLng, pLat, pLng) + distanceKm(pLat, pLng, bLat, bLng);
    final direct = distanceKm(aLat, aLng, bLat, bLng);
    return viaP - direct;
  }

  /// Fraction (roughly 0-1) of how far along the route from A to B point P
  /// falls, used to check that a pickup comes before a drop-off in the same
  /// direction the driver is travelling. Only meaningful when P is close to
  /// the route (see [routeDeviationKm]); values are clamped to [0, 1].
  static double routeProgress(
    double aLat,
    double aLng,
    double pLat,
    double pLng,
    double bLat,
    double bLng,
  ) {
    final direct = distanceKm(aLat, aLng, bLat, bLng);
    if (direct <= 0) return 0;
    final fromStart = distanceKm(aLat, aLng, pLat, pLng);
    return (fromStart / direct).clamp(0, 1);
  }

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

  /// Human-friendly distance label, e.g. "650 m" / "3.2 km".
  static String formatDistance(double km) {
    if (km < 1) {
      return '${(km * 1000).round()} m';
    }
    return '${km.toStringAsFixed(1)} km';
  }

  /// Calculates the point on the line segment AB that is closest to point P.
  /// Used to find the "on the road" drop-off/pick-up point for along-the-route
  /// matches where the driver isn't detouring to the rider's building.
  static Map<String, double> projectPointToSegment(
    double aLat,
    double aLng,
    double bLat,
    double bLng,
    double pLat,
    double pLng,
  ) {
    final double l2 = _distSq(aLat, aLng, bLat, bLng);
    if (l2 == 0) return {'latitude': aLat, 'longitude': aLng};
    
    // t is the projection fraction along the line AB
    final double t = (((pLat - aLat) * (bLat - aLat) + (pLng - aLng) * (bLng - aLng)) / l2).clamp(0.0, 1.0);
    
    return {
      'latitude': aLat + t * (bLat - aLat),
      'longitude': aLng + t * (bLng - aLng),
    };
  }

  static double _distSq(double lat1, double lng1, double lat2, double lng2) {
    return (lat1 - lat2) * (lat1 - lat2) + (lng1 - lng2) * (lng1 - lng2);
  }

  /// Converts a distance into a 0-100 match score: 0km -> 100%, tapering
  /// linearly to 0% at [scaleKm] (defaults to [maxMatchDistanceKm]).
  static int matchPercentFromDistance(
    double km, {
    double scaleKm = maxMatchDistanceKm,
  }) {
    final clamped = km.clamp(0, scaleKm);
    return (100 * (1 - clamped / scaleKm)).round();
  }

  /// Single shared match computation used by both the Find-ride search and
  /// the Trips tab's Rides list, so match % stays consistent everywhere.
  ///
  /// [liveDetourKm], when provided, is the *real road* extra distance
  /// (fetched live from Google Directions with the user's points forced in as
  /// waypoints, minus the ride's own direct route distance) of detouring via
  /// the user's from/to points — this is what lets a rider whose pickup/drop
  /// is along the actual road, but off the straight geometric line between
  /// the ride's endpoints, still count as a match. When null (no live Google
  /// result available — missing key, request failed, etc), falls back to the
  /// straight-line [routeDeviationKm]/[routeProgress] approximation.
  static RideMatchResult computeMatch({
    required String userFromAddress,
    required String userToAddress,
    double? userFromLat,
    double? userFromLng,
    double? userToLat,
    double? userToLng,
    required String rideFromAddress,
    required String rideToAddress,
    double? rideFromLat,
    double? rideFromLng,
    double? rideToLat,
    double? rideToLng,
    double? liveDetourKm,
  }) {
    final haveUserCoords =
        userFromLat != null &&
        userFromLng != null &&
        userToLat != null &&
        userToLng != null;
    final haveRideCoords =
        rideFromLat != null &&
        rideFromLng != null &&
        rideToLat != null &&
        rideToLng != null;

    if (!haveUserCoords || !haveRideCoords) {
      final fromMatch = fuzzyAddressMatches(userFromAddress, rideFromAddress);
      final toMatch = fuzzyAddressMatches(userToAddress, rideToAddress);
      int percent;
      if (fromMatch && toMatch) {
        percent = 65;
      } else if (toMatch) {
        percent = 50;
      } else if (fromMatch) {
        percent = 35;
      } else {
        percent = 20;
      }
      return RideMatchResult(
        matchPercent: percent,
        distanceKm: null,
        isMatch: fromMatch && toMatch,
      );
    }

    final fromDistanceKm = distanceKm(
      userFromLat,
      userFromLng,
      rideFromLat,
      rideFromLng,
    );
    final toDistanceKm = distanceKm(userToLat, userToLng, rideToLat, rideToLng);
    final endpointsMatch =
        fromDistanceKm <= maxMatchDistanceKm &&
        toDistanceKm <= maxMatchDistanceKm;

    final double deviationKm;
    bool onRoute;
    if (liveDetourKm != null) {
      deviationKm = liveDetourKm < 0 ? 0 : liveDetourKm;
      onRoute = deviationKm <= maxRouteDeviationKm;
    } else {
      final fromDeviationKm = routeDeviationKm(
        rideFromLat,
        rideFromLng,
        userFromLat,
        userFromLng,
        rideToLat,
        rideToLng,
      );
      final toDeviationKm = routeDeviationKm(
        rideFromLat,
        rideFromLng,
        userToLat,
        userToLng,
        rideToLat,
        rideToLng,
      );
      final fromProgress = routeProgress(
        rideFromLat,
        rideFromLng,
        userFromLat,
        userFromLng,
        rideToLat,
        rideToLng,
      );
      final toProgress = routeProgress(
        rideFromLat,
        rideFromLng,
        userToLat,
        userToLng,
        rideToLat,
        rideToLng,
      );
      deviationKm = fromDeviationKm > toDeviationKm
          ? fromDeviationKm
          : toDeviationKm;
      onRoute =
          deviationKm <= maxRouteDeviationKm && fromProgress <= toProgress;
    }

    final int percent;
    if (endpointsMatch) {
      final worstKm = fromDistanceKm > toDistanceKm
          ? fromDistanceKm
          : toDistanceKm;
      percent = matchPercentFromDistance(worstKm, scaleKm: 10.0);
    } else {
      percent = matchPercentFromDistance(
        deviationKm,
        scaleKm: maxRouteDeviationKm,
      );
    }

    // Distance to show the user: distance to the driver's start if they're
    // close, otherwise the distance they'd have to deviate to meet the
    // driver (the deviation slack).
    final displayDistanceKm = endpointsMatch ? fromDistanceKm : deviationKm;

    return RideMatchResult(
      matchPercent: percent,
      distanceKm: fromDistanceKm,
      isMatch: endpointsMatch || onRoute,
    );
  }
}

/// Result of [RideMatcher.computeMatch]: how well a user's from/to compares
/// to a candidate ride's from/to.
class RideMatchResult {
  const RideMatchResult({
    required this.matchPercent,
    required this.distanceKm,
    required this.isMatch,
  });

  /// 0-100 match score.
  final int matchPercent;

  /// Distance (km) from the user's start point to the ride's start point,
  /// or null when neither side has coordinates (fuzzy address match only).
  final double? distanceKm;

  /// Whether this candidate counts as a match at all — either near both of
  /// the ride's endpoints, or on the ride's route in between them.
  final bool isMatch;
}
