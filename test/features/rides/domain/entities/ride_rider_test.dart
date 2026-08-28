import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:acepool/features/rides/domain/entities/ride_rider.dart';

void main() {
  RideRider buildRider({TimeOfDay pickupTime = const TimeOfDay(hour: 9, minute: 5)}) {
    return RideRider(
      requestId: 'req-1',
      riderId: 'rider-1',
      riderName: 'Alice',
      riderPhotoUrl: 'https://photo',
      employeeId: 'EMP1',
      pickupPoint: 'Main St',
      pickupLat: 1.1,
      pickupLng: 2.2,
      dropOffLat: 3.3,
      dropOffLng: 4.4,
      pickupTime: pickupTime,
    );
  }

  group('RideRider', () {
    test('stores all constructor fields', () {
      final rider = buildRider();

      expect(rider.requestId, 'req-1');
      expect(rider.riderId, 'rider-1');
      expect(rider.riderName, 'Alice');
      expect(rider.riderPhotoUrl, 'https://photo');
      expect(rider.employeeId, 'EMP1');
      expect(rider.pickupPoint, 'Main St');
      expect(rider.pickupLat, 1.1);
      expect(rider.pickupLng, 2.2);
      expect(rider.dropOffLat, 3.3);
      expect(rider.dropOffLng, 4.4);
      expect(rider.pickupTime, const TimeOfDay(hour: 9, minute: 5));
    });

    test('optional fields default to null when omitted', () {
      const rider = RideRider(
        requestId: 'req-2',
        riderId: 'rider-2',
        riderName: 'Bob',
        employeeId: 'EMP2',
        pickupPoint: 'Elm St',
        pickupTime: TimeOfDay(hour: 8, minute: 0),
      );

      expect(rider.riderPhotoUrl, isNull);
      expect(rider.pickupLat, isNull);
      expect(rider.pickupLng, isNull);
      expect(rider.dropOffLat, isNull);
      expect(rider.dropOffLng, isNull);
    });

    test('pickupTimeLabel formats midnight as 12:00 AM', () {
      final rider = buildRider(pickupTime: const TimeOfDay(hour: 0, minute: 0));
      expect(rider.pickupTimeLabel, '12:00 AM');
    });

    test('pickupTimeLabel formats noon as 12:00 PM', () {
      final rider = buildRider(pickupTime: const TimeOfDay(hour: 12, minute: 0));
      expect(rider.pickupTimeLabel, '12:00 PM');
    });

    test('pickupTimeLabel formats an afternoon time with zero-padded minutes', () {
      final rider = buildRider(pickupTime: const TimeOfDay(hour: 13, minute: 5));
      expect(rider.pickupTimeLabel, '1:05 PM');
    });

    test('pickupTimeLabel formats a late-night time correctly', () {
      final rider = buildRider(pickupTime: const TimeOfDay(hour: 23, minute: 59));
      expect(rider.pickupTimeLabel, '11:59 PM');
    });

    test('pickupTimeLabel formats a morning time correctly', () {
      final rider = buildRider(pickupTime: const TimeOfDay(hour: 6, minute: 45));
      expect(rider.pickupTimeLabel, '6:45 AM');
    });

    test('two instances with identical field values are not == (no value '
        'equality override on this entity)', () {
      final a = buildRider();
      final b = buildRider();
      expect(identical(a, b), isFalse);
      expect(a == b, isFalse);
    });
  });
}
