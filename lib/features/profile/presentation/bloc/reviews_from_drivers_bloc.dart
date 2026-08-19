import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:acepool/features/profile/domain/entities/received_rating_ride.dart';
import 'package:acepool/features/profile/domain/repositories/ratings_repository.dart';

part 'reviews_from_drivers_event.dart';
part 'reviews_from_drivers_state.dart';

class ReviewsFromDriversBloc extends Bloc<ReviewsFromDriversEvent, ReviewsFromDriversState> {
  ReviewsFromDriversBloc({required RatingsRepository ratingsRepository})
      : _ratingsRepository = ratingsRepository,
        super(const ReviewsFromDriversState()) {
    on<ReviewsFromDriversStarted>(_onStarted);
  }

  final RatingsRepository _ratingsRepository;

  Future<void> _onStarted(
    ReviewsFromDriversStarted event,
    Emitter<ReviewsFromDriversState> emit,
  ) async {
    emit(state.copyWith(status: ReviewsFromDriversStatus.loading));
    final reviews = await _ratingsRepository.getRatingsReceivedFromDrivers();
    emit(state.copyWith(status: ReviewsFromDriversStatus.loaded, reviews: reviews));
  }
}
