import 'package:flutter/material.dart';

import 'package:acepool/features/home/domain/repositories/home_repository.dart';

class ScheduleRideUseCase {
  ScheduleRideUseCase(this._repository);

  final HomeRepository _repository;

  Future<void> call({
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
  }) {
    return _repository.scheduleRide(
      rideMode: rideMode,
      vehicleType: vehicleType,
      fromAddress: fromAddress,
      toAddress: toAddress,
      fromLat: fromLat,
      fromLng: fromLng,
      toLat: toLat,
      toLng: toLng,
      date: date,
      time: time,
      seatCount: seatCount,
      routeDistanceKm: routeDistanceKm,
      routeDurationMinutes: routeDurationMinutes,
      fare: fare,
    );
  }
}
