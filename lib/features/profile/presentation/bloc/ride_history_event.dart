part of 'ride_history_bloc.dart';

abstract class RideHistoryEvent extends Equatable {
  const RideHistoryEvent();

  @override
  List<Object?> get props => [];
}

class RideHistoryStarted extends RideHistoryEvent {
  const RideHistoryStarted();
}
