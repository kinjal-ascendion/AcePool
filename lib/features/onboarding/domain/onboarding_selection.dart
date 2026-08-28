import 'entities/travel_preference.dart';
import 'entities/vehicle_preference.dart';

class OnboardingSelection {
  const OnboardingSelection({
    required this.travelPreference,
    required this.vehicleType,
  });

  final TravelPreference travelPreference;
  final VehiclePreference vehicleType;
}
