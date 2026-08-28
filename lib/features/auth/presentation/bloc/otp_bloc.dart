import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/auth_exception.dart';
import '../../domain/usecases/cancel_signup_usecase.dart';
import '../../domain/usecases/send_otp_usecase.dart';
import '../../domain/usecases/verify_otp_usecase.dart';

part 'otp_event.dart';
part 'otp_state.dart';

class OtpBloc extends Bloc<OtpEvent, OtpState> {
  OtpBloc({
    required SendOtpUseCase sendOtp,
    required VerifyOtpUseCase verifyOtp,
    required CancelSignupUseCase cancelSignup,
  }) : _sendOtp = sendOtp,
       _verifyOtp = verifyOtp,
       _cancelSignup = cancelSignup,
       super(const OtpState()) {
    on<OtpStarted>(_onOtpStarted);
    on<OtpSubmitted>(_onOtpSubmitted);
    on<OtpResendRequested>(_onOtpResendRequested);
    on<OtpCancelled>(_onOtpCancelled);
    on<OtpErrorCleared>(_onOtpErrorCleared);
  }

  final SendOtpUseCase _sendOtp;
  final VerifyOtpUseCase _verifyOtp;
  final CancelSignupUseCase _cancelSignup;

  late String _email;
  late String _uid;

  Future<void> _onOtpStarted(OtpStarted event, Emitter<OtpState> emit) async {
    _email = event.email;
    _uid = event.uid;
    emit(const OtpState(status: OtpStatus.sending));
    await _sendOtp(email: _email, uid: _uid);
    emit(const OtpState(status: OtpStatus.awaitingCode));
  }

  Future<void> _onOtpSubmitted(
    OtpSubmitted event,
    Emitter<OtpState> emit,
  ) async {
    if (event.code.length != 6) {
      emit(
        const OtpState(
          status: OtpStatus.awaitingCode,
          errorMessage: 'Please enter the complete 6-digit OTP',
        ),
      );
      return;
    }

    emit(const OtpState(status: OtpStatus.verifying));
    try {
      await _verifyOtp(uid: _uid, enteredOtp: event.code);
      emit(const OtpState(status: OtpStatus.verified));
    } on AuthException catch (e) {
      emit(OtpState(status: OtpStatus.awaitingCode, errorMessage: e.message));
    } catch (_) {
      emit(
        const OtpState(
          status: OtpStatus.awaitingCode,
          errorMessage: 'Verification failed. Please try again.',
        ),
      );
    }
  }

  Future<void> _onOtpResendRequested(
    OtpResendRequested event,
    Emitter<OtpState> emit,
  ) async {
    if (state.status == OtpStatus.resending) return;
    emit(const OtpState(status: OtpStatus.resending));
    await _sendOtp(email: _email, uid: _uid);
    emit(const OtpState(status: OtpStatus.resent));
  }

  Future<void> _onOtpCancelled(
    OtpCancelled event,
    Emitter<OtpState> emit,
  ) async {
    await _cancelSignup(uid: _uid);
    emit(const OtpState(status: OtpStatus.cancelled));
  }

  void _onOtpErrorCleared(OtpErrorCleared event, Emitter<OtpState> emit) {
    if (state.errorMessage == null) return;
    emit(OtpState(status: state.status));
  }
}
