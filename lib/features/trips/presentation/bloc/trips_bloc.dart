import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:acepool/features/home/domain/entities/upcoming_trip.dart';
import 'package:acepool/features/trips/domain/entities/available_ride.dart';
import 'package:acepool/features/trips/domain/entities/requested_ride.dart';
import 'package:acepool/features/trips/domain/repositories/trips_repository.dart';

part 'trips_event.dart';
part 'trips_state.dart';

class TripsBloc extends Bloc<TripsEvent, TripsState> {
  TripsBloc({required TripsRepository tripsRepository})
      : _tripsRepository = tripsRepository,
        super(const TripsState()) {
    on<TripsDrivesRequested>(_onDrivesRequested);
    on<TripsAvailableRidesRequested>(_onAvailableRidesRequested);
    on<TripsRequestedRidesRequested>(_onRequestedRidesRequested);
    on<TripsPreferenceUpdated>(_onPreferenceUpdated);
  }

  final TripsRepository _tripsRepository;

  Future<void> _onDrivesRequested(
    TripsDrivesRequested event,
    Emitter<TripsState> emit,
  ) async {
    emit(state.copyWith(drivesStatus: TripsSectionStatus.loading));
    final drives = await _tripsRepository.getTrips('offer');
    emit(state.copyWith(drivesStatus: TripsSectionStatus.loaded, drives: drives));
  }

  Future<void> _onAvailableRidesRequested(
    TripsAvailableRidesRequested event,
    Emitter<TripsState> emit,
  ) async {
    emit(state.copyWith(availableRidesStatus: TripsSectionStatus.loading));
    final hasCommuteLocation = (event.fromAddress?.trim().isNotEmpty ?? false) &&
        (event.toAddress?.trim().isNotEmpty ?? false);
    final rides = await _tripsRepository.getAvailableRides(
      fromAddress: event.fromAddress,
      toAddress: event.toAddress,
      fromLat: event.fromLat,
      fromLng: event.fromLng,
      toLat: event.toLat,
      toLng: event.toLng,
    );
    emit(state.copyWith(
      availableRidesStatus: TripsSectionStatus.loaded,
      availableRides: rides,
      hasCommuteLocation: hasCommuteLocation,
    ));
  }

  Future<void> _onRequestedRidesRequested(
    TripsRequestedRidesRequested event,
    Emitter<TripsState> emit,
  ) async {
    emit(state.copyWith(requestedRidesStatus: TripsSectionStatus.loading));
    final requests = await _tripsRepository.getRideRequests(
      homeFromAddress: event.homeFromAddress,
      homeToAddress: event.homeToAddress,
      homeFromLat: event.homeFromLat,
      homeFromLng: event.homeFromLng,
      homeToLat: event.homeToLat,
      homeToLng: event.homeToLng,
    );
    emit(state.copyWith(
      requestedRidesStatus: TripsSectionStatus.loaded,
      requestedRides: requests,
    ));
  }

  void _onPreferenceUpdated(
    TripsPreferenceUpdated event,
    Emitter<TripsState> emit,
  ) {
    // This handles immediate UI update when preference changes in Profile
  }
}
