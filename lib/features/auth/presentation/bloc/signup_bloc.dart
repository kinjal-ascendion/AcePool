import 'dart:io';

import 'package:acepool/core/usecases/scan_license_usecase.dart';
import 'package:acepool/features/onboarding/domain/onboarding_selection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/auth_exception.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/entities/signup_details.dart';
import '../../domain/usecases/sign_up_usecase.dart';

part 'signup_event.dart';
part 'signup_state.dart';

class SignupBloc extends Bloc<SignupEvent, SignupState> {
  SignupBloc({required SignUpUseCase signUp, required ScanLicenseUseCase scanLicense})
    : _signUp = signUp,
      _scanLicense = scanLicense,
      super(const SignupState()) {
    on<SignupSubmitted>(_onSignupSubmitted);
    on<SignupFieldChanged>(_onSignupFieldChanged);
    on<SignupLicenseImagePicked>(_onSignupLicenseImagePicked);
  }

  final SignUpUseCase _signUp;
  final ScanLicenseUseCase _scanLicense;

  Future<void> _onSignupSubmitted(
    SignupSubmitted event,
    Emitter<SignupState> emit,
  ) async {
    final fullName = event.fullName.trim();
    final employeeId = event.employeeId.trim();
    final phone = event.phone.trim();
    final emailUsername = event.emailUsername.trim();
    final password = event.password;
    final confirmPassword = event.confirmPassword;

    final fullNameError = fullName.isEmpty ? 'Full name is required' : null;
    final employeeIdError = employeeId.isEmpty
        ? 'Employee ID is required'
        : null;
    final phoneError = phone.isEmpty
        ? 'Phone number is required'
        : phone.length != 10
        ? 'Enter a valid 10-digit phone number'
        : null;
    final emailError = emailUsername.isEmpty
        ? 'Work email username is required'
        : null;
    final passwordError = password.isEmpty
        ? 'Password is required'
        : password.length < 6
        ? 'Password must be at least 6 characters'
        : null;
    final confirmPasswordError = confirmPassword.isEmpty
        ? 'Please confirm your password'
        : confirmPassword != password
        ? 'Passwords do not match'
        : null;

    if (fullNameError != null ||
        employeeIdError != null ||
        phoneError != null ||
        emailError != null ||
        passwordError != null ||
        confirmPasswordError != null) {
      emit(
        SignupState(
          fullNameError: fullNameError,
          employeeIdError: employeeIdError,
          phoneError: phoneError,
          emailError: emailError,
          passwordError: passwordError,
          confirmPasswordError: confirmPasswordError,
          frontLicenseImage: state.frontLicenseImage,
          backLicenseImage: state.backLicenseImage,
          isVerifyingFrontLicense: state.isVerifyingFrontLicense,
          isVerifyingBackLicense: state.isVerifyingBackLicense,
          frontLicenseValid: state.frontLicenseValid,
          backLicenseValid: state.backLicenseValid,
          licenseNumber: state.licenseNumber,
        ),
      );
      return;
    }

    emit(
      SignupState(
        status: SignupStatus.submitting,
        frontLicenseImage: state.frontLicenseImage,
        backLicenseImage: state.backLicenseImage,
        isVerifyingFrontLicense: state.isVerifyingFrontLicense,
        isVerifyingBackLicense: state.isVerifyingBackLicense,
        frontLicenseValid: state.frontLicenseValid,
        backLicenseValid: state.backLicenseValid,
        licenseNumber: state.licenseNumber,
      ),
    );

    bool? licenseVerified;
    if (event.showLicenseSection &&
        (state.frontLicenseImage != null || state.backLicenseImage != null)) {
      licenseVerified =
          (state.frontLicenseValid ?? false) || (state.backLicenseValid ?? false);
    }

    try {
      final user = await _signUp(
        SignupDetails(
          fullName: fullName,
          employeeId: employeeId,
          phone: phone,
          emailUsername: emailUsername,
          password: password,
          onboardingSelection: event.onboardingSelection,
          licenseVerified: licenseVerified,
          licenseNumber: state.licenseNumber,
        ),
      );
      emit(
        SignupState(
          status: SignupStatus.success,
          user: user,
          frontLicenseImage: state.frontLicenseImage,
          backLicenseImage: state.backLicenseImage,
          frontLicenseValid: state.frontLicenseValid,
          backLicenseValid: state.backLicenseValid,
          licenseNumber: state.licenseNumber,
        ),
      );
    } on AuthException catch (e) {
      emit(
        SignupState(
          status: SignupStatus.failure,
          errorMessage: e.message,
          frontLicenseImage: state.frontLicenseImage,
          backLicenseImage: state.backLicenseImage,
          frontLicenseValid: state.frontLicenseValid,
          backLicenseValid: state.backLicenseValid,
          licenseNumber: state.licenseNumber,
        ),
      );
    } catch (_) {
      emit(
        SignupState(
          status: SignupStatus.failure,
          errorMessage: 'Sign up failed. Please try again.',
          frontLicenseImage: state.frontLicenseImage,
          backLicenseImage: state.backLicenseImage,
          frontLicenseValid: state.frontLicenseValid,
          backLicenseValid: state.backLicenseValid,
          licenseNumber: state.licenseNumber,
        ),
      );
    }
  }

