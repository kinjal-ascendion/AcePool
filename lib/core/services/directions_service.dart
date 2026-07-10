import 'dart:convert';

import 'package:acepool/core/constants/api_keys.dart';
import 'package:http/http.dart' as http;

/// Fetches real road-driving distances from the Google Directions API, so
/// ride matching can reason about actual route distance/detours instead of
/// straight-line geometry.
class DirectionsService {
  static const _baseUrl = 'https://maps.googleapis.com/maps/api/directions/json';

  /// Total driving distance (km) from (originLat, originLng) to
  /// (destLat, destLng). When [waypoints] is non-empty, the route is forced
  /// through each `[lat, lng]` pair in the given order (no reordering) before
  /// reaching the destination — summing every leg's distance gives the real
  /// road distance of detouring via those points.
  ///
  /// Returns null if the route couldn't be fetched (missing/invalid key, no
  /// connectivity, no route found, etc). Never throws — callers can treat a
  /// null result as "fall back to straight-line matching".
  Future<double?> fetchRouteDistanceKm({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    List<List<double>> waypoints = const [],
  }) async {
    try {
      final params = {
        'origin': '$originLat,$originLng',
        'destination': '$destLat,$destLng',
        'key': ApiKeys.googleDirections,
      };
      if (waypoints.isNotEmpty) {
        params['waypoints'] = waypoints.map((w) => '${w[0]},${w[1]}').join('|');
      }

      final uri = Uri.parse(_baseUrl).replace(queryParameters: params);
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['status'] != 'OK') return null;

      final routes = body['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return null;

      final legs = (routes.first as Map<String, dynamic>)['legs'] as List<dynamic>?;
      if (legs == null || legs.isEmpty) return null;

      final totalMeters = legs.fold<num>(0, (sum, leg) {
        final distance = (leg as Map<String, dynamic>)['distance'] as Map<String, dynamic>?;
        return sum + ((distance?['value'] as num?) ?? 0);
      });
      return totalMeters / 1000.0;
    } catch (_) {
      return null;
    }
  }
}
