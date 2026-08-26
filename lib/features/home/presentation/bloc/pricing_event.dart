part of 'pricing_bloc.dart';

abstract class PricingEvent extends Equatable {
  const PricingEvent();

  @override
  List<Object?> get props => [];
}

class PricingStarted extends PricingEvent {
  final String fromAddress;
  final String toAddress;
  final double? fromLat;
  final double? fromLng;
  final double? toLat;
  final double? toLng;
  final DateTime date;
  final TimeOfDay time;
  final int seatCount;
  final String vehicleType;
  final String rideMode;

  final bool hasReturnRide;
  final TimeOfDay? returnTime;
  final int returnSeatCount;

  const PricingStarted({
    required this.fromAddress,
    required this.toAddress,
    this.fromLat,
    this.fromLng,
    this.toLat,
    this.toLng,
    required this.date,
    required this.time,
    required this.seatCount,
    required this.vehicleType,
    required this.rideMode,
    this.hasReturnRide = false,
    this.returnTime,
    this.returnSeatCount = 1,
  });

  @override
  List<Object?> get props => [
        fromAddress,
        toAddress,
        fromLat,
        fromLng,
        toLat,
        toLng,
        date,
        time,
        seatCount,
        vehicleType,
        rideMode,
        hasReturnRide,
        returnTime,
        returnSeatCount,
      ];
}

class PricingTabChanged extends PricingEvent {
  final PricingTab tab;
  const PricingTabChanged(this.tab);

  @override
  List<Object?> get props => [tab];
}

class VehicleSelected extends PricingEvent {
  final String vehicleId;
  final String label;
  const VehicleSelected(this.vehicleId, this.label);

  @override
  List<Object?> get props => [vehicleId, label];
}

class RatePerKmChanged extends PricingEvent {
  final double value;
  const RatePerKmChanged(this.value);

  @override
  List<Object?> get props => [value];
}

class VehiclesRefreshRequested extends PricingEvent {
  const VehiclesRefreshRequested();
}

class PublishRideRequested extends PricingEvent {
  const PublishRideRequested();
}
