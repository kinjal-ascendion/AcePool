part of 'ride_map_bloc.dart';

abstract class RideMapEvent extends Equatable {
  const RideMapEvent();

  @override
  List<Object?> get props => [];
}

class RideMapStarted extends RideMapEvent {
  const RideMapStarted({required this.rideId, this.initialNote});

  final String rideId;
  final String? initialNote;

  @override
  List<Object?> get props => [rideId, initialNote];
}

class RideMapNoteChanged extends RideMapEvent {
  const RideMapNoteChanged(this.note);

  final String? note;

  @override
  List<Object?> get props => [note];
}
