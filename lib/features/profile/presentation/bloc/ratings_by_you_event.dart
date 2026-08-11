part of 'ratings_by_you_bloc.dart';

abstract class RatingsByYouEvent extends Equatable {
  const RatingsByYouEvent();

  @override
  List<Object?> get props => [];
}

class RatingsByYouStarted extends RatingsByYouEvent {
  const RatingsByYouStarted();
}

class RatingsByYouExpandToggled extends RatingsByYouEvent {
  const RatingsByYouExpandToggled(this.requestId);

  final String requestId;

  @override
  List<Object?> get props => [requestId];
}

class RatingsByYouStarSelected extends RatingsByYouEvent {
  const RatingsByYouStarSelected(this.rating);

  final int rating;

  @override
  List<Object?> get props => [rating];
}

class RatingsByYouSubmitted extends RatingsByYouEvent {
  const RatingsByYouSubmitted(this.requestId);

  final String requestId;

  @override
  List<Object?> get props => [requestId];
}
