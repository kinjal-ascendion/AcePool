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
    on<RatingsByYouExpandToggled>(_onExpandToggled);
    on<RatingsByYouStarSelected>(_onStarSelected);
    on<RatingsByYouSubmitted>(_onSubmitted);
  }

  final RatingsRepository _ratingsRepository;

  Future<void> _onStarted(RatingsByYouStarted event, Emitter<RatingsByYouState> emit) async {
    emit(state.copyWith(status: RatingsByYouStatus.loading));
    final rides = await _ratingsRepository.getMyCompletedRidesToRate();
    emit(state.copyWith(status: RatingsByYouStatus.loaded, rides: rides));
  }

  void _onExpandToggled(RatingsByYouExpandToggled event, Emitter<RatingsByYouState> emit) {
    final isSameRide = state.expandedRequestId == event.requestId;
    emit(state.copyWith(
      expandedRequestId: isSameRide ? null : event.requestId,
      clearExpandedRequestId: isSameRide,
      selectedRating: 0,
    ));
  }

  void _onStarSelected(RatingsByYouStarSelected event, Emitter<RatingsByYouState> emit) {
    emit(state.copyWith(selectedRating: event.rating));
  }

  Future<void> _onSubmitted(
    RatingsByYouSubmitted event,
    Emitter<RatingsByYouState> emit,
  ) async {
    try {
      await _ratingsRepository.submitRiderRating(
        requestId: event.requestId,
        rating: state.selectedRating,
      );

      final rides = List<RiderRatableRide>.from(state.rides);
      final index = rides.indexWhere((r) => r.requestId == event.requestId);
      if (index != -1) {
        rides[index] = rides[index].copyWith(riderRating: state.selectedRating);
      }

      emit(state.copyWith(
        rides: rides,
        clearExpandedRequestId: true,
        selectedRating: 0,
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }
}
