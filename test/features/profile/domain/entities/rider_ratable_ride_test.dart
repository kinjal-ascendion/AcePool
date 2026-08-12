import 'package:acepool/features/profile/domain/entities/rider_ratable_ride.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RiderRatableRide', () {
    RiderRatableRide buildRide({int? riderRating}) {
      return RiderRatableRide(
        requestId: 'req1',
        rideId: 'ride1',
        driverId: 'driver1',
        date: DateTime(2024, 1, 1),
        time: const TimeOfDay(hour: 10, minute: 0),
        pickup: 'A',
        drop: 'B',
        riderRating: riderRating,
      );
    }

    test('constructor assigns all fields', () {
      final ride = buildRide(riderRating: 5);

      expect(ride.requestId, 'req1');
      expect(ride.rideId, 'ride1');
      expect(ride.driverId, 'driver1');
      expect(ride.date, DateTime(2024, 1, 1));
      expect(ride.time, const TimeOfDay(hour: 10, minute: 0));
      expect(ride.pickup, 'A');
      expect(ride.drop, 'B');
      expect(ride.riderRating, 5);
    });

    test('riderRating can be null', () {
      final ride = buildRide();
      expect(ride.riderRating, isNull);
    });

    group('copyWith', () {
      test('overrides riderRating when provided', () {
        final ride = buildRide(riderRating: 3);
        final updated = ride.copyWith(riderRating: 5);

        expect(updated.riderRating, 5);
        expect(updated.requestId, ride.requestId);
        expect(updated.rideId, ride.rideId);
        expect(updated.driverId, ride.driverId);
        expect(updated.date, ride.date);
        expect(updated.time, ride.time);
        expect(updated.pickup, ride.pickup);
        expect(updated.drop, ride.drop);
      });

      test('keeps existing riderRating when not provided', () {
        final ride = buildRide(riderRating: 3);
        final updated = ride.copyWith();

        expect(updated.riderRating, 3);
      });

      test('keeps null riderRating when not provided and originally null', () {
        final ride = buildRide();
        final updated = ride.copyWith();

        expect(updated.riderRating, isNull);
      });
    });
  });
}
