import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:acepool/features/profile/domain/repositories/ride_history_repository.dart';

part 'ride_history_event.dart';
part 'ride_history_state.dart';

class RideHistoryBloc extends Bloc<RideHistoryEvent, RideHistoryState> {
  RideHistoryBloc({required RideHistoryRepository rideHistoryRepository})
      : _rideHistoryRepository = rideHistoryRepository,
        super(const RideHistoryState()) {
    on<RideHistoryStarted>(_onStarted);
  }

  final RideHistoryRepository _rideHistoryRepository;

  Future<void> _onStarted(RideHistoryStarted event, Emitter<RideHistoryState> emit) async {
    emit(state.copyWith(status: RideHistoryStatus.loading));
    final rides = await _rideHistoryRepository.getHistory();
    emit(state.copyWith(status: RideHistoryStatus.loaded, rides: rides));
  }
}
