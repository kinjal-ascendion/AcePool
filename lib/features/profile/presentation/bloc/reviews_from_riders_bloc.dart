import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:acepool/features/profile/domain/entities/received_rating_ride.dart';
import 'package:acepool/features/profile/domain/repositories/ratings_repository.dart';

part 'reviews_from_riders_event.dart';
part 'reviews_from_riders_state.dart';

class ReviewsFromRidersBloc extends Bloc<ReviewsFromRidersEvent, ReviewsFromRidersState> {
  ReviewsFromRidersBloc({required RatingsRepository ratingsRepository})
      : _ratingsRepository = ratingsRepository,
        super(const ReviewsFromRidersState()) {
    on<ReviewsFromRidersStarted>(_onStarted);
  }

  final RatingsRepository _ratingsRepository;

  Future<void> _onStarted(
    ReviewsFromRidersStarted event,
    Emitter<ReviewsFromRidersState> emit,
  ) async {
    emit(state.copyWith(status: ReviewsFromRidersStatus.loading));
    final reviews = await _ratingsRepository.getRatingsReceivedFromRiders();
    emit(state.copyWith(status: ReviewsFromRidersStatus.loaded, reviews: reviews));
  }
}
