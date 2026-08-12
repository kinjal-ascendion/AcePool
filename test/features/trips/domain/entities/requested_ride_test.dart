import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:acepool/features/trips/domain/entities/requested_ride.dart';

RequestedRide _buildRequest({
  DateTime? date,
  TimeOfDay time = const TimeOfDay(hour: 9, minute: 5),
  double? distanceKm,
  String driverPhone = '',
  double? farePerSeat,
}) {
  return RequestedRide(
    id: 'req1',
    rideId: 'ride1',
    driverId: 'driver1',
    driverName: 'Jane',
    driverPhotoUrl: 'photo.png',
    driverPhone: driverPhone,
    date: date ?? DateTime(2024, 1, 5),
    time: time,
    fromAddress: 'Home',
    toAddress: 'Office',
    riderStartAddress: 'Rider Home',
    riderEndAddress: 'Rider Office',
    seatsFilled: 1,
    seatsTotal: 4,
    status: 'accepted',
    farePerSeat: farePerSeat,
    vehicleType: 'car',
    matchPercent: 80,
    distanceKm: distanceKm,
  );
}

void main() {
  group('RequestedRide', () {
    test('applies default values for optional fields', () {
      final request = _buildRequest();
      expect(request.driverPhone, '');
      expect(request.farePerSeat, isNull);
      expect(request.distanceKm, isNull);
    });

    test('retains explicitly provided optional field values', () {
      final request = _buildRequest(driverPhone: '999', farePerSeat: 50.0);
      expect(request.driverPhone, '999');
      expect(request.farePerSeat, 50.0);
    });

    group('distanceLabel', () {
      test('is null when distanceKm is null', () {
        final request = _buildRequest(distanceKm: null);
        expect(request.distanceLabel, isNull);
      });

      test('formats sub-kilometre distances in metres', () {
        final request = _buildRequest(distanceKm: 0.1);
        expect(request.distanceLabel, '100 m');
      });

      test('formats distances >= 1km in kilometres with one decimal', () {
        final request = _buildRequest(distanceKm: 12.05);
        expect(request.distanceLabel, '12.1 km');
      });
    });

    group('timeLabel', () {
      test('formats midnight as 12:00 AM', () {
        final request =
            _buildRequest(time: const TimeOfDay(hour: 0, minute: 0));
        expect(request.timeLabel, '12:00 AM');
      });

      test('formats noon as 12:00 PM', () {
        final request =
            _buildRequest(time: const TimeOfDay(hour: 12, minute: 0));
        expect(request.timeLabel, '12:00 PM');
      });

      test('formats evening hour with minute padding', () {
        final request =
            _buildRequest(time: const TimeOfDay(hour: 18, minute: 3));
        expect(request.timeLabel, '6:03 PM');
      });
    });

    group('dateLabel', () {
      test('formats a mid-year date', () {
        final request = _buildRequest(date: DateTime(2023, 6, 15));
        expect(request.dateLabel, 'June 15, 2023');
      });

      test('formats an end-of-year date', () {
        final request = _buildRequest(date: DateTime(2025, 12, 1));
        expect(request.dateLabel, 'December 1, 2025');
      });
    });
  });
}
