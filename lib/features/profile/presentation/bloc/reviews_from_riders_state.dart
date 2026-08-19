part of 'reviews_from_riders_bloc.dart';

enum ReviewsFromRidersStatus { initial, loading, loaded }

class ReviewsFromRidersState extends Equatable {
  const ReviewsFromRidersState({
    this.status = ReviewsFromRidersStatus.initial,
    this.reviews = const [],
  });

  final ReviewsFromRidersStatus status;
  final List<ReceivedReviewRide> reviews;

  ReviewsFromRidersState copyWith({
    ReviewsFromRidersStatus? status,
    List<ReceivedReviewRide>? reviews,
  }) {
    return ReviewsFromRidersState(
      status: status ?? this.status,
      reviews: reviews ?? this.reviews,
    );
  }

  @override
  List<Object?> get props => [status, reviews];
}
