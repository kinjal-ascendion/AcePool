part of 'vehicle_bloc.dart';

abstract class VehicleEvent extends Equatable {
  const VehicleEvent();

  @override
  List<Object?> get props => [];
}

class VehicleListStarted extends VehicleEvent {
  const VehicleListStarted();
}
