part of 'track_route_bloc.dart';

abstract class TrackRouteEvent extends Equatable {
  const TrackRouteEvent();

  @override
  List<Object?> get props => [];
}

class TrackRouteStarted extends TrackRouteEvent {
  const TrackRouteStarted({
    required this.ride,
    this.riderFromAddress,
    this.riderFromLat,
    this.riderFromLng,
    this.riderToAddress,
    this.riderToLat,
    this.riderToLng,
  });

  final RideMatch ride;
  final String? riderFromAddress;
  final double? riderFromLat;
  final double? riderFromLng;
  final String? riderToAddress;
  final double? riderToLat;
  final double? riderToLng;

  @override
  List<Object?> get props => [
        ride,
        riderFromAddress,
        riderFromLat,
        riderFromLng,
        riderToAddress,
        riderToLat,
        riderToLng,
      ];
}
