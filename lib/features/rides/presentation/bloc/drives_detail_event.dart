part of 'drives_detail_bloc.dart';

abstract class DrivesDetailEvent extends Equatable {
  const DrivesDetailEvent();

  @override
  List<Object?> get props => [];
}

class DrivesDetailStarted extends DrivesDetailEvent {
  const DrivesDetailStarted(this.trip);

  final UpcomingTrip trip;

  @override
  List<Object?> get props => [trip];
}

class DrivesDetailReloadRequested extends DrivesDetailEvent {
  const DrivesDetailReloadRequested();
}

class DrivesDetailStatusChangeRequested extends DrivesDetailEvent {
  const DrivesDetailStatusChangeRequested(this.status);

  final String status;

  @override
  List<Object?> get props => [status];
}

class DrivesDetailNegotiationResponded extends DrivesDetailEvent {
  const DrivesDetailNegotiationResponded({
    required this.requestId,
    required this.status,
  });

  final String requestId;
  final String status;

  @override
  List<Object?> get props => [requestId, status];
}
