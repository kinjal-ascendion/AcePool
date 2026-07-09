import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:acepool/features/home/domain/entities/upcoming_trip.dart';
import 'package:acepool/features/home/domain/usecases/get_upcoming_trips_usecase.dart';
import 'package:acepool/features/home/domain/usecases/schedule_ride_usecase.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetUpcomingTripsUseCase _getUpcomingTrips;
  final ScheduleRideUseCase _scheduleRide;

  HomeBloc({
    required GetUpcomingTripsUseCase getUpcomingTrips,
    required ScheduleRideUseCase scheduleRide,
  })  : _getUpcomingTrips = getUpcomingTrips,
        _scheduleRide = scheduleRide,
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
    on<ScheduleRideRequested>(_onScheduleRideRequested);
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

  void _onFromAddressChanged(FromAddressChanged event, Emitter<HomeState> emit) {
    emit(state.copyWith(fromAddress: event.address, fromLatLng: event.latLng));
  }

  void _onToAddressChanged(ToAddressChanged event, Emitter<HomeState> emit) {
    emit(state.copyWith(toAddress: event.address, toLatLng: event.latLng));
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

  Future<void> _onScheduleRideRequested(
    ScheduleRideRequested event,
    Emitter<HomeState> emit,
  ) async {
    if (!state.isFormValid) return;
    emit(state.copyWith(status: HomeStatus.scheduling));
    try {
      await _scheduleRide(
        rideMode: state.rideMode.name,
        vehicleType: state.vehicleType.name,
        fromAddress: state.fromAddress!,
        toAddress: state.toAddress!,
        fromLatLng: state.fromLatLng,
        toLatLng: state.toLatLng,
        date: state.selectedDate!,
        time: state.selectedTime!,
        seatCount: state.seatCount,
      );
    } catch (e) {
      emit(state.copyWith(
        status: HomeStatus.failure,
        errorMessage: e.toString(),
      ));
      return;
    }

    List<UpcomingTrip> trips = state.upcomingTrips;
    try {
      trips = await _getUpcomingTrips();
    } catch (_) {}

    emit(state.resetForm().copyWith(
      status: HomeStatus.scheduled,
      upcomingTrips: trips,
    ));
  }
}
