import 'dart:math' as math;

import 'package:acepool/core/services/directions_service.dart';

class EstimateRouteUseCase {
  final DirectionsService _directions;

  EstimateRouteUseCase({DirectionsService? directions})
      : _directions = directions ?? DirectionsService();

  // Roads are rarely a straight line, and this is only used when the real
  // routing call is unavailable — a generous multiplier keeps the fallback
  // from under-quoting the driver.
  static const _straightLineRoadFactor = 1.3;
  static const _averageSpeedKmh = 30.0;

  Future<RouteDetails> call({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    final route = await _directions.fetchRouteDetails(
      originLat: originLat,
      originLng: originLng,
      destLat: destLat,
      destLng: destLng,
    );
    if (route != null) return route;

    // Directions API unreachable (billing disabled, no network, quota,
    // etc.) — fall back to a straight-line estimate so the Pricing screen
    // always has a real starting distance/duration instead of showing 0.
    final distanceKm =
        _haversineKm(originLat, originLng, destLat, destLng) * _straightLineRoadFactor;
    final durationMinutes = (distanceKm / _averageSpeedKmh * 60).round();
    return RouteDetails(distanceKm: distanceKm, durationMinutes: durationMinutes);
  }

  double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
    const earthRadiusKm = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLng = _degToRad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _degToRad(double deg) => deg * (math.pi / 180);
}
