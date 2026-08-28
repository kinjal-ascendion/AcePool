part of 'vehicle_bloc.dart';

enum VehicleListStatus { initial, loading, loaded, error }

class VehicleState extends Equatable {
  const VehicleState({
    this.status = VehicleListStatus.initial,
    this.vehicles = const [],
    this.errorMessage,
  });

  final VehicleListStatus status;
  final List<Vehicle> vehicles;
  final String? errorMessage;

  VehicleState copyWith({
    VehicleListStatus? status,
    List<Vehicle>? vehicles,
    String? errorMessage,
  }) {
    return VehicleState(
      status: status ?? this.status,
      vehicles: vehicles ?? this.vehicles,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, vehicles, errorMessage];
}
