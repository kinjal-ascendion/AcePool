part of 'reviews_from_riders_bloc.dart';

abstract class ReviewsFromRidersEvent extends Equatable {
  const ReviewsFromRidersEvent();

  @override
  List<Object?> get props => [];
}

class ReviewsFromRidersStarted extends ReviewsFromRidersEvent {
  const ReviewsFromRidersStarted();
}
