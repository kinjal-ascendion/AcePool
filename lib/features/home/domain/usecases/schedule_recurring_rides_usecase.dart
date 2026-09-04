import 'package:flutter/material.dart';
import 'package:acepool/features/home/domain/repositories/home_repository.dart';

class ScheduleRecurringRidesUseCase {
  ScheduleRecurringRidesUseCase(this._repository);

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
    required List<DateTime> dates,
    required TimeOfDay time,
    required int seatCount,
    double? routeDistanceKm,
    int? routeDurationMinutes,
    Map<String, dynamic>? fare,
  }) {
    return _repository.scheduleRecurringRides(
      rideMode: rideMode,
      vehicleType: vehicleType,
      fromAddress: fromAddress,
      toAddress: toAddress,
      fromLat: fromLat,
      fromLng: fromLng,
      toLat: toLat,
      toLng: toLng,
      dates: dates,
      time: time,
      seatCount: seatCount,
      routeDistanceKm: routeDistanceKm,
      routeDurationMinutes: routeDurationMinutes,
      fare: fare,
    );
  }
}
