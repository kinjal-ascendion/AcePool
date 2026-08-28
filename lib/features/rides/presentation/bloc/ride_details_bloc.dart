import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:acepool/features/rides/domain/entities/ride_match.dart';
import 'package:acepool/features/rides/domain/entities/ride_rider.dart';
import 'package:acepool/features/rides/domain/repositories/rides_repository.dart';

part 'ride_details_event.dart';
part 'ride_details_state.dart';

class RideDetailsBloc extends Bloc<RideDetailsEvent, RideDetailsState> {
  RideDetailsBloc({required RidesRepository ridesRepository})
      : _ridesRepository = ridesRepository,
        super(const RideDetailsState()) {
    on<RideDetailsStarted>(_onStarted);
    on<RideDetailsSubmitted>(_onSubmitted);
  }

  final RidesRepository _ridesRepository;

  late RideMatch _ride;
  String? _riderFromAddress;
  double? _riderFromLat;
  double? _riderFromLng;
  String? _riderToAddress;
  double? _riderToLat;
  double? _riderToLng;

  Future<void> _onStarted(
    RideDetailsStarted event,
    Emitter<RideDetailsState> emit,
  ) async {
    _ride = event.ride;
    _riderFromAddress = event.riderFromAddress;
    _riderFromLat = event.riderFromLat;
    _riderFromLng = event.riderFromLng;
    _riderToAddress = event.riderToAddress;
    _riderToLat = event.riderToLat;
    _riderToLng = event.riderToLng;

    emit(state.copyWith(
      ridersStatus: RideDetailsRidersStatus.loading,
      justRequested: event.ride.alreadyRequested,
    ));

    try {
      final riders = await _ridesRepository.getOtherRiders(_ride.id);
      emit(state.copyWith(
        ridersStatus: RideDetailsRidersStatus.loaded,
        riders: riders,
      ));
    } catch (e) {
      emit(state.copyWith(ridersStatus: RideDetailsRidersStatus.error, ridersError: e));
    }
  }

  Future<void> _onSubmitted(
    RideDetailsSubmitted event,
    Emitter<RideDetailsState> emit,
  ) async {
    final messageText = event.messageText.trim();
    if (state.submitting) return;

    if (state.justRequested) {
      if (messageText.isEmpty) return;
      emit(state.copyWith(submitting: true, clearSnackbar: true));
      try {
        await _ridesRepository.sendRideChatMessage(
          driverId: _ride.driverId,
          driverName: _ride.driverName,
          text: messageText,
        );
        emit(state.copyWith(
          submitting: false,
          snackbarMessage: 'Message sent to driver',
          clearMessageText: true,
        ));
      } catch (e) {
        emit(state.copyWith(
          submitting: false,
          snackbarMessage: 'Failed to send message: $e',
        ));
      }
      return;
    }

    emit(state.copyWith(submitting: true, clearSnackbar: true));
    try {
      await _ridesRepository.requestRideFromDetails(
        ride: _ride,
        riderFromAddress: _riderFromAddress,
        riderFromLat: _riderFromLat,
        riderFromLng: _riderFromLng,
        riderToAddress: _riderToAddress,
        riderToLat: _riderToLat,
        riderToLng: _riderToLng,
        message: messageText,
      );

      if (messageText.isNotEmpty) {
        await _ridesRepository.sendRideChatMessage(
          driverId: _ride.driverId,
          driverName: _ride.driverName,
          text: messageText,
        );
      }

      final riders = await _ridesRepository.getOtherRiders(_ride.id);

      emit(state.copyWith(
        submitting: false,
        justRequested: true,
        clearMessageText: true,
        riders: riders,
      ));
    } catch (e) {
      emit(state.copyWith(
        submitting: false,
        snackbarMessage: 'Could not request ride: $e',
      ));
    }
  }
}
