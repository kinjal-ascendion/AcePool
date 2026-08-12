import 'package:acepool/features/onboarding/domain/entities/vehicle_preference.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VehiclePreference', () {
    test('has exactly the expected values in order', () {
      expect(VehiclePreference.values, [
        VehiclePreference.car,
        VehiclePreference.bike,
        VehiclePreference.both,
      ]);
    });

    test('has three values', () {
      expect(VehiclePreference.values.length, 3);
    });

    test('car is distinct from bike and both', () {
      expect(VehiclePreference.car, isNot(VehiclePreference.bike));
      expect(VehiclePreference.car, isNot(VehiclePreference.both));
    });

    test('each value equals itself', () {
      for (final value in VehiclePreference.values) {
        expect(value, value);
      }
    });

    test('name getter returns expected string for each value', () {
      expect(VehiclePreference.car.name, 'car');
      expect(VehiclePreference.bike.name, 'bike');
      expect(VehiclePreference.both.name, 'both');
    });
  });
}