  void _onSignupFieldChanged(SignupFieldChanged event, Emitter<SignupState> emit) {
    emit(
      SignupState(
        frontLicenseImage: state.frontLicenseImage,
        backLicenseImage: state.backLicenseImage,
        isVerifyingFrontLicense: state.isVerifyingFrontLicense,
        isVerifyingBackLicense: state.isVerifyingBackLicense,
        frontLicenseValid: state.frontLicenseValid,
        backLicenseValid: state.backLicenseValid,
        licenseNumber: state.licenseNumber,
      ),
    );
  }

  Future<void> _onSignupLicenseImagePicked(
    SignupLicenseImagePicked event,
    Emitter<SignupState> emit,
  ) async {
    if (event.isFront) {
      emit(
        SignupState(
          frontLicenseImage: event.imageFile,
          backLicenseImage: state.backLicenseImage,
          isVerifyingFrontLicense: true,
          isVerifyingBackLicense: state.isVerifyingBackLicense,
          backLicenseValid: state.backLicenseValid,
          licenseNumber: state.licenseNumber,
        ),
      );
    } else {
      emit(
        SignupState(
          frontLicenseImage: state.frontLicenseImage,
          backLicenseImage: event.imageFile,
          isVerifyingFrontLicense: state.isVerifyingFrontLicense,
          isVerifyingBackLicense: true,
          frontLicenseValid: state.frontLicenseValid,
          licenseNumber: state.licenseNumber,
        ),
      );
    }

    final result = await _scanLicense(event.imageFile.path);
    // true = number found, false = OCR genuinely failed, null = no match
    // found on this side (normal - keep it neutral, not an error).
    final status = result.ocrFailed
        ? false
        : (result.licenseNumber != null ? true : null);
    final licenseNumber = result.licenseNumber ?? state.licenseNumber;

    if (event.isFront) {
      emit(
        SignupState(
          frontLicenseImage: state.frontLicenseImage,
          backLicenseImage: state.backLicenseImage,
          isVerifyingFrontLicense: false,
          isVerifyingBackLicense: state.isVerifyingBackLicense,
          frontLicenseValid: status,
          backLicenseValid: state.backLicenseValid,
          licenseNumber: licenseNumber,
        ),
      );
    } else {
      emit(
        SignupState(
          frontLicenseImage: state.frontLicenseImage,
          backLicenseImage: state.backLicenseImage,
          isVerifyingFrontLicense: state.isVerifyingFrontLicense,
          isVerifyingBackLicense: false,
          frontLicenseValid: state.frontLicenseValid,
          backLicenseValid: status,
          licenseNumber: licenseNumber,
        ),
      );
    }
  }
}
