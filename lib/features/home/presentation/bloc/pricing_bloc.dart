import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:acepool/features/home/domain/entities/fare_breakdown.dart';
import 'package:acepool/features/home/domain/entities/vehicle_option.dart';
import 'package:acepool/features/home/domain/usecases/estimate_route_usecase.dart';
import 'package:acepool/features/home/domain/usecases/get_vehicle_options_usecase.dart';
import 'package:acepool/features/home/domain/usecases/schedule_ride_usecase.dart';
import 'package:acepool/features/home/domain/usecases/update_ride_usecase.dart';

part 'pricing_event.dart';
part 'pricing_state.dart';

class PricingBloc extends Bloc<PricingEvent, PricingState> {
  final EstimateRouteUseCase _estimateRoute;
  final ScheduleRideUseCase _scheduleRide;
  final UpdateRideUseCase _updateRide;
  final GetVehicleOptionsUseCase _getVehicleOptions;

  double? _fromLat;
  double? _fromLng;
  double? _toLat;
  double? _toLng;
  String _vehicleType = 'car';
  String _rideMode = 'offer';

  PricingBloc({
    required EstimateRouteUseCase estimateRoute,
    required ScheduleRideUseCase scheduleRide,
    required UpdateRideUseCase updateRide,
    required GetVehicleOptionsUseCase getVehicleOptions,
  })  : _estimateRoute = estimateRoute,
        _scheduleRide = scheduleRide,
        _updateRide = updateRide,
        _getVehicleOptions = getVehicleOptions,
        super(const PricingState()) {
    on<PricingStarted>(_onPricingStarted);
    on<PricingTabChanged>(_onPricingTabChanged);
    on<VehicleSelected>(_onVehicleSelected);
    on<RatePerKmChanged>(_onRatePerKmChanged);
    on<VehiclesRefreshRequested>(_onVehiclesRefreshRequested);
    on<PublishRideRequested>(_onPublishRideRequested);
    on<PricingLocationsSwapped>(_onLocationsSwapped);
  }

  void _onPricingTabChanged(PricingTabChanged event, Emitter<PricingState> emit) {
    emit(state.copyWith(activeTab: event.tab));
  }

  Future<void> _onPricingStarted(
    PricingStarted event,
    Emitter<PricingState> emit,
  ) async {
    _fromLat = event.fromLat;
    _fromLng = event.fromLng;
    _toLat = event.toLat;
    _toLng = event.toLng;
    _vehicleType = event.vehicleType;
    _rideMode = event.rideMode;

    emit(state.copyWith(
      status: PricingStatus.loading,
      fromAddress: event.fromAddress,
      toAddress: event.toAddress,
      date: event.date,
      time: event.time,
      seatCount: event.seatCount,
      hasReturnRide: event.hasReturnRide,
      returnTime: event.returnTime,
      returnSeatCount: event.returnSeatCount,
      vehicleType: _vehicleType,
      rideId: event.rideId,
    ));

    double distanceKm = 0.0;
    int durationMinutes = 0;
    if (_fromLat != null && _fromLng != null && _toLat != null && _toLng != null) {
      final route = await _estimateRoute(
        originLat: _fromLat!,
        originLng: _fromLng!,
        destLat: _toLat!,
        destLng: _toLng!,
      );
      distanceKm = route.distanceKm;
      durationMinutes = route.durationMinutes;
    }

    // Return ride estimation (assuming swapped route for simplicity,
    // though real traffic might differ).
    double returnDistanceKm = distanceKm;
    int returnDurationMinutes = durationMinutes;

    final vehicles = await _getVehicleOptions(_vehicleType);

    emit(state.copyWith(
      status: PricingStatus.ready,
      fare: FareBreakdown(
        distanceKm: distanceKm,
        durationMinutes: durationMinutes,
        ratePerKm: 0,
      ),
      returnFare: event.hasReturnRide
          ? FareBreakdown(
              distanceKm: returnDistanceKm,
              durationMinutes: returnDurationMinutes,
              ratePerKm: 0,
            )
          : null,
      vehicles: vehicles,
    ));
  }

  void _onVehicleSelected(VehicleSelected event, Emitter<PricingState> emit) {
    if (state.activeTab == PricingTab.current) {
      final fare = state.fare;
      if (fare == null) return;
      emit(state.copyWith(
        fare: fare.copyWith(
          vehicleId: event.vehicleId,
          vehicleLabel: event.label,
        ),
      ));
    } else {
      final fare = state.returnFare;
      if (fare == null) return;
      emit(state.copyWith(
        returnFare: fare.copyWith(
          vehicleId: event.vehicleId,
          vehicleLabel: event.label,
        ),
      ));
    }
  }

  void _onRatePerKmChanged(RatePerKmChanged event, Emitter<PricingState> emit) {
    if (state.activeTab == PricingTab.current) {
      final fare = state.fare;
      if (fare == null) return;
      emit(state.copyWith(fare: fare.copyWith(ratePerKm: event.value)));
    } else {
      final fare = state.returnFare;
      if (fare == null) return;
      emit(state.copyWith(returnFare: fare.copyWith(ratePerKm: event.value)));
    }
  }

