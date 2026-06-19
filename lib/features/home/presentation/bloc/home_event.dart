part of 'home_bloc.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class HomeStarted extends HomeEvent {
  const HomeStarted();
}

class RideModeChanged extends HomeEvent {
  final RideMode mode;
  const RideModeChanged(this.mode);

  @override
  List<Object?> get props => [mode];
}

class VehicleTypeChanged extends HomeEvent {
  final VehicleType vehicleType;
  const VehicleTypeChanged(this.vehicleType);

  @override
  List<Object?> get props => [vehicleType];
}

class FromAddressChanged extends HomeEvent {
  final String address;
  const FromAddressChanged(this.address);

  @override
  List<Object?> get props => [address];
}

class ToAddressChanged extends HomeEvent {
  final String address;
  const ToAddressChanged(this.address);

  @override
  List<Object?> get props => [address];
}

class LocationsSwapped extends HomeEvent {
  const LocationsSwapped();
}

class DateSelected extends HomeEvent {
  final DateTime date;
  const DateSelected(this.date);

  @override
  List<Object?> get props => [date];
}

class TimeSelected extends HomeEvent {
  final TimeOfDay time;
  const TimeSelected(this.time);

  @override
  List<Object?> get props => [time];
}

class SeatCountChanged extends HomeEvent {
  final int seatCount;
  const SeatCountChanged(this.seatCount);

  @override
  List<Object?> get props => [seatCount];
}

class ScheduleRideRequested extends HomeEvent {
  const ScheduleRideRequested();
}
