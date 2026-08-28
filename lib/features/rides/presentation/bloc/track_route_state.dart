part of 'track_route_bloc.dart';

enum TrackRouteStatus { initial, loading, loaded, error }

class TrackRouteState extends Equatable {
  const TrackRouteState({
    this.status = TrackRouteStatus.initial,
    this.journey,
    this.errorMessage,
  });

  final TrackRouteStatus status;
  final RiderJourney? journey;
  final String? errorMessage;

  TrackRouteState copyWith({
    TrackRouteStatus? status,
    RiderJourney? journey,
    String? errorMessage,
  }) {
    return TrackRouteState(
      status: status ?? this.status,
      journey: journey ?? this.journey,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, journey, errorMessage];
}
