import 'package:acepool/features/auth/domain/entities/signup_details.dart';
import 'package:acepool/features/onboarding/domain/entities/travel_preference.dart';
import 'package:acepool/features/onboarding/domain/entities/vehicle_preference.dart';
import 'package:acepool/features/onboarding/domain/onboarding_selection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SignupDetails', () {
    test('stores required fields with optional fields defaulting to null', () {
      const details = SignupDetails(
        fullName: 'Jane Doe',
        employeeId: 'EMP123',
        phone: '1234567890',
        emailUsername: 'jane',
        password: 'password1',
      );

      expect(details.fullName, 'Jane Doe');
      expect(details.employeeId, 'EMP123');
      expect(details.phone, '1234567890');
      expect(details.emailUsername, 'jane');
      expect(details.password, 'password1');
      expect(details.onboardingSelection, isNull);
      expect(details.licenseVerified, isNull);
      expect(details.licenseNumber, isNull);
    });

    test('stores optional onboardingSelection, licenseVerified and licenseNumber', () {
      const selection = OnboardingSelection(
        travelPreference: TravelPreference.ride,
        vehicleType: VehiclePreference.car,
      );
      const details = SignupDetails(
        fullName: 'Jane Doe',
        employeeId: 'EMP123',
        phone: '1234567890',
        emailUsername: 'jane',
        password: 'password1',
        onboardingSelection: selection,
        licenseVerified: true,
        licenseNumber: 'DL12345',
      );

      expect(details.onboardingSelection, selection);
      expect(details.licenseVerified, isTrue);
      expect(details.licenseNumber, 'DL12345');
    });
  });
}
