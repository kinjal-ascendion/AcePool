import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:acepool/features/profile/domain/entities/rider_ratable_ride.dart';
import 'package:acepool/features/profile/domain/repositories/ratings_repository.dart';

part 'ratings_by_you_event.dart';
part 'ratings_by_you_state.dart';

class RatingsByYouBloc extends Bloc<RatingsByYouEvent, RatingsByYouState> {
  RatingsByYouBloc({required RatingsRepository ratingsRepository})
      : _ratingsRepository = ratingsRepository,
        super(const RatingsByYouState()) {
    on<RatingsByYouStarted>(_onStarted);
  }

  final RatingsRepository _ratingsRepository;

  Future<void> _onStarted(RatingsByYouStarted event, Emitter<RatingsByYouState> emit) async {
    emit(state.copyWith(status: RatingsByYouStatus.loading));
    final rides = await _ratingsRepository.getMyCompletedRidesToRate();
    emit(state.copyWith(status: RatingsByYouStatus.loaded, rides: rides));
  }
}
