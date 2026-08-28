part of 'ratings_by_you_bloc.dart';

enum RatingsByYouStatus { initial, loading, loaded }

class RatingsByYouState extends Equatable {
  const RatingsByYouState({
    this.status = RatingsByYouStatus.initial,
    this.rides = const [],
  });

  final RatingsByYouStatus status;
  final List<RiderRatableRide> rides;

  RatingsByYouState copyWith({
    RatingsByYouStatus? status,
    List<RiderRatableRide>? rides,
  }) {
    return RatingsByYouState(
      status: status ?? this.status,
      rides: rides ?? this.rides,
    );
  }

  @override
  List<Object?> get props => [status, rides];
}
