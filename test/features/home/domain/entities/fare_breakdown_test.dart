import 'package:acepool/features/home/domain/entities/fare_breakdown.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FareBreakdown', () {
    test('defaults ratePerKm to 0 and nullable fields to null', () {
      const fare = FareBreakdown(distanceKm: 10, durationMinutes: 20);

      expect(fare.distanceKm, 10);
      expect(fare.durationMinutes, 20);
      expect(fare.vehicleId, isNull);
      expect(fare.vehicleLabel, isNull);
      expect(fare.ratePerKm, 0);
    });

    test('totalCost multiplies distanceKm by ratePerKm', () {
      const fare = FareBreakdown(
        distanceKm: 10,
        durationMinutes: 20,
        ratePerKm: 5,
      );

      expect(fare.totalCost, 50);
    });

    test('totalCost is 0 when ratePerKm is 0', () {
      const fare = FareBreakdown(distanceKm: 10, durationMinutes: 20);

      expect(fare.totalCost, 0);
    });

    test('copyWith overrides only provided fields', () {
      const fare = FareBreakdown(
        distanceKm: 10,
        durationMinutes: 20,
        vehicleId: 'v1',
        vehicleLabel: 'Honda Activa',
        ratePerKm: 5,
      );

      final updated = fare.copyWith(ratePerKm: 8);

      expect(updated.distanceKm, 10);
      expect(updated.durationMinutes, 20);
      expect(updated.vehicleId, 'v1');
      expect(updated.vehicleLabel, 'Honda Activa');
      expect(updated.ratePerKm, 8);
    });

    test('copyWith with no args returns equivalent instance', () {
      const fare = FareBreakdown(
        distanceKm: 10,
        durationMinutes: 20,
        vehicleId: 'v1',
        vehicleLabel: 'Honda Activa',
        ratePerKm: 5,
      );

      final copy = fare.copyWith();

      expect(copy, fare);
    });

    test('copyWith replaces every field when all provided', () {
      const fare = FareBreakdown(distanceKm: 10, durationMinutes: 20);

      final updated = fare.copyWith(
        distanceKm: 15,
        durationMinutes: 30,
        vehicleId: 'v2',
        vehicleLabel: 'Swift',
        ratePerKm: 12,
      );

      expect(updated.distanceKm, 15);
      expect(updated.durationMinutes, 30);
      expect(updated.vehicleId, 'v2');
      expect(updated.vehicleLabel, 'Swift');
      expect(updated.ratePerKm, 12);
    });

    test('supports value equality', () {
      const a = FareBreakdown(
        distanceKm: 10,
        durationMinutes: 20,
        vehicleId: 'v1',
        vehicleLabel: 'Honda Activa',
        ratePerKm: 5,
      );
      const b = FareBreakdown(
        distanceKm: 10,
        durationMinutes: 20,
        vehicleId: 'v1',
        vehicleLabel: 'Honda Activa',
        ratePerKm: 5,
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('differs when any prop differs', () {
      const a = FareBreakdown(distanceKm: 10, durationMinutes: 20);
      const b = FareBreakdown(distanceKm: 11, durationMinutes: 20);

      expect(a, isNot(b));
    });
  });
}
