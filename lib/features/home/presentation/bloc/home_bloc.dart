import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:acepool/features/home/domain/entities/upcoming_trip.dart';
import 'package:acepool/features/home/domain/usecases/get_upcoming_trips_usecase.dart';
import 'package:acepool/features/rides/domain/entities/ride_match.dart';
import 'package:acepool/features/rides/domain/usecases/find_matching_rides_usecase.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetUpcomingTripsUseCase _getUpcomingTrips;
  final FindMatchingRidesUseCase _findMatchingRides;

  HomeBloc({
    required GetUpcomingTripsUseCase getUpcomingTrips,
    required FindMatchingRidesUseCase findMatchingRides,
  })  : _getUpcomingTrips = getUpcomingTrips,
        _findMatchingRides = findMatchingRides,
        super(const HomeState()) {
    on<HomeStarted>(_onHomeStarted);
    on<RideModeChanged>(_onRideModeChanged);
    on<VehicleTypeChanged>(_onVehicleTypeChanged);
    on<FromAddressChanged>(_onFromAddressChanged);
    on<ToAddressChanged>(_onToAddressChanged);
    on<LocationsSwapped>(_onLocationsSwapped);
    on<DateSelected>(_onDateSelected);
    on<TimeSelected>(_onTimeSelected);
    on<SeatCountChanged>(_onSeatCountChanged);
    on<RideFormReset>(_onRideFormReset);
    on<FindRidesRequested>(_onFindRidesRequested);
  }

  Future<void> _onHomeStarted(HomeStarted event, Emitter<HomeState> emit) async {
    emit(state.copyWith(status: HomeStatus.loading));
    try {
      final trips = await _getUpcomingTrips();
      emit(state.copyWith(status: HomeStatus.success, upcomingTrips: trips));
    } catch (e) {
      emit(state.copyWith(status: HomeStatus.failure, errorMessage: e.toString()));
    }
  }

  void _onRideModeChanged(RideModeChanged event, Emitter<HomeState> emit) {
    emit(state.copyWith(rideMode: event.mode));
  }

  void _onVehicleTypeChanged(VehicleTypeChanged event, Emitter<HomeState> emit) {
    final maxSeats = event.vehicleType == VehicleType.bike ? 1 : 4;
    emit(state.copyWith(
      vehicleType: event.vehicleType,
      seatCount: state.seatCount > maxSeats ? maxSeats : state.seatCount,
    ));
  }

  void _onFromAddressChanged(FromAddressChanged event, Emitter<HomeState> emit) {
    emit(state.copyWith(
      fromAddress: event.address,
      fromLat: event.lat,
      fromLng: event.lng,
    ));
  }

  void _onToAddressChanged(ToAddressChanged event, Emitter<HomeState> emit) {
    emit(state.copyWith(
      toAddress: event.address,
      toLat: event.lat,
      toLng: event.lng,
    ));
  }

  void _onLocationsSwapped(LocationsSwapped event, Emitter<HomeState> emit) {
    emit(state.swapLocations());
  }

  void _onDateSelected(DateSelected event, Emitter<HomeState> emit) {
    emit(state.copyWith(selectedDate: event.date));
  }

  void _onTimeSelected(TimeSelected event, Emitter<HomeState> emit) {
    emit(state.copyWith(selectedTime: event.time));
  }

  void _onSeatCountChanged(SeatCountChanged event, Emitter<HomeState> emit) {
    emit(state.copyWith(seatCount: event.seatCount));
  }

  Future<void> _onRideFormReset(
    RideFormReset event,
    Emitter<HomeState> emit,
  ) async {
    List<UpcomingTrip> trips = state.upcomingTrips;
    try {
      trips = await _getUpcomingTrips();
    } catch (_) {}

    emit(state.resetForm().copyWith(upcomingTrips: trips));
  }

  Future<void> _onFindRidesRequested(
    FindRidesRequested event,
    Emitter<HomeState> emit,
  ) async {
    if (!state.isFormValid) return;
    emit(state.copyWith(
      findStatus: HomeStatus.loading,
      hasSearchedRides: true,
    ));
    try {
      final results = await _findMatchingRides(
        fromAddress: state.fromAddress!,
        toAddress: state.toAddress!,
        fromLat: state.fromLat,
        fromLng: state.fromLng,
        toLat: state.toLat,
        toLng: state.toLng,
        date: state.selectedDate!,
        time: state.selectedTime!,
        vehicleType: state.vehicleType.name,
      );
      emit(state.copyWith(findStatus: HomeStatus.success, findResults: results));
    } catch (e) {
      emit(state.copyWith(
        findStatus: HomeStatus.failure,
        findResults: const <RideMatch>[],
        errorMessage: e.toString(),
      ));
    }
  }
}
