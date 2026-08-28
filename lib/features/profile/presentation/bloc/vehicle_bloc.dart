import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:acepool/features/profile/domain/entities/vehicle.dart';
import 'package:acepool/features/profile/domain/repositories/vehicle_repository.dart';

part 'vehicle_event.dart';
part 'vehicle_state.dart';

class VehicleBloc extends Bloc<VehicleEvent, VehicleState> {
  VehicleBloc({required VehicleRepository vehicleRepository})
      : _vehicleRepository = vehicleRepository,
        super(const VehicleState()) {
    on<VehicleListStarted>(_onStarted);
  }

  final VehicleRepository _vehicleRepository;

  Future<void> _onStarted(VehicleListStarted event, Emitter<VehicleState> emit) async {
    emit(state.copyWith(status: VehicleListStatus.loading));
    await emit.forEach<List<Vehicle>>(
      _vehicleRepository.watchVehicles(),
      onData: (vehicles) => state.copyWith(status: VehicleListStatus.loaded, vehicles: vehicles),
      onError: (error, stackTrace) =>
          state.copyWith(status: VehicleListStatus.error, errorMessage: error.toString()),
    );
  }
}
