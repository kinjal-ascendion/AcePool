part of 'profile_payment_bloc.dart';

abstract class ProfilePaymentEvent extends Equatable {
  const ProfilePaymentEvent();

  @override
  List<Object?> get props => [];
}

class ProfilePaymentMethodChanged extends ProfilePaymentEvent {
  const ProfilePaymentMethodChanged(this.method);

  final String method;

  @override
  List<Object?> get props => [method];
}

class ProfilePaymentEditToggled extends ProfilePaymentEvent {
  const ProfilePaymentEditToggled();
}

class ProfilePaymentSaveRequested extends ProfilePaymentEvent {
  const ProfilePaymentSaveRequested(this.upiId, this.upiPhone);

  final String upiId;
  final String upiPhone;

  @override
  List<Object?> get props => [upiId, upiPhone];
}

class ProfilePaymentDetailsLoaded extends ProfilePaymentEvent {
  const ProfilePaymentDetailsLoaded({
    required this.method,
    required this.upiId,
    required this.upiPhone,
  });

  final String method;
  final String upiId;
  final String upiPhone;

  @override
  List<Object?> get props => [method, upiId, upiPhone];
}
