import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:acepool/features/profile/domain/entities/driver_ratable_ride.dart';
import 'package:acepool/features/profile/domain/repositories/ratings_repository.dart';

part 'review_your_riders_event.dart';
part 'review_your_riders_state.dart';

class ReviewYourRidersBloc extends Bloc<ReviewYourRidersEvent, ReviewYourRidersState> {
  ReviewYourRidersBloc({required RatingsRepository ratingsRepository})
      : _ratingsRepository = ratingsRepository,
        super(const ReviewYourRidersState()) {
    on<ReviewYourRidersStarted>(_onStarted);
  }

  final RatingsRepository _ratingsRepository;

  Future<void> _onStarted(
    ReviewYourRidersStarted event,
    Emitter<ReviewYourRidersState> emit,
  ) async {
    emit(state.copyWith(status: ReviewYourRidersStatus.loading));
    final rides = await _ratingsRepository.getMyCompletedRidesAsDriver();
    emit(state.copyWith(status: ReviewYourRidersStatus.loaded, rides: rides));
  }
}
