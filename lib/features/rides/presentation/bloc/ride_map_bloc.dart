import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:acepool/features/rides/domain/repositories/rides_repository.dart';

part 'ride_map_event.dart';
part 'ride_map_state.dart';

class RideMapBloc extends Bloc<RideMapEvent, RideMapState> {
  RideMapBloc({required RidesRepository ridesRepository})
      : _ridesRepository = ridesRepository,
        super(const RideMapState()) {
    on<RideMapStarted>(_onStarted);
    on<RideMapNoteChanged>(_onNoteChanged);
  }

  final RidesRepository _ridesRepository;
  StreamSubscription<String?>? _noteSubscription;

  Future<void> _onStarted(RideMapStarted event, Emitter<RideMapState> emit) async {
    emit(state.copyWith(tripNote: event.initialNote));

    try {
      final isDriver = await _ridesRepository.isRideOwnedByCurrentUser(event.rideId);
      emit(state.copyWith(isDriver: isDriver));
    } catch (_) {}

    await _noteSubscription?.cancel();
    _noteSubscription = _ridesRepository.watchRideNote(event.rideId).listen((note) {
      add(RideMapNoteChanged(note));
    });
  }

  void _onNoteChanged(RideMapNoteChanged event, Emitter<RideMapState> emit) {
    emit(state.copyWith(tripNote: event.note));
  }

  @override
  Future<void> close() {
    _noteSubscription?.cancel();
    return super.close();
  }
}
