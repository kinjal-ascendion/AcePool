import 'package:flutter/material.dart';

import 'package:acepool/features/rides/domain/entities/ride_match.dart';
import 'package:acepool/features/rides/domain/repositories/rides_repository.dart';

class FindMatchingRidesUseCase {
  FindMatchingRidesUseCase(this._repository);

  final RidesRepository _repository;

  Future<List<RideMatch>> call({
    required String fromAddress,
    required String toAddress,
    double? fromLat,
    double? fromLng,
    double? toLat,
    double? toLng,
    required DateTime date,
    required TimeOfDay time,
    required String vehicleType,
  }) {
    return _repository.findMatchingRides(
      fromAddress: fromAddress,
      toAddress: toAddress,
      fromLat: fromLat,
      fromLng: fromLng,
      toLat: toLat,
      toLng: toLng,
      date: date,
      time: time,
      vehicleType: vehicleType,
    );
  }
}
