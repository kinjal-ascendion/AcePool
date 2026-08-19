import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:acepool/features/profile/domain/entities/rider_review.dart';
import 'package:acepool/features/profile/domain/repositories/ratings_repository.dart';

part 'review_riders_event.dart';
part 'review_riders_state.dart';

class ReviewRidersBloc extends Bloc<ReviewRidersEvent, ReviewRidersState> {
  ReviewRidersBloc({required RatingsRepository ratingsRepository})
      : _ratingsRepository = ratingsRepository,
        super(const ReviewRidersState()) {
    on<ReviewRidersStarted>(_onStarted);
    on<ReviewRidersEmojiSelected>(_onEmojiSelected);
    on<ReviewRidersTagToggled>(_onTagToggled);
    on<ReviewRidersCommentChanged>(_onCommentChanged);
    on<ReviewRidersSubmitted>(_onSubmitted);
    on<ReviewRidersSkipped>(_onSkipped);
  }

  final RatingsRepository _ratingsRepository;

  Future<void> _onStarted(
    ReviewRidersStarted event,
    Emitter<ReviewRidersState> emit,
  ) async {
    emit(state.copyWith(status: ReviewRidersStatus.loading));
    final riders = await _ratingsRepository.getRidersToReview(event.rideId);
    final firstRider = riders.isEmpty ? null : riders.first;
    emit(state.copyWith(
      status: ReviewRidersStatus.loaded,
      riders: riders,
      currentIndex: 0,
      selectedEmoji: () => firstRider?.driverRating,
    ));
  }

  void _onEmojiSelected(
    ReviewRidersEmojiSelected event,
    Emitter<ReviewRidersState> emit,
  ) {
    final rider = state.currentRider;
    if (rider == null || rider.driverRating != null) return;
    emit(state.copyWith(selectedEmoji: () => event.rating));
  }

  void _onTagToggled(
    ReviewRidersTagToggled event,
    Emitter<ReviewRidersState> emit,
  ) {
    final tags = Set<String>.from(state.selectedTags);
    if (!tags.add(event.tag)) {
      tags.remove(event.tag);
    }
    emit(state.copyWith(selectedTags: tags));
  }

  void _onCommentChanged(
    ReviewRidersCommentChanged event,
    Emitter<ReviewRidersState> emit,
  ) {
    emit(state.copyWith(comment: event.comment));
  }

  Future<void> _onSubmitted(
    ReviewRidersSubmitted event,
    Emitter<ReviewRidersState> emit,
  ) async {
    final rider = state.currentRider;
    final rating = state.selectedEmoji;
    if (state.isSubmitting ||
        rider == null ||
        rider.driverRating != null ||
        rating == null) {
      return;
    }

    emit(state.copyWith(isSubmitting: true));
    try {
      await _ratingsRepository.submitDriverRating(
        requestId: rider.requestId,
        rating: rating,
        tags: state.selectedTags.toList(),
        comment: state.comment.isEmpty ? null : state.comment,
      );
      final riders = List<RiderReview>.from(state.riders);
      riders[state.currentIndex] = rider.copyWith(driverRating: rating);
      _advance(emit, riders: riders);
    } catch (_) {
      emit(state.copyWith(isSubmitting: false));
    }
  }

  Future<void> _onSkipped(
    ReviewRidersSkipped event,
    Emitter<ReviewRidersState> emit,
  ) async {
    if (state.isSubmitting) return;
    _advance(emit);
  }

  void _advance(Emitter<ReviewRidersState> emit, {List<RiderReview>? riders}) {
    final updatedRiders = riders ?? state.riders;
    final nextIndex = state.currentIndex + 1;
    if (nextIndex >= updatedRiders.length) {
      emit(state.copyWith(
        riders: updatedRiders,
        selectedTags: const {},
        comment: '',
        isSubmitting: false,
        completed: true,
      ));
      return;
    }
    final nextRider = updatedRiders[nextIndex];
    emit(state.copyWith(
      riders: updatedRiders,
      currentIndex: nextIndex,
      selectedEmoji: () => nextRider.driverRating,
      selectedTags: const {},
      comment: '',
      isSubmitting: false,
    ));
  }
}
