import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:acepool/features/home/domain/entities/fare_breakdown.dart';
import 'package:acepool/features/home/domain/entities/vehicle_option.dart';
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

  PricingBloc({
    required EstimateRouteUseCase estimateRoute,
    required ScheduleRideUseCase scheduleRide,
  })  : _estimateRoute = estimateRoute,
        _scheduleRide = scheduleRide,
        super(const PricingState()) {
    on<PricingStarted>(_onPricingStarted);
    on<VehicleSelected>(_onVehicleSelected);
    on<RatePerKmChanged>(_onRatePerKmChanged);
    on<VehiclesRefreshRequested>(_onVehiclesRefreshRequested);
    on<PublishRideRequested>(_onPublishRideRequested);
  }

  Future<List<VehicleOption>> _fetchVehicles(String vehicleType) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const [];

    final db = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'acepool',
    );
    final expectedType = vehicleType == 'bike' ? 'two_wheeler' : 'four_wheeler';
    final snapshot = await db
        .collection('users')
        .doc(uid)
        .collection('vehicles')
        .where('type', isEqualTo: expectedType)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      final brand = data['brand'] as String? ?? '';
      final model = data['model'] as String? ?? '';
      final label = [brand, model].where((s) => s.isNotEmpty).join(' ');
      return VehicleOption(
        id: doc.id,
        label: label.isNotEmpty ? label : 'Vehicle',
        type: data['type'] as String? ?? expectedType,
      );
    }).toList();
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

    final vehicles = await _fetchVehicles(_vehicleType);

    emit(state.copyWith(
      status: PricingStatus.ready,
      fare: FareBreakdown(
        distanceKm: distanceKm,
        durationMinutes: durationMinutes,
        ratePerKm: 0,
      ),
      vehicles: vehicles,
    ));
  }

  void _onVehicleSelected(VehicleSelected event, Emitter<PricingState> emit) {
    final fare = state.fare;
    if (fare == null) return;
    emit(state.copyWith(
      fare: fare.copyWith(vehicleId: event.vehicleId, vehicleLabel: event.label),
    ));
  }

  void _onRatePerKmChanged(RatePerKmChanged event, Emitter<PricingState> emit) {
    final fare = state.fare;
    if (fare == null) return;
    emit(state.copyWith(fare: fare.copyWith(ratePerKm: event.value)));
  }

  Future<void> _onVehiclesRefreshRequested(
    VehiclesRefreshRequested event,
    Emitter<PricingState> emit,
  ) async {
    final vehicles = await _fetchVehicles(_vehicleType);
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

    emit(state.copyWith(status: PricingStatus.publishing));
    try {
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
      emit(state.copyWith(status: PricingStatus.published));
    } catch (e) {
      emit(state.copyWith(status: PricingStatus.failure, errorMessage: e.toString()));
    }
  }
}
