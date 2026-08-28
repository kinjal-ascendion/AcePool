part of 'route_matching_bloc.dart';

abstract class RouteMatchingEvent extends Equatable {
  const RouteMatchingEvent();

  @override
  List<Object?> get props => [];
}

class RouteMatchingStarted extends RouteMatchingEvent {
  const RouteMatchingStarted();
}

class RouteMatchingSaveRequested extends RouteMatchingEvent {
  const RouteMatchingSaveRequested(this.radius);

  final double radius;

  @override
  List<Object?> get props => [radius];
}
