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

class ReviewRidersEmojiSelected extends ReviewRidersEvent {
  const ReviewRidersEmojiSelected(this.rating);

  final int rating;

  @override
  List<Object?> get props => [rating];
}

class ReviewRidersTagToggled extends ReviewRidersEvent {
  const ReviewRidersTagToggled(this.tag);

  final String tag;

  @override
  List<Object?> get props => [tag];
}

class ReviewRidersCommentChanged extends ReviewRidersEvent {
  const ReviewRidersCommentChanged(this.comment);

  final String comment;

  @override
  List<Object?> get props => [comment];
}

class ReviewRidersSubmitted extends ReviewRidersEvent {
  const ReviewRidersSubmitted();
}

class ReviewRidersSkipped extends ReviewRidersEvent {
  const ReviewRidersSkipped();
}
