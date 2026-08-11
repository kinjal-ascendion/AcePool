part of 'otp_bloc.dart';

abstract class OtpEvent extends Equatable {
  const OtpEvent();

  @override
  List<Object?> get props => [];
}

class OtpStarted extends OtpEvent {
  const OtpStarted({required this.email, required this.uid});

  final String email;
  final String uid;

  @override
  List<Object?> get props => [email, uid];
}

class OtpSubmitted extends OtpEvent {
  const OtpSubmitted(this.code);

  final String code;

  @override
  List<Object?> get props => [code];
}

class OtpResendRequested extends OtpEvent {
  const OtpResendRequested();
}

class OtpCancelled extends OtpEvent {
  const OtpCancelled();
}

class OtpErrorCleared extends OtpEvent {
  const OtpErrorCleared();
}
