part of 'review_riders_bloc.dart';

enum ReviewRidersStatus { initial, loading, loaded }

class ReviewRidersState extends Equatable {
  const ReviewRidersState({
    this.status = ReviewRidersStatus.initial,
    this.riders = const [],
    this.selectedRatings = const {},
  });

  final ReviewRidersStatus status;
  final List<RiderReview> riders;
  final Map<String, int> selectedRatings;

  ReviewRidersState copyWith({
    ReviewRidersStatus? status,
    List<RiderReview>? riders,
    Map<String, int>? selectedRatings,
  }) {
    return ReviewRidersState(
      status: status ?? this.status,
      riders: riders ?? this.riders,
      selectedRatings: selectedRatings ?? this.selectedRatings,
    );
  }

  @override
  List<Object?> get props => [status, riders, selectedRatings];
}
