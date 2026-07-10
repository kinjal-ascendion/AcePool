import '../presentation/pages/travel_preference_page.dart';
import '../presentation/pages/vehicle_preference_page.dart';

class OnboardingSelection {
  const OnboardingSelection({
    required this.travelPreference,
    required this.vehicleType,
  });

  final TravelPreference travelPreference;
  final VehiclePreference vehicleType;
}
