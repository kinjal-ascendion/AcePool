import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:acepool/features/profile/domain/entities/driver_review.dart';
import 'package:acepool/features/profile/domain/repositories/ratings_repository.dart';

part 'review_drivers_event.dart';
part 'review_drivers_state.dart';

class ReviewDriversBloc extends Bloc<ReviewDriversEvent, ReviewDriversState> {
  ReviewDriversBloc({required RatingsRepository ratingsRepository})
      : _ratingsRepository = ratingsRepository,
        super(const ReviewDriversState()) {
    on<ReviewDriversStarted>(_onStarted);
    on<ReviewDriversEmojiSelected>(_onEmojiSelected);
    on<ReviewDriversTagToggled>(_onTagToggled);
    on<ReviewDriversCommentChanged>(_onCommentChanged);
    on<ReviewDriversSubmitted>(_onSubmitted);
    on<ReviewDriversSkipped>(_onSkipped);
  }

  final RatingsRepository _ratingsRepository;

  Future<void> _onStarted(
    ReviewDriversStarted event,
    Emitter<ReviewDriversState> emit,
  ) async {
    emit(state.copyWith(status: ReviewDriversStatus.loading));
    final drivers = await _ratingsRepository.getDriversToReview(event.rideId);
    final firstDriver = drivers.isEmpty ? null : drivers.first;
    emit(state.copyWith(
      status: ReviewDriversStatus.loaded,
      drivers: drivers,
      currentIndex: 0,
      selectedEmoji: () => firstDriver?.riderRating,
    ));
  }

  void _onEmojiSelected(
    ReviewDriversEmojiSelected event,
    Emitter<ReviewDriversState> emit,
  ) {
    final driver = state.currentDriver;
    if (driver == null || driver.riderRating != null) return;
    emit(state.copyWith(selectedEmoji: () => event.rating));
  }

  void _onTagToggled(
    ReviewDriversTagToggled event,
    Emitter<ReviewDriversState> emit,
  ) {
    final tags = Set<String>.from(state.selectedTags);
    if (!tags.add(event.tag)) {
      tags.remove(event.tag);
    }
    emit(state.copyWith(selectedTags: tags));
  }

  void _onCommentChanged(
    ReviewDriversCommentChanged event,
    Emitter<ReviewDriversState> emit,
  ) {
    emit(state.copyWith(comment: event.comment));
  }

  Future<void> _onSubmitted(
    ReviewDriversSubmitted event,
    Emitter<ReviewDriversState> emit,
  ) async {
    final driver = state.currentDriver;
    final rating = state.selectedEmoji;
    if (state.isSubmitting ||
        driver == null ||
        driver.riderRating != null ||
        rating == null) {
      return;
    }

    emit(state.copyWith(isSubmitting: true));
    try {
      await _ratingsRepository.submitRiderRating(
        requestId: driver.requestId,
        rating: rating,
      );
      final drivers = List<DriverReview>.from(state.drivers);
      drivers[state.currentIndex] = driver.copyWith(riderRating: rating);
      _advance(emit, drivers: drivers);
    } catch (_) {
      emit(state.copyWith(isSubmitting: false));
    }
  }

  Future<void> _onSkipped(
    ReviewDriversSkipped event,
    Emitter<ReviewDriversState> emit,
  ) async {
    if (state.isSubmitting) return;
    _advance(emit);
  }

  void _advance(Emitter<ReviewDriversState> emit, {List<DriverReview>? drivers}) {
    final updatedDrivers = drivers ?? state.drivers;
    final nextIndex = state.currentIndex + 1;
    if (nextIndex >= updatedDrivers.length) {
      emit(state.copyWith(
        drivers: updatedDrivers,
        selectedTags: const {},
        comment: '',
        isSubmitting: false,
        completed: true,
      ));
      return;
    }
    final nextDriver = updatedDrivers[nextIndex];
    emit(state.copyWith(
      drivers: updatedDrivers,
      currentIndex: nextIndex,
      selectedEmoji: () => nextDriver.riderRating,
      selectedTags: const {},
      comment: '',
      isSubmitting: false,
    ));
  }
}
