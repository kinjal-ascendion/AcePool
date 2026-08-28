part of 'vehicle_preference_bloc.dart';

abstract class VehiclePreferenceEvent extends Equatable {
  const VehiclePreferenceEvent();

  @override
  List<Object?> get props => [];
}

class VehicleOptionSelected extends VehiclePreferenceEvent {
  final VehiclePreference value;

  const VehicleOptionSelected(this.value);

  @override
  List<Object?> get props => [value];
}
