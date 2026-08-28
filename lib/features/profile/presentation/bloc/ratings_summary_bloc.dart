import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:acepool/features/profile/domain/entities/received_rating_ride.dart';
import 'package:acepool/features/profile/domain/repositories/ratings_repository.dart';


part 'ratings_summary_event.dart';
part 'ratings_summary_state.dart';

class RatingsSummaryBloc extends Bloc<RatingsSummaryEvent, RatingsSummaryState> {
  RatingsSummaryBloc({required RatingsRepository ratingsRepository})
      : super(const RatingsSummaryState()) {
    on<RatingsSummaryRequested>(_onRequested);
  }

  Future<void> _onRequested(
    RatingsSummaryRequested event,
    Emitter<RatingsSummaryState> emit,
  ) async {
    emit(state.copyWith(status: RatingsSummaryStatus.loading));
  }
}
