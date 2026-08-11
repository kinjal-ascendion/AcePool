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
    on<ReviewRidersStarSelected>(_onStarSelected);
    on<ReviewRidersSubmitted>(_onSubmitted);
  }

  final RatingsRepository _ratingsRepository;

  Future<void> _onStarted(ReviewRidersStarted event, Emitter<ReviewRidersState> emit) async {
    emit(state.copyWith(status: ReviewRidersStatus.loading));
    final riders = await _ratingsRepository.getRidersToReview(event.rideId);
    emit(state.copyWith(status: ReviewRidersStatus.loaded, riders: riders));
  }

  void _onStarSelected(ReviewRidersStarSelected event, Emitter<ReviewRidersState> emit) {
    final selectedRatings = Map<String, int>.from(state.selectedRatings);
    selectedRatings[event.requestId] = event.rating;
    emit(state.copyWith(selectedRatings: selectedRatings));
  }

  Future<void> _onSubmitted(
    ReviewRidersSubmitted event,
    Emitter<ReviewRidersState> emit,
  ) async {
    final rating = state.selectedRatings[event.requestId];
    if (rating == null) return;

    await _ratingsRepository.submitDriverRating(requestId: event.requestId, rating: rating);

    final riders = List<RiderReview>.from(state.riders);
    final index = riders.indexWhere((r) => r.requestId == event.requestId);
    if (index != -1) {
      riders[index] = riders[index].copyWith(driverRating: rating);
    }
    emit(state.copyWith(riders: riders));
  }
}
