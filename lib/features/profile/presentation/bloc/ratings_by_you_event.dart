part of 'ratings_by_you_bloc.dart';

abstract class RatingsByYouEvent extends Equatable {
  const RatingsByYouEvent();

  @override
  List<Object?> get props => [];
}

class RatingsByYouStarted extends RatingsByYouEvent {
  const RatingsByYouStarted();
}
