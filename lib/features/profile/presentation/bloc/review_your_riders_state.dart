part of 'review_your_riders_bloc.dart';

enum ReviewYourRidersStatus { initial, loading, loaded }

class ReviewYourRidersState extends Equatable {
  const ReviewYourRidersState({
    this.status = ReviewYourRidersStatus.initial,
    this.rides = const [],
  });

  final ReviewYourRidersStatus status;
  final List<DriverRatableRide> rides;

  ReviewYourRidersState copyWith({
    ReviewYourRidersStatus? status,
    List<DriverRatableRide>? rides,
  }) {
    return ReviewYourRidersState(
      status: status ?? this.status,
      rides: rides ?? this.rides,
    );
  }

  @override
  List<Object?> get props => [status, rides];
}
