part of 'review_your_riders_bloc.dart';

abstract class ReviewYourRidersEvent extends Equatable {
  const ReviewYourRidersEvent();

  @override
  List<Object?> get props => [];
}

class ReviewYourRidersStarted extends ReviewYourRidersEvent {
  const ReviewYourRidersStarted();
}
