part of 'review_riders_bloc.dart';

abstract class ReviewRidersEvent extends Equatable {
  const ReviewRidersEvent();

  @override
  List<Object?> get props => [];
}

class ReviewRidersStarted extends ReviewRidersEvent {
  const ReviewRidersStarted(this.rideId);

  final String rideId;

  @override
  List<Object?> get props => [rideId];
}

class ReviewRidersStarSelected extends ReviewRidersEvent {
  const ReviewRidersStarSelected({required this.requestId, required this.rating});

  final String requestId;
  final int rating;

  @override
  List<Object?> get props => [requestId, rating];
}

class ReviewRidersSubmitted extends ReviewRidersEvent {
  const ReviewRidersSubmitted(this.requestId);

  final String requestId;

  @override
  List<Object?> get props => [requestId];
}
