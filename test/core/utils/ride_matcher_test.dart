import 'package:acepool/core/utils/ride_matcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RideMatcher.distanceKm', () {
    test('returns 0 for identical points', () {
      expect(RideMatcher.distanceKm(12.9716, 77.5946, 12.9716, 77.5946), closeTo(0, 1e-9));
    });

    test('computes the known distance between two well-known coordinates', () {
      // New York (40.7128, -74.0060) to London (51.5074, -0.1278):
      // widely cited great-circle distance is ~5570 km.
      final km = RideMatcher.distanceKm(40.7128, -74.0060, 51.5074, -0.1278);
      expect(km, closeTo(5570, 30));
    });

    test('computes a known short distance accurately (~1 degree latitude ~= 111km)', () {
      final km = RideMatcher.distanceKm(0, 0, 1, 0);
      expect(km, closeTo(111.19, 1));
    });

    test('is symmetric', () {
      final a = RideMatcher.distanceKm(12.9716, 77.5946, 13.0827, 80.2707);
      final b = RideMatcher.distanceKm(13.0827, 80.2707, 12.9716, 77.5946);
      expect(a, closeTo(b, 1e-9));
    });
  });

  group('RideMatcher.routeDeviationKm', () {
    test('returns ~0 when P sits exactly on the route between A and B', () {
      // Midpoint of a straight line between A and B.
      const aLat = 0.0, aLng = 0.0, bLat = 0.0, bLng = 2.0;
      const pLat = 0.0, pLng = 1.0;
      final deviation = RideMatcher.routeDeviationKm(aLat, aLng, pLat, pLng, bLat, bLng);
      expect(deviation, closeTo(0, 1e-6));
    });

    test('returns a large value when P is far off the route', () {
      const aLat = 0.0, aLng = 0.0, bLat = 0.0, bLng = 2.0;
      const pLat = 5.0, pLng = 1.0;
      final deviation = RideMatcher.routeDeviationKm(aLat, aLng, pLat, pLng, bLat, bLng);
      expect(deviation, greaterThan(100));
    });
  });

  group('RideMatcher.routeProgress', () {
    test('returns 0 when direct distance between A and B is 0', () {
      expect(RideMatcher.routeProgress(1, 1, 5, 5, 1, 1), 0);
    });

    test('returns ~0.5 for the midpoint of the route', () {
      final progress = RideMatcher.routeProgress(0, 0, 0, 1, 0, 2);
      expect(progress, closeTo(0.5, 0.01));
    });

    test('returns ~0 for a point at the start', () {
      final progress = RideMatcher.routeProgress(0, 0, 0, 0, 0, 2);
      expect(progress, closeTo(0, 0.01));
    });

    test('clamps to 1 when P is past the end', () {
      final progress = RideMatcher.routeProgress(0, 0, 0, 5, 0, 2);
      expect(progress, 1);
    });

    test('clamps to a maximum of 1', () {
      final progress = RideMatcher.routeProgress(0, 0, 0, 100, 0, 2);
      expect(progress, lessThanOrEqualTo(1));
    });
  });

  group('RideMatcher.fuzzyAddressMatches', () {
    test('returns false when either string is empty', () {
      expect(RideMatcher.fuzzyAddressMatches('', 'MG Road'), isFalse);
      expect(RideMatcher.fuzzyAddressMatches('MG Road', ''), isFalse);
      expect(RideMatcher.fuzzyAddressMatches('', ''), isFalse);
    });

    test('returns true when one string contains the other (case-insensitive)', () {
      expect(RideMatcher.fuzzyAddressMatches('MG Road, Bangalore', 'mg road'), isTrue);
      expect(RideMatcher.fuzzyAddressMatches('mg road', 'MG Road, Bangalore'), isTrue);
    });

    test('returns true when a long word (>3 chars) is shared between the two', () {
      expect(
        RideMatcher.fuzzyAddressMatches('Koramangala 5th Block', 'Near Koramangala Signal'),
        isTrue,
      );
    });

    test('returns false when there is no meaningful overlap', () {
      expect(RideMatcher.fuzzyAddressMatches('Whitefield', 'Yelahanka'), isFalse);
    });

    test('ignores words of length <= 3 when checking word overlap', () {
      // Shared word "the" (3 chars) alone should not cause a match.
      expect(RideMatcher.fuzzyAddressMatches('near the big mall', 'far the old shop'), isFalse);
    });
  });

  group('RideMatcher.formatDistance', () {
    test('formats sub-km distances in meters, rounded', () {
      expect(RideMatcher.formatDistance(0.65), '650 m');
    });

    test('rounds meters to the nearest integer', () {
      expect(RideMatcher.formatDistance(0.1234), '123 m');
    });

    test('formats distances of 1km or more in km with one decimal place', () {
      expect(RideMatcher.formatDistance(3.2), '3.2 km');
    });

    test('formats exactly 1km as km, not meters (boundary)', () {
      expect(RideMatcher.formatDistance(1.0), '1.0 km');
    });

    test('formats just under 1km as meters (boundary)', () {
      expect(RideMatcher.formatDistance(0.999), '999 m');
    });
  });

  group('RideMatcher.formatDuration', () {
    test('returns "0 min" for zero minutes', () {
      expect(RideMatcher.formatDuration(0), '0 min');
    });

    test('returns "0 min" for negative minutes', () {
      expect(RideMatcher.formatDuration(-5), '0 min');
    });

    test('formats minutes under an hour as "N min"', () {
      expect(RideMatcher.formatDuration(45), '45 min');
    });

    test('formats exactly 59 minutes as "59 min" (boundary)', () {
      expect(RideMatcher.formatDuration(59), '59 min');
    });

    test('formats exactly 60 minutes as "1h" with no minutes suffix', () {
      expect(RideMatcher.formatDuration(60), '1h');
    });

    test('formats an even number of hours as "Nh"', () {
      expect(RideMatcher.formatDuration(120), '2h');
    });

    test('formats hours + minutes as "NhMm"', () {
      expect(RideMatcher.formatDuration(80), '1h 20m');
    });
  });

  group('RideMatcher.projectPointToSegment', () {
    test('projects an interior point onto the segment', () {
      // Segment from (0,0) to (0,10); point (5, 5) should project to (0, 5).
      final result = RideMatcher.projectPointToSegment(0, 0, 0, 10, 5, 5);
      expect(result['latitude'], closeTo(0, 1e-9));
      expect(result['longitude'], closeTo(5, 1e-9));
    });

    test('clamps to the start point A when P projects before the segment', () {
      // Segment from (0,0) to (0,10); point (-5, -5) is "before" A.
      final result = RideMatcher.projectPointToSegment(0, 0, 0, 10, -5, -5);
      expect(result['latitude'], closeTo(0, 1e-9));
      expect(result['longitude'], closeTo(0, 1e-9));
    });

    test('clamps to the end point B when P projects past the segment', () {
      // Segment from (0,0) to (0,10); point (5, 15) is "past" B.
      final result = RideMatcher.projectPointToSegment(0, 0, 0, 10, 5, 15);
      expect(result['latitude'], closeTo(0, 1e-9));
      expect(result['longitude'], closeTo(10, 1e-9));
    });

    test('returns point A when A and B are identical (zero-length segment)', () {
      final result = RideMatcher.projectPointToSegment(3, 4, 3, 4, 10, 10);
      expect(result['latitude'], 3);
      expect(result['longitude'], 4);
    });

    test('projects a point on a diagonal segment correctly', () {
      // Segment from (0,0) to (10,10); point (0,10) should project to the
      // midpoint (5,5).
      final result = RideMatcher.projectPointToSegment(0, 0, 10, 10, 0, 10);
      expect(result['latitude'], closeTo(5, 1e-9));
      expect(result['longitude'], closeTo(5, 1e-9));
    });
  });

  group('RideMatcher.matchPercentFromDistance', () {
    test('returns 100 at 0 distance', () {
      expect(RideMatcher.matchPercentFromDistance(0), 100);
    });

    test('returns 0 at the default scale boundary (maxMatchDistanceKm)', () {
      expect(
        RideMatcher.matchPercentFromDistance(RideMatcher.maxMatchDistanceKm),
        0,
      );
    });

    test('returns 50 at half the default scale', () {
      expect(
        RideMatcher.matchPercentFromDistance(RideMatcher.maxMatchDistanceKm / 2),
        50,
      );
    });

    test('clamps distances beyond scaleKm to 0', () {
      expect(RideMatcher.matchPercentFromDistance(100, scaleKm: 2.0), 0);
    });

    test('respects a custom scaleKm', () {
      expect(RideMatcher.matchPercentFromDistance(5.0, scaleKm: 10.0), 50);
    });
  });

  group('RideMatcher.computeMatch - constants', () {
    test('maxMatchDistanceKm is 2.0', () {
      expect(RideMatcher.maxMatchDistanceKm, 2.0);
    });

    test('maxRouteDeviationKm is 5.0', () {
      expect(RideMatcher.maxRouteDeviationKm, 5.0);
    });
  });

  group('RideMatcher.computeMatch - missing coordinates (fuzzy fallback)', () {
    test('both addresses fuzzy-match -> 65% and isMatch true', () {
      final result = RideMatcher.computeMatch(
        userFromAddress: 'MG Road, Bangalore',
        userToAddress: 'Koramangala, Bangalore',
        rideFromAddress: 'MG Road',
        rideToAddress: 'Koramangala',
        matchRadiusKm: 2.0,
      );
      expect(result.matchPercent, 65);
      expect(result.distanceKm, isNull);
      expect(result.isMatch, isTrue);
    });

    test('only "to" address fuzzy-matches -> 50% and isMatch false', () {
      final result = RideMatcher.computeMatch(
        userFromAddress: 'Whitefield',
        userToAddress: 'Koramangala, Bangalore',
        rideFromAddress: 'Yelahanka',
        rideToAddress: 'Koramangala',
        matchRadiusKm: 2.0,
      );
      expect(result.matchPercent, 50);
      expect(result.isMatch, isFalse);
    });

    test('only "from" address fuzzy-matches -> 35% and isMatch false', () {
      final result = RideMatcher.computeMatch(
        userFromAddress: 'MG Road, Bangalore',
        userToAddress: 'Whitefield',
        rideFromAddress: 'MG Road',
        rideToAddress: 'Yelahanka',
        matchRadiusKm: 2.0,
      );
      expect(result.matchPercent, 35);
      expect(result.isMatch, isFalse);
    });

    test('neither address matches -> 20% and isMatch false', () {
      final result = RideMatcher.computeMatch(
        userFromAddress: 'Whitefield',
        userToAddress: 'Electronic City',
        rideFromAddress: 'Yelahanka',
        rideToAddress: 'Hebbal',
        matchRadiusKm: 2.0,
      );
      expect(result.matchPercent, 20);
      expect(result.isMatch, isFalse);
    });

    test('falls back to fuzzy matching when only user coords are missing', () {
      final result = RideMatcher.computeMatch(
        userFromAddress: 'MG Road',
        userToAddress: 'Koramangala',
        rideFromAddress: 'MG Road',
        rideToAddress: 'Koramangala',
        rideFromLat: 12.9,
        rideFromLng: 77.6,
        rideToLat: 12.93,
        rideToLng: 77.61,
        matchRadiusKm: 2.0,
      );
      expect(result.distanceKm, isNull);
      expect(result.isMatch, isTrue);
    });

    test('falls back to fuzzy matching when only ride coords are missing', () {
      final result = RideMatcher.computeMatch(
        userFromAddress: 'MG Road',
        userToAddress: 'Koramangala',
        userFromLat: 12.9,
        userFromLng: 77.6,
        userToLat: 12.93,
        userToLng: 77.61,
        rideFromAddress: 'MG Road',
        rideToAddress: 'Koramangala',
        matchRadiusKm: 2.0,
      );
      expect(result.distanceKm, isNull);
      expect(result.isMatch, isTrue);
    });
  });

  group('RideMatcher.computeMatch - endpoint matching with coordinates', () {
    test('isMatch true when both endpoints are within matchRadiusKm', () {
      const userFromLat = 12.9716, userFromLng = 77.5946;
      const userToLat = 12.9352, userToLng = 77.6146;
      final result = RideMatcher.computeMatch(
        userFromAddress: 'A',
        userToAddress: 'B',
        userFromLat: userFromLat,
        userFromLng: userFromLng,
        userToLat: userToLat,
        userToLng: userToLng,
        rideFromAddress: 'A2',
        rideToAddress: 'B2',
        // Ride endpoints ~0 distance away from user endpoints.
        rideFromLat: userFromLat,
        rideFromLng: userFromLng,
        rideToLat: userToLat,
        rideToLng: userToLng,
        matchRadiusKm: 2.0,
      );
      expect(result.isMatch, isTrue);
      expect(result.matchPercent, 100);
      expect(result.distanceKm, closeTo(0, 1e-6));
    });

    test('isMatch false when endpoints are farther than matchRadiusKm', () {
      final result = RideMatcher.computeMatch(
        userFromAddress: 'A',
        userToAddress: 'B',
        userFromLat: 12.9716,
        userFromLng: 77.5946,
        userToLat: 12.9352,
        userToLng: 77.6146,
        rideFromAddress: 'A2',
        rideToAddress: 'B2',
        // Ride endpoints far away (Chennai) - no fuzzy/route match either.
        rideFromLat: 13.0827,
        rideFromLng: 80.2707,
        rideToLat: 13.0674,
        rideToLng: 80.2376,
        matchRadiusKm: 2.0,
      );
      expect(result.isMatch, isFalse);
    });

    test('boundary: endpoints exactly at matchRadiusKm still count as a match (<=)', () {
      // Derive the "to" point's distance using the production distanceKm
      // function itself, then set matchRadiusKm to that exact value so the
      // <= boundary is hit with no floating-point slop.
      const rideToLat = 12.9352, rideToLng = 77.6146;
      const userToLat = 12.9532; // ~2km north
      final exactToDistanceKm =
          RideMatcher.distanceKm(userToLat, rideToLng, rideToLat, rideToLng);

      final result = RideMatcher.computeMatch(
        userFromAddress: 'A',
        userToAddress: 'B',
        userFromLat: 12.9716,
        userFromLng: 77.5946,
        userToLat: userToLat,
        userToLng: rideToLng,
        rideFromAddress: 'A2',
        rideToAddress: 'B2',
        rideFromLat: 12.9716,
        rideFromLng: 77.5946,
        rideToLat: rideToLat,
        rideToLng: rideToLng,
        matchRadiusKm: exactToDistanceKm,
      );
      // fromDistanceKm is ~0 (same from point); toDistanceKm exactly equals
      // matchRadiusKm by construction, so the <= comparison should still
      // count this as a match.
      expect(result.isMatch, isTrue);
    });

    test('just beyond matchRadiusKm does not count as a match', () {
      const rideToLat = 12.9352, rideToLng = 77.6146;
      const userToLat = 12.9532; // ~2km north
      final exactToDistanceKm =
          RideMatcher.distanceKm(userToLat, rideToLng, rideToLat, rideToLng);

      final result = RideMatcher.computeMatch(
        userFromAddress: 'A',
        userToAddress: 'B',
        userFromLat: 12.9716,
        userFromLng: 77.5946,
        userToLat: userToLat,
        userToLng: rideToLng,
        rideFromAddress: 'A2',
        rideToAddress: 'B2',
        rideFromLat: 12.9716,
        rideFromLng: 77.5946,
        rideToLat: rideToLat,
        rideToLng: rideToLng,
        // Just under the actual distance, so toDistanceKm > matchRadiusKm.
        matchRadiusKm: exactToDistanceKm - 0.001,
      );
      expect(result.isMatch, isFalse);
    });

    test('endpointsMatch percent uses a 10km scale on the worst-case endpoint distance', () {
      const userFromLat = 12.9716, userFromLng = 77.5946;
      const userToLat = 12.9352, userToLng = 77.6146;
      const rideFromLat = 12.9806; // ~1km north of userFromLat
      final worstKm =
          RideMatcher.distanceKm(userFromLat, userFromLng, rideFromLat, userFromLng);

      final result = RideMatcher.computeMatch(
        userFromAddress: 'A',
        userToAddress: 'B',
        userFromLat: userFromLat,
        userFromLng: userFromLng,
        userToLat: userToLat,
        userToLng: userToLng,
        rideFromAddress: 'A2',
        rideToAddress: 'B2',
        // Within matchRadiusKm (2.0), so endpointsMatch stays true; percent
        // should be scaled by the worst endpoint distance over a 10km scale.
        rideFromLat: rideFromLat,
        rideFromLng: userFromLng,
        rideToLat: userToLat,
        rideToLng: userToLng,
        matchRadiusKm: 2.0,
      );
      expect(result.isMatch, isTrue);
      expect(result.matchPercent, RideMatcher.matchPercentFromDistance(worstKm, scaleKm: 10.0));
    });
  });

  // NOTE: `isMatch` on the returned RideMatchResult is always exactly
  // `endpointsMatch` (both the user's from/to points within matchRadiusKm of
  // the ride's own from/to points) - the straight-line route-deviation
  // approximation (routeDeviationKm/routeProgress -> the local `onRoute`
  // variable) and `liveDetourKm` are computed but only ever feed into
  // `matchPercent` (and only in the branch taken when endpointsMatch is
  // false); neither can flip `isMatch` to true. This was verified by reading
  // lib/core/utils/ride_matcher.dart's computeMatch return statement, which
  // literally returns `isMatch: endpointsMatch`. The groups below test the
  // real, percent-only effect of route-deviation/liveDetourKm rather than
  // the isMatch-flipping behavior the doc comments on computeMatch imply.
  group('RideMatcher.computeMatch - off-route deviation only affects matchPercent, not isMatch', () {
    test('a point lying on the straight-line route yields a high matchPercent despite isMatch being false', () {
      // Driver goes from (0,0) to (0,10). Rider's from/to are far from the
      // driver's own endpoints (so endpointsMatch is false / isMatch stays
      // false) but sit right on the line between them (near-zero deviation).
      final result = RideMatcher.computeMatch(
        userFromAddress: 'Mid start',
        userToAddress: 'Mid end',
        userFromLat: 0,
        userFromLng: 5,
        userToLat: 0,
        userToLng: 8,
        rideFromAddress: 'Driver start',
        rideToAddress: 'Driver end',
        rideFromLat: 0,
        rideFromLng: 0,
        rideToLat: 0,
        rideToLng: 10,
        matchRadiusKm: 1.0,
      );
      expect(result.isMatch, isFalse);
      expect(result.matchPercent, 100);
    });

    test('a point far from the route yields matchPercent 0 and isMatch false', () {
      final result = RideMatcher.computeMatch(
        userFromAddress: 'Off route start',
        userToAddress: 'Off route end',
        userFromLat: 5,
        userFromLng: 5,
        userToLat: 5,
        userToLng: 8,
        rideFromAddress: 'Driver start',
        rideToAddress: 'Driver end',
        rideFromLat: 0,
        rideFromLng: 0,
        rideToLat: 0,
        rideToLng: 10,
        matchRadiusKm: 1.0,
      );
      expect(result.isMatch, isFalse);
      expect(result.matchPercent, 0);
    });
  });

  group('RideMatcher.computeMatch - liveDetourKm overrides the deviation used for matchPercent (isMatch unaffected)', () {
    test('a small non-negative liveDetourKm yields a high matchPercent, but isMatch stays false', () {
      final result = RideMatcher.computeMatch(
        userFromAddress: 'A',
        userToAddress: 'B',
        userFromLat: 5,
        userFromLng: 5,
        userToLat: 5,
        userToLng: 8,
        rideFromAddress: 'Driver start',
        rideToAddress: 'Driver end',
        rideFromLat: 0,
        rideFromLng: 0,
        rideToLat: 0,
        rideToLng: 10,
        // Straight-line deviation here would be large (points are far off the
        // line), but liveDetourKm overrides that approximation for percent.
        liveDetourKm: 0.5,
        matchRadiusKm: 1.0,
      );
      expect(result.isMatch, isFalse);
      expect(result.matchPercent, RideMatcher.matchPercentFromDistance(0.5, scaleKm: 1.0));
    });

    test('a large liveDetourKm beyond matchRadiusKm yields matchPercent 0', () {
      final result = RideMatcher.computeMatch(
        userFromAddress: 'A',
        userToAddress: 'B',
        userFromLat: 5,
        userFromLng: 5,
        userToLat: 5,
        userToLng: 8,
        rideFromAddress: 'Driver start',
        rideToAddress: 'Driver end',
        rideFromLat: 0,
        rideFromLng: 0,
        rideToLat: 0,
        rideToLng: 10,
        liveDetourKm: 50.0,
        matchRadiusKm: 1.0,
      );
      expect(result.isMatch, isFalse);
      expect(result.matchPercent, 0);
    });

    test('a negative liveDetourKm is clamped to 0, yielding matchPercent 100', () {
      final result = RideMatcher.computeMatch(
        userFromAddress: 'A',
        userToAddress: 'B',
        userFromLat: 5,
        userFromLng: 5,
        userToLat: 5,
        userToLng: 8,
        rideFromAddress: 'Driver start',
        rideToAddress: 'Driver end',
        rideFromLat: 0,
        rideFromLng: 0,
        rideToLat: 0,
        rideToLng: 10,
        liveDetourKm: -3.0,
        matchRadiusKm: 1.0,
      );
      expect(result.isMatch, isFalse);
      expect(result.matchPercent, 100);
    });

    test('liveDetourKm boundary: exactly matchRadiusKm yields matchPercent 0', () {
      final result = RideMatcher.computeMatch(
        userFromAddress: 'A',
        userToAddress: 'B',
        userFromLat: 5,
        userFromLng: 5,
        userToLat: 5,
        userToLng: 8,
        rideFromAddress: 'Driver start',
        rideToAddress: 'Driver end',
        rideFromLat: 0,
        rideFromLng: 0,
        rideToLat: 0,
        rideToLng: 10,
        liveDetourKm: 1.0,
        matchRadiusKm: 1.0,
      );
      expect(result.isMatch, isFalse);
      expect(result.matchPercent, 0);
    });
  });

  group('RideMatchResult', () {
    test('exposes matchPercent, distanceKm, and isMatch fields', () {
      const result = RideMatchResult(matchPercent: 80, distanceKm: 1.5, isMatch: true);
      expect(result.matchPercent, 80);
      expect(result.distanceKm, 1.5);
      expect(result.isMatch, isTrue);
    });

    test('distanceKm can be null', () {
      const result = RideMatchResult(matchPercent: 20, distanceKm: null, isMatch: false);
      expect(result.distanceKm, isNull);
    });
  });
}
