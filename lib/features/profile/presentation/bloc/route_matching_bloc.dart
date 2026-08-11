import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:acepool/features/profile/domain/repositories/profile_repository.dart';

part 'route_matching_event.dart';
part 'route_matching_state.dart';

class RouteMatchingBloc extends Bloc<RouteMatchingEvent, RouteMatchingState> {
  RouteMatchingBloc({required ProfileRepository profileRepository})
      : _profileRepository = profileRepository,
        super(const RouteMatchingState()) {
    on<RouteMatchingStarted>(_onStarted);
    on<RouteMatchingSaveRequested>(_onSaveRequested);
  }

  final ProfileRepository _profileRepository;

  Future<void> _onStarted(
    RouteMatchingStarted event,
    Emitter<RouteMatchingState> emit,
  ) async {
    final radius = await _profileRepository.getRouteMatchingRadius();
    emit(state.copyWith(status: RouteMatchingStatus.loaded, radius: radius));
  }

  Future<void> _onSaveRequested(
    RouteMatchingSaveRequested event,
    Emitter<RouteMatchingState> emit,
  ) async {
    emit(state.copyWith(isSaving: true));
    try {
      await _profileRepository.saveRouteMatchingRadius(event.radius);
      emit(state.copyWith(
        isSaving: false,
        savedTick: state.savedTick + 1,
        radius: event.radius,
      ));
    } catch (e) {
      emit(state.copyWith(isSaving: false, saveError: e.toString()));
    }
  }
}
