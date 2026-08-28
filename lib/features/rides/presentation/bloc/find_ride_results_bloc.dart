import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:acepool/features/rides/domain/entities/ride_match.dart';
import 'package:acepool/features/rides/domain/usecases/find_matching_rides_usecase.dart';

part 'find_ride_results_event.dart';
part 'find_ride_results_state.dart';

class FindRideResultsBloc extends Bloc<FindRideResultsEvent, FindRideResultsState> {
  FindRideResultsBloc({required FindMatchingRidesUseCase findMatchingRides})
      : _findMatchingRides = findMatchingRides,
        super(const FindRideResultsState()) {
    on<FindRideResultsRequested>(_onRequested);
    on<FindRideResultsRefreshed>(_onRefreshed);
  }

  final FindMatchingRidesUseCase _findMatchingRides;

  Future<void> _onRequested(
    FindRideResultsRequested event,
    Emitter<FindRideResultsState> emit,
  ) async {
    emit(state.copyWith(
      status: FindRideResultsStatus.loading,
      fromAddress: event.fromAddress,
      toAddress: event.toAddress,
      fromLat: event.fromLat,
      fromLng: event.fromLng,
      toLat: event.toLat,
      toLng: event.toLng,
      date: event.date,
      time: event.time,
      vehicleType: event.vehicleType,
      currentLat: event.currentLat,
      currentLng: event.currentLng,
    ));
    await _fetch(emit);
  }

  Future<void> _onRefreshed(
    FindRideResultsRefreshed event,
    Emitter<FindRideResultsState> emit,
  ) async {
    emit(state.copyWith(status: FindRideResultsStatus.loading));
    await _fetch(emit);
  }

  Future<void> _fetch(Emitter<FindRideResultsState> emit) async {
    List<RideMatch> results;
    try {
      results = await _findMatchingRides(
        fromAddress: state.fromAddress!,
        toAddress: state.toAddress!,
        fromLat: state.fromLat,
        fromLng: state.fromLng,
        toLat: state.toLat,
        toLng: state.toLng,
        date: state.date!,
        time: state.time!,
        vehicleType: state.vehicleType!,
      );
    } catch (_) {
      // Matches original FutureBuilder behavior: on failure, results just
      // render as empty rather than a distinct error state.
      results = const [];
    }
    emit(state.copyWith(status: FindRideResultsStatus.loaded, results: results));
  }
}
