import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:acepool/features/home/domain/entities/upcoming_trip.dart';
import 'package:acepool/features/home/domain/usecases/get_upcoming_trips_usecase.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetUpcomingTripsUseCase _getUpcomingTrips;

  HomeBloc({required GetUpcomingTripsUseCase getUpcomingTrips})
    : _getUpcomingTrips = getUpcomingTrips,
      super(const HomeState()) {
    on<HomeStarted>(_onHomeStarted);
    on<RideModeChanged>(_onRideModeChanged);
    on<VehicleTypeChanged>(_onVehicleTypeChanged);
    on<LocationsSwapped>(_onLocationsSwapped);
    on<DateSelected>(_onDateSelected);
    on<TimeSelected>(_onTimeSelected);
    on<SeatCountChanged>(_onSeatCountChanged);
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
    emit(state.copyWith(vehicleType: event.vehicleType));
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
}
