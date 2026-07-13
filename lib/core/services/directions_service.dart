import 'dart:convert';

import 'package:acepool/core/constants/api_keys.dart';
import 'package:http/http.dart' as http;

/// Driving distance (km) and duration (minutes) for a route, as returned by
/// the Google Directions API.
class RouteDetails {
  final double distanceKm;
  final int durationMinutes;

  const RouteDetails({required this.distanceKm, required this.durationMinutes});
}

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

  /// Driving distance and duration from (originLat, originLng) to
  /// (destLat, destLng). Returns null on any failure — callers should fall
  /// back to a sensible default rather than blocking on this.
  Future<RouteDetails?> fetchRouteDetails({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    try {
      final params = {
        'origin': '$originLat,$originLng',
        'destination': '$destLat,$destLng',
        'key': ApiKeys.googleDirections,
      };

      final uri = Uri.parse(_baseUrl).replace(queryParameters: params);
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['status'] != 'OK') return null;

      final routes = body['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return null;

      final legs = (routes.first as Map<String, dynamic>)['legs'] as List<dynamic>?;
      if (legs == null || legs.isEmpty) return null;

      var totalMeters = 0.0;
      var totalSeconds = 0.0;
      for (final leg in legs) {
        final legMap = leg as Map<String, dynamic>;
        final distance = legMap['distance'] as Map<String, dynamic>?;
        final duration = legMap['duration'] as Map<String, dynamic>?;
        totalMeters += (distance?['value'] as num?)?.toDouble() ?? 0;
        totalSeconds += (duration?['value'] as num?)?.toDouble() ?? 0;
      }

      return RouteDetails(
        distanceKm: totalMeters / 1000.0,
        durationMinutes: (totalSeconds / 60.0).round(),
      );
    } catch (_) {
      return null;
    }
  }
}
