part of 'ride_payment_bloc.dart';

abstract class RidePaymentEvent extends Equatable {
  const RidePaymentEvent();

  @override
  List<Object?> get props => [];
}

class RidePaymentMethodSelected extends RidePaymentEvent {
  const RidePaymentMethodSelected(this.method);

  final String method;

  @override
  List<Object?> get props => [method];
}

class RidePaymentCompleteRequested extends RidePaymentEvent {
  const RidePaymentCompleteRequested(this.rideId);

  final String rideId;

  @override
  List<Object?> get props => [rideId];
}