  Future<void> _onLocationsSwapped(
    PricingLocationsSwapped event,
    Emitter<PricingState> emit,
  ) async {
    final tempLat = _fromLat;
    final tempLng = _fromLng;
    _fromLat = _toLat;
    _fromLng = _toLng;
    _toLat = tempLat;
    _toLng = tempLng;

    final newFromAddress = state.toAddress;
    final newToAddress = state.fromAddress;

    emit(state.copyWith(
      fromAddress: newFromAddress,
      toAddress: newToAddress,
    ));

    if (_fromLat != null && _fromLng != null && _toLat != null && _toLng != null) {
      try {
        final route = await _estimateRoute(
          originLat: _fromLat!,
          originLng: _fromLng!,
          destLat: _toLat!,
          destLng: _toLng!,
        );
        final distanceKm = route.distanceKm;
        final durationMinutes = route.durationMinutes;

        emit(state.copyWith(
          fare: state.fare?.copyWith(
            distanceKm: distanceKm,
            durationMinutes: durationMinutes,
          ),
          returnFare: state.returnFare?.copyWith(
            distanceKm: distanceKm,
            durationMinutes: durationMinutes,
          ),
        ));
      } catch (_) {}
    }
  }

  Future<void> _onVehiclesRefreshRequested(
    VehiclesRefreshRequested event,
    Emitter<PricingState> emit,
  ) async {
    final vehicles = await _getVehicleOptions(_vehicleType);
    emit(state.copyWith(vehicles: vehicles));
  }

  Future<void> _onPublishRideRequested(
    PublishRideRequested event,
    Emitter<PricingState> emit,
  ) async {
    final fare = state.fare;
    if (fare == null ||
        state.date == null ||
        state.time == null ||
        fare.vehicleId == null ||
        fare.ratePerKm <= 0) {
      return;
    }

    if (state.hasReturnRide) {
      final rf = state.returnFare;
      if (rf == null || rf.vehicleId == null || rf.ratePerKm <= 0) {
        return;
      }
    }

    emit(state.copyWith(status: PricingStatus.publishing));
    try {
      if (state.rideId != null) {
        // Update existing ride
        final farePerSeat = fare.totalCost / state.seatCount;
        final driverEarnings = fare.totalCost;
        await _updateRide(
          rideId: state.rideId!,
          fare: {
            'vehicleId': fare.vehicleId,
            'vehicleLabel': fare.vehicleLabel,
            'ratePerKm': fare.ratePerKm,
            'totalCost': fare.totalCost,
            'farePerSeat': farePerSeat,
            'driverEarnings': driverEarnings,
          },
        );
      } else {
        // 1. Publish main ride
        final farePerSeat = fare.totalCost / state.seatCount;
        final driverEarnings = fare.totalCost;
        await _scheduleRide(
          rideMode: _rideMode,
          vehicleType: _vehicleType,
          fromAddress: state.fromAddress,
          toAddress: state.toAddress,
          fromLat: _fromLat,
          fromLng: _fromLng,
          toLat: _toLat,
          toLng: _toLng,
          date: state.date!,
          time: state.time!,
          seatCount: state.seatCount,
          routeDistanceKm: fare.distanceKm,
          routeDurationMinutes: fare.durationMinutes,
          fare: {
            'vehicleId': fare.vehicleId,
            'vehicleLabel': fare.vehicleLabel,
            'ratePerKm': fare.ratePerKm,
            'totalCost': fare.totalCost,
            'farePerSeat': farePerSeat,
            'driverEarnings': driverEarnings,
          },
        );

        // 2. Publish return ride if requested
        if (state.hasReturnRide) {
          final rf = state.returnFare!;
          final rfPerSeat = rf.totalCost / state.returnSeatCount;
          final rfEarnings = rf.totalCost;
          await _scheduleRide(
            rideMode: _rideMode,
            vehicleType: _vehicleType,
            fromAddress: state.toAddress,
            toAddress: state.fromAddress,
            fromLat: _toLat,
            fromLng: _toLng,
            toLat: _fromLat,
            toLng: _fromLng,
            date: state.date!,
            time: state.returnTime!,
            seatCount: state.returnSeatCount,
            routeDistanceKm: rf.distanceKm,
            routeDurationMinutes: rf.durationMinutes,
            fare: {
              'vehicleId': rf.vehicleId,
              'vehicleLabel': rf.vehicleLabel,
              'ratePerKm': rf.ratePerKm,
              'totalCost': rf.totalCost,
              'farePerSeat': rfPerSeat,
              'driverEarnings': rfEarnings,
            },
          );
        }
      }

      emit(state.copyWith(status: PricingStatus.published));
    } catch (e) {
      emit(state.copyWith(
        status: PricingStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
