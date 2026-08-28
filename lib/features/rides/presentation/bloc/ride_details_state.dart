part of 'ride_details_bloc.dart';

enum RideDetailsRidersStatus { initial, loading, loaded, error }

const _unset = Object();

class RideDetailsState extends Equatable {
  const RideDetailsState({
    this.ridersStatus = RideDetailsRidersStatus.initial,
    this.riders = const [],
    this.ridersError,
    this.submitting = false,
    this.justRequested = false,
    this.snackbarMessage,
    this.clearMessageTextTick = 0,
  });

  final RideDetailsRidersStatus ridersStatus;
  final List<RideRider> riders;
  final Object? ridersError;
  final bool submitting;
  final bool justRequested;
  final String? snackbarMessage;

  /// Incremented whenever the message field should be cleared — a tick
  /// rather than a bool so the UI can react even to consecutive identical
  /// clears (e.g. two successful sends in a row).
  final int clearMessageTextTick;

  RideDetailsState copyWith({
    RideDetailsRidersStatus? ridersStatus,
    List<RideRider>? riders,
    Object? ridersError,
    bool? submitting,
    bool? justRequested,
    Object? snackbarMessage = _unset,
    bool clearSnackbar = false,
    bool clearMessageText = false,
  }) {
    return RideDetailsState(
      ridersStatus: ridersStatus ?? this.ridersStatus,
      riders: riders ?? this.riders,
      ridersError: ridersError ?? this.ridersError,
      submitting: submitting ?? this.submitting,
      justRequested: justRequested ?? this.justRequested,
      snackbarMessage: clearSnackbar
          ? null
          : (snackbarMessage == _unset
              ? this.snackbarMessage
              : snackbarMessage as String?),
      clearMessageTextTick:
          clearMessageText ? clearMessageTextTick + 1 : clearMessageTextTick,
    );
  }

  @override
  List<Object?> get props => [
        ridersStatus,
        riders,
        ridersError,
        submitting,
        justRequested,
        snackbarMessage,
        clearMessageTextTick,
      ];
}
