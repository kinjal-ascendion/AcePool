import 'package:flutter_test/flutter_test.dart';

import 'package:acepool/features/trips/domain/entities/driver_profile_stats.dart';

void main() {
  group('DriverProfileStats', () {
    test('uses placeholder defaults when no arguments are provided', () {
      const stats = DriverProfileStats();
      expect(stats.employeeId, 'ASC 2001922');
      expect(stats.completedRidesCount, 30);
      expect(stats.rating, 4.72);
      expect(stats.ratingCount, 15);
    });

    test('retains explicitly provided field values', () {
      const stats = DriverProfileStats(
        employeeId: 'ASC 9999999',
        completedRidesCount: 120,
        rating: 4.9,
        ratingCount: 200,
      );
      expect(stats.employeeId, 'ASC 9999999');
      expect(stats.completedRidesCount, 120);
      expect(stats.rating, 4.9);
      expect(stats.ratingCount, 200);
    });
  });
}
