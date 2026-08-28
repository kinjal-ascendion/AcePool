part of 'ride_map_bloc.dart';

const _unset = Object();

class RideMapState extends Equatable {
  const RideMapState({
    this.isDriver = false,
    this.tripNote,
  });

  final bool isDriver;
  final String? tripNote;

  RideMapState copyWith({
    bool? isDriver,
    Object? tripNote = _unset,
  }) {
    return RideMapState(
      isDriver: isDriver ?? this.isDriver,
      tripNote: tripNote == _unset ? this.tripNote : tripNote as String?,
    );
  }

  @override
  List<Object?> get props => [isDriver, tripNote];
}
