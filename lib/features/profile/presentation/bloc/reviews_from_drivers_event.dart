part of 'reviews_from_drivers_bloc.dart';

abstract class ReviewsFromDriversEvent extends Equatable {
  const ReviewsFromDriversEvent();

  @override
  List<Object?> get props => [];
}

class ReviewsFromDriversStarted extends ReviewsFromDriversEvent {
  const ReviewsFromDriversStarted();
}
