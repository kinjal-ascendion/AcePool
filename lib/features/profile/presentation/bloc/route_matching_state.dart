part of 'route_matching_bloc.dart';

enum RouteMatchingStatus { initial, loaded }

const _unset = Object();

class RouteMatchingState extends Equatable {
  const RouteMatchingState({
    this.status = RouteMatchingStatus.initial,
    this.radius = 0.0,
    this.isSaving = false,
    this.savedTick = 0,
    this.saveError,
  });

  final RouteMatchingStatus status;
  final double radius;
  final bool isSaving;
  final int savedTick;
  final String? saveError;

  RouteMatchingState copyWith({
    RouteMatchingStatus? status,
    double? radius,
    bool? isSaving,
    int? savedTick,
    Object? saveError = _unset,
  }) {
    return RouteMatchingState(
      status: status ?? this.status,
      radius: radius ?? this.radius,
      isSaving: isSaving ?? this.isSaving,
      savedTick: savedTick ?? this.savedTick,
      saveError: saveError == _unset ? this.saveError : saveError as String?,
    );
  }

  @override
  List<Object?> get props => [status, radius, isSaving, savedTick, saveError];
}
