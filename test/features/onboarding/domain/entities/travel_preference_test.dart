import 'package:acepool/features/onboarding/domain/entities/travel_preference.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TravelPreference', () {
    test('has exactly the expected values in order', () {
      expect(TravelPreference.values, [
        TravelPreference.ride,
        TravelPreference.drive,
        TravelPreference.both,
      ]);
    });

    test('has three values', () {
      expect(TravelPreference.values.length, 3);
    });

    test('ride is distinct from drive and both', () {
      expect(TravelPreference.ride, isNot(TravelPreference.drive));
      expect(TravelPreference.ride, isNot(TravelPreference.both));
    });

    test('each value equals itself', () {
      for (final value in TravelPreference.values) {
        expect(value, value);
      }
    });

    test('name getter returns expected string for each value', () {
      expect(TravelPreference.ride.name, 'ride');
      expect(TravelPreference.drive.name, 'drive');
      expect(TravelPreference.both.name, 'both');
    });
  });
}
