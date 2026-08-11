part of 'trips_bloc.dart';

enum TripsSectionStatus { initial, loading, loaded }

class TripsState extends Equatable {
  const TripsState({
    this.drivesStatus = TripsSectionStatus.initial,
    this.drives = const [],
    this.availableRidesStatus = TripsSectionStatus.initial,
    this.availableRides = const [],
    this.hasCommuteLocation = false,
    this.requestedRidesStatus = TripsSectionStatus.initial,
    this.requestedRides = const [],
  });

  final TripsSectionStatus drivesStatus;
  final List<UpcomingTrip> drives;

  final TripsSectionStatus availableRidesStatus;
  final List<AvailableRide> availableRides;
  final bool hasCommuteLocation;

  final TripsSectionStatus requestedRidesStatus;
  final List<RequestedRide> requestedRides;

  TripsState copyWith({
    TripsSectionStatus? drivesStatus,
    List<UpcomingTrip>? drives,
    TripsSectionStatus? availableRidesStatus,
    List<AvailableRide>? availableRides,
    bool? hasCommuteLocation,
    TripsSectionStatus? requestedRidesStatus,
    List<RequestedRide>? requestedRides,
  }) {
    return TripsState(
      drivesStatus: drivesStatus ?? this.drivesStatus,
      drives: drives ?? this.drives,
      availableRidesStatus: availableRidesStatus ?? this.availableRidesStatus,
      availableRides: availableRides ?? this.availableRides,
      hasCommuteLocation: hasCommuteLocation ?? this.hasCommuteLocation,
      requestedRidesStatus: requestedRidesStatus ?? this.requestedRidesStatus,
      requestedRides: requestedRides ?? this.requestedRides,
    );
  }

  @override
  List<Object?> get props => [
        drivesStatus,
        drives,
        availableRidesStatus,
        availableRides,
        hasCommuteLocation,
        requestedRidesStatus,
        requestedRides,
      ];
}
