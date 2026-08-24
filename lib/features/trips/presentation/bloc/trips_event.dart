part of 'trips_bloc.dart';

abstract class TripsEvent extends Equatable {
  const TripsEvent();

  @override
  List<Object?> get props => [];
}

class TripsDrivesRequested extends TripsEvent {
  const TripsDrivesRequested();
}

class TripsAvailableRidesRequested extends TripsEvent {
  const TripsAvailableRidesRequested({
    this.fromAddress,
    this.toAddress,
    this.fromLat,
    this.fromLng,
    this.toLat,
    this.toLng,
  });

  final String? fromAddress;
  final String? toAddress;
  final double? fromLat;
  final double? fromLng;
  final double? toLat;
  final double? toLng;

  @override
  List<Object?> get props => [fromAddress, toAddress, fromLat, fromLng, toLat, toLng];
}

class TripsRequestedRidesRequested extends TripsEvent {
  const TripsRequestedRidesRequested({
    this.homeFromAddress,
    this.homeToAddress,
    this.homeFromLat,
    this.homeFromLng,
    this.homeToLat,
    this.homeToLng,
  });

  final String? homeFromAddress;
  final String? homeToAddress;
  final double? homeFromLat;
  final double? homeFromLng;
  final double? homeToLat;
  final double? homeToLng;

  @override
  List<Object?> get props =>
      [homeFromAddress, homeToAddress, homeFromLat, homeFromLng, homeToLat, homeToLng];
}

class TripsPreferenceUpdated extends TripsEvent {
  final String? preference;
  const TripsPreferenceUpdated(this.preference);

  @override
  List<Object?> get props => [preference];
}
