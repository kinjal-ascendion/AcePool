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
  ];
}

class TollsIncludedToggled extends PricingEvent {
  final bool includeTolls;
  const TollsIncludedToggled(this.includeTolls);

  @override
  List<Object?> get props => [includeTolls];
}

class DistanceCostChanged extends PricingEvent {
  final double value;
  const DistanceCostChanged(this.value);

  @override
  List<Object?> get props => [value];
}

class TollCostChanged extends PricingEvent {
  final double value;
  const TollCostChanged(this.value);

  @override
  List<Object?> get props => [value];
}

class DetourCostChanged extends PricingEvent {
  final double value;
  const DetourCostChanged(this.value);

  @override
  List<Object?> get props => [value];
}

class RiderCountChanged extends PricingEvent {
  final int riderCount;
  const RiderCountChanged(this.riderCount);

  @override
  List<Object?> get props => [riderCount];
}

class PublishRideRequested extends PricingEvent {
  const PublishRideRequested();
}
