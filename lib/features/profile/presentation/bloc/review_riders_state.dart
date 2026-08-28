part of 'review_riders_bloc.dart';

enum ReviewRidersStatus { initial, loading, loaded }

class ReviewRidersState extends Equatable {
  const ReviewRidersState({
    this.status = ReviewRidersStatus.initial,
    this.riders = const [],
    this.currentIndex = 0,
    this.selectedEmoji,
    this.selectedTags = const {},
    this.comment = '',
    this.isSubmitting = false,
    this.completed = false,
  });

  final ReviewRidersStatus status;
  final List<RiderReview> riders;
  final int currentIndex;
  final int? selectedEmoji;
  final Set<String> selectedTags;
  final String comment;
  final bool isSubmitting;
  final bool completed;

  RiderReview? get currentRider =>
      currentIndex >= 0 && currentIndex < riders.length
          ? riders[currentIndex]
          : null;

  ReviewRidersState copyWith({
    ReviewRidersStatus? status,
    List<RiderReview>? riders,
    int? currentIndex,
    int? Function()? selectedEmoji,
    Set<String>? selectedTags,
    String? comment,
    bool? isSubmitting,
    bool? completed,
  }) {
    return ReviewRidersState(
      status: status ?? this.status,
      riders: riders ?? this.riders,
      currentIndex: currentIndex ?? this.currentIndex,
      selectedEmoji: selectedEmoji != null ? selectedEmoji() : this.selectedEmoji,
      selectedTags: selectedTags ?? this.selectedTags,
      comment: comment ?? this.comment,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      completed: completed ?? this.completed,
    );
  }

  @override
  List<Object?> get props => [
    status,
    riders,
    currentIndex,
    selectedEmoji,
    selectedTags,
    comment,
    isSubmitting,
    completed,
  ];
}
