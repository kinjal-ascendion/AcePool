import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:acepool/features/home/domain/entities/upcoming_trip.dart';
import 'package:acepool/features/rides/domain/entities/ride_rider.dart';
import 'package:acepool/features/rides/domain/repositories/rides_repository.dart';

part 'drives_detail_event.dart';
part 'drives_detail_state.dart';

class DrivesDetailBloc extends Bloc<DrivesDetailEvent, DrivesDetailState> {
  DrivesDetailBloc({required RidesRepository ridesRepository})
      : _ridesRepository = ridesRepository,
        super(const DrivesDetailState()) {
    on<DrivesDetailStarted>(_onStarted);
    on<DrivesDetailReloadRequested>(_onReloadRequested);
    on<DrivesDetailStatusChangeRequested>(_onStatusChangeRequested);
    on<DrivesDetailNegotiationResponded>(_onNegotiationResponded);
  }

  final RidesRepository _ridesRepository;

  Future<void> _onNegotiationResponded(
    DrivesDetailNegotiationResponded event,
    Emitter<DrivesDetailState> emit,
  ) async {
    try {
      await _ridesRepository.respondToNegotiation(
        requestId: event.requestId,
        status: event.status,
      );
      add(const DrivesDetailReloadRequested());
    } catch (e) {
      emit(state.copyWith(snackbarMessage: 'Failed to update negotiation: $e'));
    }
  }

  Future<void> _onStarted(
    DrivesDetailStarted event,
    Emitter<DrivesDetailState> emit,
  ) async {
    emit(state.copyWith(currentTrip: event.trip, ridersStatus: DrivesDetailRidersStatus.loading));
    await _loadRiders(emit, event.trip.id);
  }

  Future<void> _onReloadRequested(
    DrivesDetailReloadRequested event,
    Emitter<DrivesDetailState> emit,
  ) async {
    emit(state.copyWith(ridersStatus: DrivesDetailRidersStatus.loading));
    await _loadRiders(emit, state.currentTrip!.id);
  }

  Future<void> _loadRiders(Emitter<DrivesDetailState> emit, String tripId) async {
    try {
      final riders = await _ridesRepository.getRidersForCurrentDriver(rideId: tripId);
      emit(state.copyWith(ridersStatus: DrivesDetailRidersStatus.loaded, riders: riders));
    } catch (e) {
      emit(state.copyWith(
        ridersStatus: DrivesDetailRidersStatus.error,
        ridersError: e,
      ));
    }
  }

  Future<void> _onStatusChangeRequested(
    DrivesDetailStatusChangeRequested event,
    Emitter<DrivesDetailState> emit,
  ) async {
    try {
      await _ridesRepository.updateRideStatus(state.currentTrip!.id, event.status);
      emit(state.copyWith(
        currentTrip: state.currentTrip!.copyWith(status: event.status),
        statusUpdateTick: state.statusUpdateTick + 1,
        lastUpdatedStatus: event.status,
      ));
    } catch (e) {
      emit(state.copyWith(snackbarMessage: 'Failed to update trip: $e'));
    }
  }
}
