import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:acepool/core/constants/fare_constants.dart';
import 'package:acepool/features/home/domain/entities/fare_breakdown.dart';
import 'package:acepool/features/home/domain/usecases/estimate_route_usecase.dart';
import 'package:acepool/features/home/domain/usecases/schedule_ride_usecase.dart';

part 'pricing_event.dart';
part 'pricing_state.dart';

class PricingBloc extends Bloc<PricingEvent, PricingState> {
  final EstimateRouteUseCase _estimateRoute;
  final ScheduleRideUseCase _scheduleRide;

  double? _fromLat;
  double? _fromLng;
  double? _toLat;
  double? _toLng;
  String _vehicleType = 'car';
  String _rideMode = 'offer';

  int get _maxSeats => _vehicleType == 'bike' ? 1 : 4;

  PricingBloc({
    required EstimateRouteUseCase estimateRoute,
    required ScheduleRideUseCase scheduleRide,
  })  : _estimateRoute = estimateRoute,
        _scheduleRide = scheduleRide,
        super(const PricingState()) {
    on<PricingStarted>(_onPricingStarted);
    on<TollsIncludedToggled>(_onTollsIncludedToggled);
    on<DistanceCostChanged>(_onDistanceCostChanged);
    on<TollCostChanged>(_onTollCostChanged);
    on<DetourCostChanged>(_onDetourCostChanged);
    on<RiderCountChanged>(_onRiderCountChanged);
    on<PublishRideRequested>(_onPublishRideRequested);
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
      vehicleType: _vehicleType,
    ));

    var distanceKm = 0.0;
    var durationMinutes = 0;
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

    final distanceCost = (distanceKm * FareConstants.ratePerKm).roundToDouble();
    final detourCost = (distanceCost * FareConstants.detourRateMultiplier).roundToDouble();

    emit(state.copyWith(
      status: PricingStatus.ready,
      fare: FareBreakdown(
        distanceKm: distanceKm,
        durationMinutes: durationMinutes,
        distanceCost: distanceCost,
        tollCost: 0,
        includeTolls: false,
        detourCost: detourCost,
        riderCount: FareBreakdown.clampRiderCount(event.seatCount, maxCount: _maxSeats),
      ),
    ));
  }

  void _onTollsIncludedToggled(
    TollsIncludedToggled event,
    Emitter<PricingState> emit,
  ) {
    final fare = state.fare;
    if (fare == null) return;
    emit(state.copyWith(fare: fare.copyWith(includeTolls: event.includeTolls)));
  }

  void _onDistanceCostChanged(DistanceCostChanged event, Emitter<PricingState> emit) {
    final fare = state.fare;
    if (fare == null) return;
    emit(state.copyWith(fare: fare.copyWith(distanceCost: event.value)));
  }

  void _onTollCostChanged(TollCostChanged event, Emitter<PricingState> emit) {
    final fare = state.fare;
    if (fare == null) return;
    emit(state.copyWith(fare: fare.copyWith(tollCost: event.value)));
  }

  void _onDetourCostChanged(DetourCostChanged event, Emitter<PricingState> emit) {
    final fare = state.fare;
    if (fare == null) return;
    emit(state.copyWith(fare: fare.copyWith(detourCost: event.value)));
  }

  void _onRiderCountChanged(RiderCountChanged event, Emitter<PricingState> emit) {
    final fare = state.fare;
    if (fare == null) return;
    emit(state.copyWith(
      fare: fare.copyWith(
        riderCount: FareBreakdown.clampRiderCount(event.riderCount, maxCount: _maxSeats),
      ),
    ));
  }

  Future<void> _onPublishRideRequested(
    PublishRideRequested event,
    Emitter<PricingState> emit,
  ) async {
    final fare = state.fare;
    if (fare == null || state.date == null || state.time == null) return;

    emit(state.copyWith(status: PricingStatus.publishing));
    try {
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
        seatCount: fare.riderCount,
        routeDistanceKm: fare.distanceKm,
        routeDurationMinutes: fare.durationMinutes,
        fare: {
          'distanceCost': fare.distanceCost,
          'tollCost': fare.tollCost,
          'includeTolls': fare.includeTolls,
          'detourCost': fare.detourCost,
          'totalSharedCost': fare.totalSharedCost,
          'farePerSeat': fare.farePerSeat,
          'driverEarnings': fare.driverEarnings,
        },
      );
      emit(state.copyWith(status: PricingStatus.published));
    } catch (e) {
      emit(state.copyWith(status: PricingStatus.failure, errorMessage: e.toString()));
    }
  }
}
