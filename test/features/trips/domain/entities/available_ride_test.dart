import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:acepool/features/trips/domain/entities/available_ride.dart';

AvailableRide _buildRide({
  DateTime? date,
  TimeOfDay time = const TimeOfDay(hour: 9, minute: 5),
  double? distanceKm,
  String driverPhotoUrl = '',
  String driverPhone = '',
  String userFromAddress = '',
  String userToAddress = '',
}) {
  return AvailableRide(
    id: 'ride1',
    driverId: 'driver1',
    driverName: 'Jane',
    driverPhotoUrl: driverPhotoUrl,
    driverPhone: driverPhone,
    date: date ?? DateTime(2024, 1, 5),
    time: time,
    fromAddress: 'Home',
    toAddress: 'Office',
    seatsFilled: 1,
    seatsTotal: 4,
    vehicleType: 'car',
    alreadyRequested: false,
    matchPercent: 80,
    defaultPickupPoint: 'Home',
    distanceKm: distanceKm,
    userFromAddress: userFromAddress,
    userToAddress: userToAddress,
  );
}

void main() {
  group('AvailableRide', () {
    test('applies default values for optional fields', () {
      final ride = _buildRide();
      expect(ride.driverPhotoUrl, '');
      expect(ride.driverPhone, '');
      expect(ride.userFromAddress, '');
      expect(ride.userToAddress, '');
      expect(ride.userFromLat, isNull);
      expect(ride.userFromLng, isNull);
      expect(ride.userToLat, isNull);
      expect(ride.userToLng, isNull);
      expect(ride.fromLat, isNull);
      expect(ride.farePerSeat, isNull);
    });

    test('retains explicitly provided optional field values', () {
      final ride = _buildRide(
        driverPhotoUrl: 'photo.png',
        driverPhone: '12345',
        userFromAddress: 'Rider Home',
        userToAddress: 'Rider Office',
      );
      expect(ride.driverPhotoUrl, 'photo.png');
      expect(ride.driverPhone, '12345');
      expect(ride.userFromAddress, 'Rider Home');
      expect(ride.userToAddress, 'Rider Office');
    });

    group('distanceLabel', () {
      test('is null when distanceKm is null', () {
        final ride = _buildRide(distanceKm: null);
        expect(ride.distanceLabel, isNull);
      });

      test('formats sub-kilometre distances in metres', () {
        final ride = _buildRide(distanceKm: 0.65);
        expect(ride.distanceLabel, '650 m');
      });

      test('formats distances >= 1km in kilometres with one decimal', () {
        final ride = _buildRide(distanceKm: 3.24);
        expect(ride.distanceLabel, '3.2 km');
      });
    });

    group('timeLabel', () {
      test('formats midnight as 12:00 AM', () {
        final ride = _buildRide(time: const TimeOfDay(hour: 0, minute: 0));
        expect(ride.timeLabel, '12:00 AM');
      });

      test('formats noon as 12:00 PM', () {
        final ride = _buildRide(time: const TimeOfDay(hour: 12, minute: 0));
        expect(ride.timeLabel, '12:00 PM');
      });

      test('formats afternoon hour with minute padding', () {
        final ride = _buildRide(time: const TimeOfDay(hour: 13, minute: 5));
        expect(ride.timeLabel, '1:05 PM');
      });

      test('formats morning hour', () {
        final ride = _buildRide(time: const TimeOfDay(hour: 9, minute: 30));
        expect(ride.timeLabel, '9:30 AM');
      });
    });

    group('dateLabel', () {
      test('formats a January date', () {
        final ride = _buildRide(date: DateTime(2024, 1, 5));
        expect(ride.dateLabel, 'January 5, 2024');
      });

      test('formats a December date', () {
        final ride = _buildRide(date: DateTime(2025, 12, 31));
        expect(ride.dateLabel, 'December 31, 2025');
      });
    });
  });
}
