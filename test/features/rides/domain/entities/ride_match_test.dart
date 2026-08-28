import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:acepool/features/rides/domain/entities/ride_match.dart';

void main() {
  RideMatch buildMatch({
    double? distanceKm = 1.5,
    DateTime? date,
  }) {
    return RideMatch(
      id: 'ride-1',
      driverId: 'driver-1',
      driverName: 'Jane Driver',
      driverPhotoUrl: 'https://photo',
      driverPhone: '1234567890',
      date: date ?? DateTime(2020, 1, 1),
      time: const TimeOfDay(hour: 14, minute: 30),
      fromAddress: 'Home',
      toAddress: 'Office',
      seatsFilled: 2,
      seatsTotal: 4,
      vehicleType: 'car',
      alreadyRequested: false,
      distanceKm: distanceKm,
      matchPercent: 80,
      farePerSeat: 50.0,
      fromLat: 1.1,
      fromLng: 2.2,
      toLat: 3.3,
      toLng: 4.4,
    );
  }

  group('RideMatch', () {
    test('stores all constructor fields', () {
      final match = buildMatch();

      expect(match.id, 'ride-1');
      expect(match.driverId, 'driver-1');
      expect(match.driverName, 'Jane Driver');
      expect(match.driverPhotoUrl, 'https://photo');
      expect(match.driverPhone, '1234567890');
      expect(match.date, DateTime(2020, 1, 1));
      expect(match.time, const TimeOfDay(hour: 14, minute: 30));
      expect(match.fromAddress, 'Home');
      expect(match.toAddress, 'Office');
      expect(match.seatsFilled, 2);
      expect(match.seatsTotal, 4);
      expect(match.vehicleType, 'car');
      expect(match.alreadyRequested, isFalse);
      expect(match.distanceKm, 1.5);
      expect(match.matchPercent, 80);
      expect(match.farePerSeat, 50.0);
      expect(match.fromLat, 1.1);
      expect(match.fromLng, 2.2);
      expect(match.toLat, 3.3);
      expect(match.toLng, 4.4);
    });

    test('optional fields default to null when omitted', () {
      final match = RideMatch(
        id: 'ride-2',
        driverId: 'driver-2',
        driverName: 'Bob',
        date: DateTime(2021, 5, 5),
        time: const TimeOfDay(hour: 9, minute: 0),
        fromAddress: 'A',
        toAddress: 'B',
        seatsFilled: 0,
        seatsTotal: 4,
        vehicleType: 'bike',
        alreadyRequested: true,
        distanceKm: null,
        matchPercent: 20,
      );

      expect(match.driverPhotoUrl, isNull);
      expect(match.driverPhone, isNull);
      expect(match.farePerSeat, isNull);
      expect(match.fromLat, isNull);
      expect(match.fromLng, isNull);
      expect(match.toLat, isNull);
      expect(match.toLng, isNull);
      expect(match.alreadyRequested, isTrue);
    });

    test('timeLabel formats via DateTimeFormatter.time12h', () {
      final match = buildMatch();
      expect(match.timeLabel, '2:30 PM');
    });

    test('timeLabel formats midnight as 12:00 AM', () {
      final match = RideMatch(
        id: 'r',
        driverId: 'd',
        driverName: 'n',
        date: DateTime(2020, 1, 1),
        time: const TimeOfDay(hour: 0, minute: 0),
        fromAddress: 'A',
        toAddress: 'B',
        seatsFilled: 0,
        seatsTotal: 1,
        vehicleType: 'car',
        alreadyRequested: false,
        distanceKm: null,
        matchPercent: 0,
      );
      expect(match.timeLabel, '12:00 AM');
    });

    test('dateLabel includes formatted month/day/year for a date far from '
        'today/tomorrow', () {
      final match = buildMatch(date: DateTime(2020, 3, 15));
      expect(match.dateLabel, 'March 15, 2020');
    });

    test('distanceLabel is null when distanceKm is null', () {
      final match = buildMatch(distanceKm: null);
      expect(match.distanceLabel, isNull);
    });

    test('distanceLabel formats sub-km distances in meters', () {
      final match = buildMatch(distanceKm: 0.65);
      expect(match.distanceLabel, '650 m');
    });

    test('distanceLabel formats km distances with one decimal', () {
      final match = buildMatch(distanceKm: 3.24);
      expect(match.distanceLabel, '3.2 km');
    });

    test('two instances with identical field values are not == (no value '
        'equality override on this entity)', () {
      final a = buildMatch();
      final b = buildMatch();
      expect(identical(a, b), isFalse);
      expect(a == b, isFalse);
    });

    test('an instance is always == to itself', () {
      final a = buildMatch();
      expect(a == a, isTrue);
    });
  });
}
