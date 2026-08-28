part of 'vehicle_preference_bloc.dart';

class VehiclePreferenceState extends Equatable {
  final VehiclePreference selected;

  const VehiclePreferenceState({required this.selected});

  @override
  List<Object?> get props => [selected];
}
