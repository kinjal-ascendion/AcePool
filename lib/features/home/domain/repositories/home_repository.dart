import 'package:flutter/material.dart';

import 'package:acepool/core/services/directions_service.dart';
import 'package:acepool/features/home/domain/entities/upcoming_trip.dart';
import 'package:acepool/features/home/domain/entities/vehicle_option.dart';

abstract class HomeRepository {
  Future<List<UpcomingTrip>> getUpcomingTrips();

  Future<void> scheduleRide({
    required String rideMode,
    required String vehicleType,
    required String fromAddress,
    required String toAddress,
    double? fromLat,
    double? fromLng,
    double? toLat,
    double? toLng,
    required DateTime date,
    required TimeOfDay time,
    required int seatCount,
    double? routeDistanceKm,
    int? routeDurationMinutes,
    Map<String, dynamic>? fare,
  });

  Future<void> updateRide({
    required String rideId,
    Map<String, dynamic>? fare,
    int? seatCount,
  });

  Future<void> scheduleRecurringRides({
    required String rideMode,
    required String vehicleType,
    required String fromAddress,
    required String toAddress,
    double? fromLat,
    double? fromLng,
    double? toLat,
    double? toLng,
    required List<DateTime> dates,
    required TimeOfDay time,
    required int seatCount,
    double? routeDistanceKm,
    int? routeDurationMinutes,
    Map<String, dynamic>? fare,
  });

  Future<RouteDetails> estimateRoute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  });

  /// The current user's `travelPreference` field (`ride`/`drive`/`both`),
  /// or null if unset/no user is signed in.
  Future<String?> getTravelPreference();

  /// Vehicles the current user has registered matching [vehicleType]
  /// (`car`/`bike`).
  Future<List<VehicleOption>> getVehicleOptions(String vehicleType);
}
