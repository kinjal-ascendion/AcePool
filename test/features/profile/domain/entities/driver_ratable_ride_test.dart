import 'package:acepool/features/profile/domain/entities/driver_ratable_ride.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DriverRatableRide', () {
    test('constructor assigns all fields', () {
      final ride = DriverRatableRide(
        requestId: 'req1',
        rideId: 'ride1',
        driverId: 'driver1',
        date: DateTime(2024, 1, 1),
        time: const TimeOfDay(hour: 9, minute: 30),
        pickup: 'A',
        drop: 'B',
        driverRating: 4,
        ratedRiders: 2,
        totalRiders: 3,
      );

      expect(ride.requestId, 'req1');
      expect(ride.rideId, 'ride1');
      expect(ride.driverId, 'driver1');
      expect(ride.date, DateTime(2024, 1, 1));
      expect(ride.time, const TimeOfDay(hour: 9, minute: 30));
      expect(ride.pickup, 'A');
      expect(ride.drop, 'B');
      expect(ride.driverRating, 4);
      expect(ride.ratedRiders, 2);
      expect(ride.totalRiders, 3);
    });

    test('driverRating can be null', () {
      final ride = DriverRatableRide(
        requestId: 'req1',
        rideId: 'ride1',
        driverId: 'driver1',
        date: DateTime(2024, 1, 1),
        time: const TimeOfDay(hour: 9, minute: 30),
        pickup: 'A',
        drop: 'B',
        driverRating: null,
        ratedRiders: 0,
        totalRiders: 0,
      );

      expect(ride.driverRating, isNull);
    });
  });
}
