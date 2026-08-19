part of 'reviews_from_drivers_bloc.dart';

enum ReviewsFromDriversStatus { initial, loading, loaded }

class ReviewsFromDriversState extends Equatable {
  const ReviewsFromDriversState({
    this.status = ReviewsFromDriversStatus.initial,
    this.reviews = const [],
  });

  final ReviewsFromDriversStatus status;
  final List<ReceivedReviewFromDriver> reviews;

  ReviewsFromDriversState copyWith({
    ReviewsFromDriversStatus? status,
    List<ReceivedReviewFromDriver>? reviews,
  }) {
    return ReviewsFromDriversState(
      status: status ?? this.status,
      reviews: reviews ?? this.reviews,
    );
  }

  @override
  List<Object?> get props => [status, reviews];
}
