part of 'review_drivers_bloc.dart';

enum ReviewDriversStatus { initial, loading, loaded }

class ReviewDriversState extends Equatable {
  const ReviewDriversState({
    this.status = ReviewDriversStatus.initial,
    this.drivers = const [],
    this.currentIndex = 0,
    this.selectedEmoji,
    this.selectedTags = const {},
    this.comment = '',
    this.isSubmitting = false,
    this.completed = false,
  });

  final ReviewDriversStatus status;
  final List<DriverReview> drivers;
  final int currentIndex;
  final int? selectedEmoji;
  final Set<String> selectedTags;
  final String comment;
  final bool isSubmitting;
  final bool completed;

  DriverReview? get currentDriver =>
      currentIndex >= 0 && currentIndex < drivers.length
          ? drivers[currentIndex]
          : null;

  ReviewDriversState copyWith({
    ReviewDriversStatus? status,
    List<DriverReview>? drivers,
    int? currentIndex,
    int? Function()? selectedEmoji,
    Set<String>? selectedTags,
    String? comment,
    bool? isSubmitting,
    bool? completed,
  }) {
    return ReviewDriversState(
      status: status ?? this.status,
      drivers: drivers ?? this.drivers,
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
    drivers,
    currentIndex,
    selectedEmoji,
    selectedTags,
    comment,
    isSubmitting,
    completed,
  ];
}
