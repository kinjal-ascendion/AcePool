import 'package:flutter_test/flutter_test.dart';

import 'package:acepool/features/rides/domain/entities/rider_journey.dart';

void main() {
  group('RiderJourney', () {
    test('stores all constructor fields when provided', () {
      const journey = RiderJourney(
        pickupPoint: 'Pickup A',
        dropOffPoint: 'Dropoff B',
        riderStartAddress: 'Rider Start',
        riderEndAddress: 'Rider End',
        pickupLat: 1.1,
        pickupLng: 2.2,
        dropOffLat: 3.3,
        dropOffLng: 4.4,
        riderStartLat: 5.5,
        riderStartLng: 6.6,
        riderEndLat: 7.7,
        riderEndLng: 8.8,
        pinnedLat: 9.9,
        pinnedLng: 10.1,
        pinnedName: 'Pinned Spot',
        driveDurationMinutes: 25,
      );

      expect(journey.pickupPoint, 'Pickup A');
      expect(journey.dropOffPoint, 'Dropoff B');
      expect(journey.riderStartAddress, 'Rider Start');
      expect(journey.riderEndAddress, 'Rider End');
      expect(journey.pickupLat, 1.1);
      expect(journey.pickupLng, 2.2);
      expect(journey.dropOffLat, 3.3);
      expect(journey.dropOffLng, 4.4);
      expect(journey.riderStartLat, 5.5);
      expect(journey.riderStartLng, 6.6);
      expect(journey.riderEndLat, 7.7);
      expect(journey.riderEndLng, 8.8);
      expect(journey.pinnedLat, 9.9);
      expect(journey.pinnedLng, 10.1);
      expect(journey.pinnedName, 'Pinned Spot');
      expect(journey.driveDurationMinutes, 25);
    });

    test('optional coordinate/pinned fields default to null when omitted', () {
      const journey = RiderJourney(
        pickupPoint: 'Pickup A',
        dropOffPoint: 'Dropoff B',
        riderStartAddress: '',
        riderEndAddress: '',
        driveDurationMinutes: 20,
      );

      expect(journey.pickupLat, isNull);
      expect(journey.pickupLng, isNull);
      expect(journey.dropOffLat, isNull);
      expect(journey.dropOffLng, isNull);
      expect(journey.riderStartLat, isNull);
      expect(journey.riderStartLng, isNull);
      expect(journey.riderEndLat, isNull);
      expect(journey.riderEndLng, isNull);
      expect(journey.pinnedLat, isNull);
      expect(journey.pinnedLng, isNull);
      expect(journey.pinnedName, isNull);
      expect(journey.driveDurationMinutes, 20);
    });

    test('two separately-built (non-const) instances with identical field '
        'values are not == (no value equality override on this entity)', () {
      RiderJourney build() => RiderJourney(
            pickupPoint: 'P',
            dropOffPoint: 'D',
            riderStartAddress: 'S',
            riderEndAddress: 'E',
            driveDurationMinutes: 10 + 0,
          );
      final a = build();
      final b = build();
      expect(identical(a, b), isFalse);
      expect(a == b, isFalse);
    });
  });
}
