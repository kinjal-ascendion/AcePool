import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/vehicle_preference.dart';

part 'vehicle_preference_event.dart';
part 'vehicle_preference_state.dart';

class VehiclePreferenceBloc
    extends Bloc<VehiclePreferenceEvent, VehiclePreferenceState> {
  VehiclePreferenceBloc()
    : super(const VehiclePreferenceState(selected: VehiclePreference.car)) {
    on<VehicleOptionSelected>(_onVehicleOptionSelected);
  }

  void _onVehicleOptionSelected(
    VehicleOptionSelected event,
    Emitter<VehiclePreferenceState> emit,
  ) {
    emit(VehiclePreferenceState(selected: event.value));
  }
}
