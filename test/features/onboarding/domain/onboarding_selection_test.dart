import 'package:acepool/features/onboarding/domain/entities/travel_preference.dart';
import 'package:acepool/features/onboarding/domain/entities/vehicle_preference.dart';
import 'package:acepool/features/onboarding/domain/onboarding_selection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OnboardingSelection', () {
    test('stores the provided travelPreference and vehicleType', () {
      const selection = OnboardingSelection(
        travelPreference: TravelPreference.drive,
        vehicleType: VehiclePreference.bike,
      );

      expect(selection.travelPreference, TravelPreference.drive);
      expect(selection.vehicleType, VehiclePreference.bike);
    });

    test('supports every TravelPreference and VehiclePreference combination', () {
      for (final travel in TravelPreference.values) {
        for (final vehicle in VehiclePreference.values) {
          final selection = OnboardingSelection(
            travelPreference: travel,
            vehicleType: vehicle,
          );

          expect(selection.travelPreference, travel);
          expect(selection.vehicleType, vehicle);
        }
      }
    });
  });
}
