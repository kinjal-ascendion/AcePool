part of 'drives_detail_bloc.dart';

enum DrivesDetailRidersStatus { initial, loading, loaded, error }

const _unset = Object();

class DrivesDetailState extends Equatable {
  const DrivesDetailState({
    this.currentTrip,
    this.ridersStatus = DrivesDetailRidersStatus.initial,
    this.riders = const [],
    this.ridersError,
    this.statusUpdateTick = 0,
    this.lastUpdatedStatus,
    this.snackbarMessage,
  });

  final UpcomingTrip? currentTrip;
  final DrivesDetailRidersStatus ridersStatus;
  final List<RideRider> riders;
  final Object? ridersError;

  /// Incremented on every successful status change so the page can react
  /// (refresh HomeBloc's upcoming trips, pop when completed/cancelled).
  final int statusUpdateTick;
  final String? lastUpdatedStatus;

  final String? snackbarMessage;

  DrivesDetailState copyWith({
    UpcomingTrip? currentTrip,
    DrivesDetailRidersStatus? ridersStatus,
    List<RideRider>? riders,
    Object? ridersError,
    int? statusUpdateTick,
    String? lastUpdatedStatus,
    Object? snackbarMessage = _unset,
    bool clearSnackbar = false,
  }) {
    return DrivesDetailState(
      currentTrip: currentTrip ?? this.currentTrip,
      ridersStatus: ridersStatus ?? this.ridersStatus,
      riders: riders ?? this.riders,
      ridersError: ridersError ?? this.ridersError,
      statusUpdateTick: statusUpdateTick ?? this.statusUpdateTick,
      lastUpdatedStatus: lastUpdatedStatus ?? this.lastUpdatedStatus,
      snackbarMessage: clearSnackbar
          ? null
          : (snackbarMessage == _unset ? this.snackbarMessage : snackbarMessage as String?),
    );
  }

  @override
  List<Object?> get props => [
        currentTrip,
        ridersStatus,
        riders,
        ridersError,
        statusUpdateTick,
        lastUpdatedStatus,
        snackbarMessage,
      ];
}
