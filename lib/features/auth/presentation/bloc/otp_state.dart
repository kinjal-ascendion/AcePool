part of 'otp_bloc.dart';

enum OtpStatus {
  initial,
  sending,
  awaitingCode,
  verifying,
  resending,
  resent,
  verified,
  cancelled,
}

class OtpState extends Equatable {
  const OtpState({this.status = OtpStatus.initial, this.errorMessage});

  final OtpStatus status;
  final String? errorMessage;

  @override
  List<Object?> get props => [status, errorMessage];
}
