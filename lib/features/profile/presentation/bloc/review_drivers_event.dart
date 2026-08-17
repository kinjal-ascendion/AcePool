part of 'review_drivers_bloc.dart';

abstract class ReviewDriversEvent extends Equatable {
  const ReviewDriversEvent();

  @override
  List<Object?> get props => [];
}

class ReviewDriversStarted extends ReviewDriversEvent {
  const ReviewDriversStarted(this.rideId);

  final String rideId;

  @override
  List<Object?> get props => [rideId];
}

class ReviewDriversEmojiSelected extends ReviewDriversEvent {
  const ReviewDriversEmojiSelected(this.rating);

  final int rating;

  @override
  List<Object?> get props => [rating];
}

class ReviewDriversTagToggled extends ReviewDriversEvent {
  const ReviewDriversTagToggled(this.tag);

  final String tag;

  @override
  List<Object?> get props => [tag];
}

class ReviewDriversCommentChanged extends ReviewDriversEvent {
  const ReviewDriversCommentChanged(this.comment);

  final String comment;

  @override
  List<Object?> get props => [comment];
}

class ReviewDriversSubmitted extends ReviewDriversEvent {
  const ReviewDriversSubmitted();
}

class ReviewDriversSkipped extends ReviewDriversEvent {
  const ReviewDriversSkipped();
}
