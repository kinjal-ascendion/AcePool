import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:acepool/features/rides/domain/entities/ride_match.dart';
import 'package:acepool/features/rides/domain/entities/rider_journey.dart';
import 'package:acepool/features/rides/domain/repositories/rides_repository.dart';

part 'track_route_event.dart';
part 'track_route_state.dart';

class TrackRouteBloc extends Bloc<TrackRouteEvent, TrackRouteState> {
  TrackRouteBloc({required RidesRepository ridesRepository})
      : _ridesRepository = ridesRepository,
        super(const TrackRouteState()) {
    on<TrackRouteStarted>(_onStarted);
  }

  final RidesRepository _ridesRepository;

  Future<void> _onStarted(TrackRouteStarted event, Emitter<TrackRouteState> emit) async {
    emit(state.copyWith(status: TrackRouteStatus.loading));
    try {
      final journey = await _ridesRepository.getRiderJourney(
        ride: event.ride,
        riderFromAddress: event.riderFromAddress,
        riderFromLat: event.riderFromLat,
        riderFromLng: event.riderFromLng,
        riderToAddress: event.riderToAddress,
        riderToLat: event.riderToLat,
        riderToLng: event.riderToLng,
      );
      emit(state.copyWith(status: TrackRouteStatus.loaded, journey: journey));
    } catch (e) {
      emit(state.copyWith(status: TrackRouteStatus.error, errorMessage: e.toString()));
    }
  }
}
