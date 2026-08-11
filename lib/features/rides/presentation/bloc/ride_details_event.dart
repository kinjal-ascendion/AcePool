part of 'ride_details_bloc.dart';

abstract class RideDetailsEvent extends Equatable {
  const RideDetailsEvent();

  @override
  List<Object?> get props => [];
}

class RideDetailsStarted extends RideDetailsEvent {
  const RideDetailsStarted({
    required this.ride,
    this.riderFromAddress,
    this.riderFromLat,
    this.riderFromLng,
    this.riderToAddress,
    this.riderToLat,
    this.riderToLng,
  });

  final RideMatch ride;
  final String? riderFromAddress;
  final double? riderFromLat;
  final double? riderFromLng;
  final String? riderToAddress;
  final double? riderToLat;
  final double? riderToLng;

  @override
  List<Object?> get props => [
        ride,
        riderFromAddress,
        riderFromLat,
        riderFromLng,
        riderToAddress,
        riderToLat,
        riderToLng,
      ];
}

/// Fired on send-button tap. Behaves as "send message to driver" if a
/// request was already made, otherwise as "request ride" (sending the
/// message afterward too, if non-empty) — matching the page's original
/// dual-purpose send button.
class RideDetailsSubmitted extends RideDetailsEvent {
  const RideDetailsSubmitted(this.messageText);

  final String messageText;

  @override
  List<Object?> get props => [messageText];
}
